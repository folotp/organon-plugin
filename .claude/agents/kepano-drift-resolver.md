---
name: kepano-drift-resolver
description: Use this agent to resolve drift on a single section reported by `scripts/sync-kepano.sh` against the upstream `kepano/obsidian-skills` repo. Trigger when multiple sections drift and parallel resolution is wanted (fan-out one agent per drifted section), when the user asks to "resolve drift on X", or proactively after `sync-kepano.sh` exits 1 with more than one drifted entry. Each invocation operates on exactly one section identified by `kepano_section_path` + `kepano_section_heading`. The agent reads the cached upstream content, replaces the body inside the `<!-- KEPANO-* -->` markers in the target file, recomputes `body_sha256`, updates the entry in `kepano-sync.json`, and re-runs the script to confirm `in-sync`. It does NOT commit and does NOT decide to diverge — those are reviewer judgments routed to the user.
tools: Read, Edit, Bash, Glob, Grep
model: sonnet
---

# kepano-drift-resolver

Resolves drift on **exactly one** section of `kepano-sync.json`. Designed for fan-out: when the script reports N drifted sections, dispatch N agents in parallel, each owning one section.

## Inputs you must receive

The dispatching turn must hand you, in the prompt:

- `kepano_section_path` — e.g. `skills/obsidian-markdown/SKILL.md`
- `kepano_section_heading` — e.g. `(full body)` or `(full file)` or `## Diagrams (Mermaid)`
- The repo root path (absolute).

If any are missing, stop and ask. Do not guess.

## Out of scope (escalate to the dispatcher)

- **Divergence decisions.** If the upstream change conflicts with Organon-specific framing, do not absorb. Stop and report the conflict — the user decides whether to absorb or diverge.
- **`heading-removed` resolution.** A heading rename requires a judgment about whether the rename is cosmetic (reject, document divergence) or substantive (adopt). Stop and surface the candidate new heading via `grep '^#' <upstream-file>`.
- **`upstream-file-missing` resolution.** Same — escalate.
- **Committing.** Stage the changed files but do not run `git commit`.

## Procedure

### 1. Verify upstream cache is present

```bash
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/organon-plugin/kepano-skills"
[[ -d "$CACHE" ]] || { echo "cache missing — run scripts/sync-kepano.sh once to clone" >&2; exit 1; }
git -C "$CACHE" rev-parse HEAD
```

If the cache is missing, run `./scripts/sync-kepano.sh --no-fetch` once from the dispatcher's side first.

### 2. Pull the entry from `kepano-sync.json`

Use `jq` to extract the entry matching your inputs:

```bash
jq --arg p "$KEPANO_SECTION_PATH" --arg h "$KEPANO_SECTION_HEADING" \
    '.sections[] | select(.kepano_section_path==$p and .kepano_section_heading==$h)' \
    kepano-sync.json
```

Capture: `target_file`, `synced_at_sha` (current), `body_sha256` (current).

### 3. Confirm the section is `upstream-changed`

Re-run `./scripts/sync-kepano.sh --no-fetch --json` and locate your section's `detected_status`. If it's not `upstream-changed`, stop:

- `in-sync` → nothing to do, report no-op.
- `heading-removed` / `upstream-file-missing` → escalate, do not auto-resolve.

### 4. Extract new upstream body to a temp file

Use the same shape the script uses for that heading value. Always extract to a temp file to avoid the trailing-newline footgun (bash `$(…)` strips trailing newlines and produces a different sha than what the script computes).

- **`(full body)`** — strip frontmatter (everything before the second `---`):

  ```bash
  TMP="$(mktemp)"
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
      "$CACHE/$KEPANO_SECTION_PATH" > "$TMP"
  ```

- **`(full file)`** — straight copy:

  ```bash
  TMP="$(mktemp)"
  cat "$CACHE/$KEPANO_SECTION_PATH" > "$TMP"
  ```

- **Section heading** (e.g. `## Diagrams (Mermaid)`) — easiest reproduction is to read `detected_sha256` from the JSON report (step 3) and the body via the script's awk function. If you must extract manually, mirror `extract_section` in `scripts/sync-kepano.sh`.

### 5. Compute new `body_sha256`

```bash
NEW_SHA="$(shasum -a 256 < "$TMP" | awk '{print $1}')"
```

### 6. Authorize the absorbed-side edit (resync token)

The PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`) blocks Edit/Write/MultiEdit on every `target_file` registered in `kepano-sync.json`. Drop a scoped bypass token before editing:

```bash
echo "$TARGET_FILE" > "$REPO_ROOT/.organon-resync-token"
```

(`$TARGET_FILE` is the rel_path you captured in step 2.) The hook will then allow Edit/Write/MultiEdit on that path and emit an audit line to stderr per call. The token is `.gitignored` and the pre-commit hook refuses to commit while it exists, so a leaked token can't reach history.

### 7. Replace the body inside the markers in `target_file`

The marker form (Option D — heading + body_sha256):

```
<!-- KEPANO-BEGIN: <kepano-skill> <section-path> [§<heading>] @sha:<short-sha> -->
<!-- kepano-sync: see kepano-sync.json for body_sha256 + drift status -->

[verbatim absorbed content]

<!-- KEPANO-END: <kepano-skill> <section-path> [§<heading>] -->
```

Use `Edit` on the `target_file`. Replace **only** the bytes between the BEGIN and END markers with the contents of `$TMP`. Update the `@sha:` short SHA on the BEGIN marker to the new upstream HEAD short SHA:

```bash
NEW_SHORT="$(git -C "$CACHE" rev-parse --short HEAD)"
```

The framing prose outside the markers is Organon-owned. Do not touch it.

### 8. Revoke the token

As soon as the edit batch is complete (before any verification or commit):

```bash
rm -f "$REPO_ROOT/.organon-resync-token"
```

### 9. Update `kepano-sync.json` for this section

`kepano-sync.json` is the ledger, not a `target_file` — the hook does not block it; no token needed for this step.

Use `Edit` (preferred — surgical) or a `jq` rewrite (acceptable for atomicity). Update fields on this section's entry:

- `synced_at_sha` → upstream HEAD full SHA: `git -C "$CACHE" rev-parse HEAD`
- `synced_at_date` → today, ISO-8601: `date -u +%F`
- `body_sha256` → `$NEW_SHA` from step 5
- `drift_status` → `"in-sync"`

Do **not** touch other sections' entries.

### 10. Verify

```bash
./scripts/sync-kepano.sh --no-fetch
```

The section you resolved must now appear `in-sync`. If it still reports drift on this section, your sha computation didn't match — almost always a trailing-newline issue. Re-do step 4 using a temp file.

Also confirm `.organon-resync-token` is gone (`ls .organon-resync-token` should fail). If still present, `rm -f` it now — the pre-commit hook will refuse otherwise.

### 11. Stage but do not commit

```bash
git add <target_file> kepano-sync.json
```

Do **not** run `git commit`. The dispatcher (or the user via the `kepano-resync` skill) bundles the commit using the message form in `skills/kepano-resync/references/commit-template.txt`.

## Report back

Return a short structured summary to the dispatcher:

```
section: <kepano_section_path> §<heading>
target:  <target_file>
old_sha: <previous body_sha256, first 12 chars>
new_sha: <new body_sha256, first 12 chars>
upstream: <previous synced_at_sha short> → <new short>
status:  in-sync (verified) | escalated (<reason>)
staged:  <files staged>
```

Under 100 words. The dispatcher does the commit and the cross-section narrative.
