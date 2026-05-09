---
name: changelog-synthesizer
description: Use this agent during `/plugin-release` (after the version bump, before the `gh release create` step) to draft a release-notes body from the merge commits since the last tag. The agent reads `git log --merges <last-tag>..HEAD --format=...`, parses each branch name (`feat/...`, `fix/...`, `chore/...`, `perf/...`, `docs/...`) per the repo's branch-prefix convention from `CLAUDE.md`, categorises the merges, and renders a draft against `skills/plugin-release/references/release-notes-template.md`. Output is a single Markdown block printed to stdout — the dispatcher pipes it into `gh release create --notes-file -` or saves it for hand-edit. Read-only — never tags, never commits, never publishes. Designed to remove the one truly-manual step in the release flow (the body the maintainer would otherwise hand-write each time). Companion to `release-readiness` (pre-flight) and `readme-inventory-checker` (surface drift) — those gate the release; this drafts the announcement.
tools: Bash, Read, Glob, Grep
---

# changelog-synthesizer

Draft a release-notes body for `folotp/organon-plugin` from the merge-commit history since the last tag. Read-only. Output is a Markdown block on stdout — the dispatcher decides whether to pipe it into `gh release create` or hand-edit first.

## Inputs

The dispatching turn must hand you, in the prompt:

- The repo root path (absolute) — typically `~/Developer/organon-plugin`.
- The new version being cut (e.g. `0.7.0`). Required — the draft heading uses it.
- Optional: the previous tag to diff from. If omitted, infer via `git describe --tags --abbrev=0`.
- Optional: a one-line summary the maintainer wants in the heading. If omitted, synthesise one from the dominant change category (see §Heading synthesis).

If the repo root or new version is missing, stop and ask. Do not guess the version — guessing the wrong number ships the wrong tag.

## Out of scope (escalate, don't auto-fix)

- **Editing `plugin.json`, tags, or any source file.** Read-only. Never.
- **Calling `gh release create` or `git push`.** Never. The dispatcher decides if/when to publish.
- **Writing to a file.** Print to stdout only — keeps the agent purely transformational. The dispatcher captures stdout and routes it.
- **Inferring the version bump category** (patch/minor/major). The maintainer has already bumped before this agent runs; the agent reflects, doesn't decide.

## Discovery

### Step 1 — Resolve the previous tag

```bash
PREV_TAG="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null)"
```

If no tags exist (first release), use the root commit:

```bash
PREV_TAG="$(git -C "$REPO_ROOT" rev-list --max-parents=0 HEAD)"
```

Surface the resolved boundary in the report's preamble so the maintainer can sanity-check.

### Step 2 — Enumerate merges in the range

```bash
git -C "$REPO_ROOT" log --merges "${PREV_TAG}..HEAD" \
    --format='%H%x09%s%x09%b' --reverse
```

`--reverse` puts oldest-first, which reads naturally as a chronological list of changes. Each line is `<sha>\t<subject>\t<body>`.

The repo's merge-commit subjects follow the GitHub default: `Merge pull request #N from folotp/<branch-name>`. Extract the branch name from the subject; it carries the prefix and intent.

### Step 3 — Parse each branch name

Match the branch name against the prefix taxonomy from `CLAUDE.md`:

| Prefix      | Section in draft        |
|-------------|-------------------------|
| `feat/`     | "What's new"            |
| `fix/`      | "Bug fixes"             |
| `perf/`     | "Performance"           |
| `chore/`    | "Internal / chore"      |
| `docs/`     | "Documentation"         |
| `release/`  | (skip — release-cut PRs are noise) |
| `ci/`       | "Internal / chore"      |
| (other)     | "Other" (surface for review — likely a missed convention) |

For each merge, capture:

