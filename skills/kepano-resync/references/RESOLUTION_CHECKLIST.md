# Resolution checklist — per drifted section

Operational checklist for resolving a single drifted section reported by `./scripts/sync-kepano.sh`. Work this list once per section; for multiple drifted sections, fan out via the `kepano-drift-resolver` subagent if available.

## Statuses

Bilateral check (since v0.6.x): the script verifies BOTH the upstream → stored sha chain AND the plugin target → stored sha chain. Upstream-side issues take priority; target-side statuses surface only when upstream is in-sync.

| status | meaning | routing |
|---|---|---|
| `in-sync` | upstream AND plugin target both match stored sha | nothing to do |
| `upstream-changed` | upstream body differs from stored | §Re-sync (§Divergence if conflict) |
| `heading-removed` | heading renamed/removed | §Heading rename |
| `upstream-file-missing` | source file gone | escalate — manual investigation |
| `target-corrupt` | plugin target body between markers differs from stored (upstream still matches) | §Target-corrupt below |
| `target-marker-missing` | plugin target's BEGIN/END markers not found | escalate — markers were removed or corrupted; restore manually before re-running |

## Re-sync (status: `upstream-changed`)

1. **Pull the entry from `kepano-sync.json`** — note `kepano_skill`, `kepano_section_path`, `kepano_section_heading`, `synced_at_sha`, `target_file`, `body_sha256` (stored).

2. **Inspect upstream changes** between stored sha and HEAD:

   ```bash
   git -C ~/.cache/organon-plugin/kepano-skills log \
       --oneline <stored_sha>..HEAD -- skills/<kepano-skill>/<section_path>
   git -C ~/.cache/organon-plugin/kepano-skills diff \
       <stored_sha>..HEAD -- skills/<kepano-skill>/<section_path>
   ```

3. **Decide: absorb or diverge.** If the upstream edit conflicts with an Organon-specific convention or framing in the surrounding `organon-*/SKILL.md`, choose §Divergence below instead.

4. **Authorize the absorbed-side edit via the resync token.** The PreToolUse hook blocks Edit/Write/MultiEdit on every `target_file` registered in `kepano-sync.json`. Drop a token listing the paths you intend to edit:

   ```bash
   # Single-file:
   echo "<target_file>" > .organon-resync-token

   # Multi-section batch sharing one target file: list the path once.
   ```

   The hook will allow Edit/Write/MultiEdit on listed paths and emit an audit line to stderr per call. The token is `.gitignored` and pre-commit refuses if it leaks.

5. **Pull the new content into `target_file`**, replacing only the bytes between `<!-- KEPANO-BEGIN -->` and `<!-- KEPANO-END -->`. The marker form:

   ```
   <!-- KEPANO-BEGIN: <kepano-skill> <section_path> [§<heading>] @sha:<new-short-sha> -->
   <!-- kepano-sync: see kepano-sync.json for body_sha256 + drift status -->

   [verbatim absorbed content]

   <!-- KEPANO-END: <kepano-skill> <section_path> [§<heading>] -->
   ```

   Update the `@sha:` short SHA on the BEGIN marker.

6. **Revoke the token.** As soon as the edit batch on absorbed files is complete:

   ```bash
   rm -f .organon-resync-token
   ```

   This is mandatory before commit. The pre-commit hook refuses while the token exists.

7. **Recompute `body_sha256`** — see §Hash recomputation. Use the same extraction shape the script uses for that entry.

8. **Update `kepano-sync.json`** entry (the ledger is not blocked — only `target_file` paths are):
   - `synced_at_sha`: new upstream HEAD full SHA.
   - `synced_at_date`: today, ISO-8601 (`date -u +%F`).
   - `body_sha256`: new sha from step 7.
   - `drift_status`: `"in-sync"`.

9. **Re-run** `./scripts/sync-kepano.sh` — confirm `in-sync` for this section.

10. **Test the affected `organon-*` skill** — load it in a fresh chat, confirm the absorbed content reads coherently with the surrounding `SKILL.md`. If the upstream edit changed terminology that the framing prose references, update the framing prose in a separate commit.

11. **Commit** using the form in `commit-template.txt`. The re-sync commit must contain *only* the absorbed file + `kepano-sync.json` change. The pre-commit hook will (a) verify token absence, then (b) re-run `sync-kepano.sh --no-fetch` to confirm in-sync.

## Hash recomputation

The script's extraction shape varies by `kepano_section_heading` value. Match it exactly.

### `(full body)` — SKILL.md whole-body absorption

The script strips the YAML frontmatter (everything before the second `---` line):

```bash
awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
    ~/.cache/organon-plugin/kepano-skills/skills/<kepano-skill>/SKILL.md \
  | shasum -a 256 | awk '{print $1}'
```

### `(full file)` — whole-file absorption (e.g. `references/EMBEDS.md`)

```bash
shasum -a 256 \
    ~/.cache/organon-plugin/kepano-skills/skills/<kepano-skill>/<path> \
  | awk '{print $1}'
```

### Section heading (e.g. `## Diagrams (Mermaid)`)

The script's `extract_section` awk function in `scripts/sync-kepano.sh` is the reference. Easiest reproduction: invoke the script with `--no-fetch --json`, find the section, read its `detected_sha256` field — that's the value to store.

```bash
./scripts/sync-kepano.sh --no-fetch --json \
  | jq -r '.sections[] | select(.kepano_section_path=="<path>" and .kepano_section_heading=="<heading>") | .detected_sha256'
```

### Footgun: trailing newline

Bash command substitution `$(…)` strips trailing newlines. If you compute the sha by piping a command-substituted body into `shasum`, the result will mismatch what the script computes (which uses a temp file). Always extract to a temp file first:

```bash
tmp="$(mktemp)"
awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
    ~/.cache/organon-plugin/kepano-skills/skills/<skill>/SKILL.md > "$tmp"
shasum -a 256 < "$tmp" | awk '{print $1}'
rm "$tmp"
```

## Target-corrupt (status: `target-corrupt`)

The upstream is in-sync with the stored sha, but the plugin target body between `<!-- KEPANO-BEGIN -->` / `<!-- KEPANO-END -->` markers does not. Cause: a direct edit landed in the plugin target without going through the resync flow.

The fix is to **restore the absorbed copy from the upstream cache** — exactly the §Re-sync flow above, except `body_sha256`, `synced_at_sha`, and `synced_at_date` in `kepano-sync.json` do NOT change (the stored sha is correct; only the plugin target needs to be brought back into alignment).

1. Authorize the absorbed-side edit via the resync token (see step 4 of §Re-sync).
2. Re-extract from the upstream cache (using the appropriate extraction shape per §Hash recomputation) into the marker region of the plugin target. Preserve the surrounding framing layout.
3. Revoke the token (`rm -f .organon-resync-token`).
4. **Do not change `body_sha256`, `synced_at_sha`, or `synced_at_date`** — the stored fingerprint is already correct (upstream matches it). Updating them would mask the corruption history.
5. Re-run `./scripts/sync-kepano.sh --no-fetch` — must report `in-sync` for this section. Both `detected_sha256` and `detected_target_sha256` should equal `stored_sha256`.
6. Commit only the absorbed file (no `kepano-sync.json` change). Suggested message: `organon: restore <section> from kepano (target-corrupt repair)`.

## Heading rename (status: `heading-removed`)

The script matches sections by exact heading text. A rename trips `heading-removed`.

1. **Confirm the rename** — list current upstream headings:

   ```bash
   grep -n '^#' ~/.cache/organon-plugin/kepano-skills/skills/<kepano-skill>/<section_path>
   ```

2. **Decide:**
   - **Adopt the rename**: update `kepano_section_heading` in `kepano-sync.json` to the new heading, then proceed as §Re-sync from step 4.
   - **Reject the rename**: leave `kepano_section_heading` unchanged, add a `note` field documenting why (e.g., "kepano renamed cosmetically @<sha>; we keep our heading for continuity"). Drift will continue to be reported — that's the cost of divergence.
   - **Section removed entirely**: evaluate whether Organon still needs the content. If yes, the absorbed material becomes Organon-owned: remove the `<!-- KEPANO-* -->` markers, delete the entry from `kepano-sync.json`, restate the content as native Organon convention in the surrounding `SKILL.md`.

## Divergence (intentional non-absorption)

When an upstream edit conflicts with an Organon-specific convention, do not absorb. Instead:

1. **Do not change `body_sha256`** — drift remains reported (desired: visible reminder of divergence).
2. **Bump `synced_at_sha`** to the upstream commit at the time of the divergence decision — future runs measure drift against the post-decision baseline.
3. **Add `note`** field to the `kepano-sync.json` entry: short rationale + decision date.
4. **Commit** with message: `organon: diverge from kepano @<short-sha> on <section> — <reason>`.

## Add a new absorption (not a re-sync; included for symmetry)

When kepano publishes new content worth absorbing:

1. Pick the `organon-*` skill that owns the cascade.
2. Decide inline (≤ ~30 lines, in `SKILL.md`) vs `references/<NAME>.md`.
3. Insert the marker pair around the absorbed content.
4. Compute `body_sha256` (§Hash recomputation).
5. Add a new entry to `kepano-sync.json` with `drift_status: "in-sync"`.
6. Run `./scripts/sync-kepano.sh` — confirm `in-sync` for the new entry.
7. Update the surrounding `SKILL.md` framing prose if the new content needs a new pointer.
8. Commit: `organon: absorb kepano <section> @<short-sha> into <target>`.