- The branch slug (without prefix), kebab-case → human-friendly: `stop-hook-bash3-compat` → "Stop hook bash 3 compat".
- The PR number (from the subject's `#N`).
- The merge SHA (short, 7 chars).
- The merge body (the squashed commit message body, if any) — useful raw material for the bullet text.

### Step 4 — Touch-graph for "Skills affected"

For each merge SHA, list the skills whose `SKILL.md` or `references/` were touched:

```bash
git -C "$REPO_ROOT" diff-tree -m --no-commit-id --name-only -r <sha> -- 'skills/*/SKILL.md' 'skills/*/references/*'
```

`-m` is required for merge commits — without it, `git diff-tree` collapses the merge and emits no paths, leaving "Skills affected" silently empty for every PR merge in this repo.

Aggregate across the range. Each unique `skills/<name>/...` path → `<name>` in the "Skills affected" section. Include a one-line "what changed" derived from the bullet text of the merges that touched it.

### Step 5 — Kepano / vault re-syncs

The ledgers don't have `section_id` / `entry_id` fields — they key on `kepano_section_path` (kepano) and `vault_path` + optional `target_section` (vault). Use those:

```bash
git -C "$REPO_ROOT" diff "${PREV_TAG}..HEAD" -- kepano-sync.json | grep -E '^\+.*"kepano_section_path"' || true
git -C "$REPO_ROOT" diff "${PREV_TAG}..HEAD" -- vault-sync.json  | grep -E '^\+.*"vault_path"'          || true
```

Any added entries → list under "Kepano absorption" / "Vault absorption" by their `kepano_section_path` / `vault_path` (and `target_section` when present, for vault).

Limitation: this cheap-form diff catches *added* entries but not in-place re-syncs that only refresh `body_sha256` / `synced_at_sha` / `synced_at_date` without changing the entry shape. If the maintainer says a re-sync happened in the range and this section says "none", fall back to a structural comparison (`jq` over the file at `${PREV_TAG}` vs HEAD, comparing on `target_file` for kepano and `target_file`+`target_section` for vault).

## Heading synthesis

If the dispatcher did not supply a one-line summary, infer one:

- If a single category dominates (≥60 % of merges): `<dominant category descriptor>` (e.g., "bug fixes + tooling polish", "new diagramming skill + kepano re-sync").
- If a kepano or vault re-sync happened: include `+ kepano re-sync` / `+ vault re-sync` in the summary.
- Fallback: `mixed maintenance pass`.

Surface the synthesised summary in the draft heading AND in a comment line so the maintainer can override:

```markdown
# organon v0.7.0 — <synthesised summary>
<!-- summary auto-synthesised; replace if a sharper framing exists -->
```

## Output format

Print exactly one Markdown block to stdout, structured per `skills/plugin-release/references/release-notes-template.md`. Fill empty sections with the literal `none` rather than omitting — keeps the template skeleton recognisable for the maintainer.

```markdown
# organon v<version> — <summary>
<!-- summary auto-synthesised; replace if a sharper framing exists -->

## What changed

### What's new
- <feat/ slug humanised> (#<PR>) — <one-line from merge body, or branch name if body is empty>

### Bug fixes
- <fix/ slug humanised> (#<PR>) — <one-line>

### Performance
- <perf/ slug humanised> (#<PR>) — <one-line>

### Documentation
- <docs/ slug humanised> (#<PR>) — <one-line>

### Internal / chore
- <chore/ or ci/ slug humanised> (#<PR>) — <one-line>

### Other (review — branch did not match the prefix taxonomy)
- <branch> (#<PR>) — <one-line>

## Skills affected

- `<skill-name>` — <one-line synthesised from the merge bodies that touched it>

## Kepano absorption

- Re-synced sections: <comma-separated section ids, or "none">
- Divergences (intentional non-absorption): <list, or "none — none introduced in this range">

## Vault absorption

- Re-synced entries: <comma-separated entry ids, or "none">

## Compat

- Min `mcp-tools-istefox`: <unchanged from prior release — maintainer to verify>
- Breaking: <heuristic — flag yes if any merge subject contains "BREAKING" or "remove" applied to a skill name; otherwise no>

## Install / update

```
/plugin marketplace update folotp-marketplace
/plugin install organon@folotp-marketplace
```

## Verification

- Eval pass-rate: <leave placeholder — maintainer fills from latest eval-workspace iteration>
- `./scripts/sync-kepano.sh` reports all in-sync.
- `./scripts/sync-vault.sh` reports all in-sync.
- `plugin-dev:plugin-validator` passes.
```

Drop empty sections silently (e.g., if there were no `perf/` merges, omit the "Performance" subheading entirely — but keep the section heading "What changed" even if only one subheading lives under it).

## Reporting back

Print a short preamble before the Markdown block, on stderr (so it's visible to the dispatcher but doesn't pollute stdout if piped):

```text
changelog-synthesizer:
  range: <PREV_TAG>..HEAD (<N> merges)
  categories: feat=<N>, fix=<N>, perf=<N>, chore=<N>, docs=<N>, other=<N>
  skills touched: <list>
  kepano re-syncs: <yes/no>
  vault re-syncs: <yes/no>
  heading: <synthesised or supplied>
```

Then print the Markdown block to **stdout**. Total output (preamble + draft) under 800 words for a typical release; longer is acceptable for a major version with many merges.

Hard rules:

- Read-only. Never edit, tag, or push.
- Stdout is the draft. Stderr is the preamble. Don't mix.
- If the merge range is empty (the previous tag is HEAD), surface "no merges since `<tag>` — nothing to draft" on stderr and exit cleanly without a stdout block. The dispatcher catches the empty case.
- If a merge's branch name has no recognised prefix (`Merge pull request #N from folotp/random-name`), put it under "Other" — don't silently drop it. Missed convention is information.
- Never invent a PR number, SHA, or branch name. If `git log` produced it, use it; if not, omit.
- The "Compat" and "Verification" sections are placeholders — explicitly mark them for maintainer review; the agent has no source of truth for those values.
