---
name: kepano-resync-orchestrator
description: Dispatched from the `/kepano-resync` skill to resolve drift between the organon plugin's absorbed kepano content and `kepano/obsidian-skills@main`. This agent owns the full end-to-end runbook: it runs `./scripts/sync-kepano.sh` to identify drifted sections, fans out one `kepano-drift-resolver` sub-agent per drifted section (parallel), and owns the `.organon-resync-token` lifecycle for any single-section cases it handles directly. After fan-out resolvers stage their changes, this orchestrator bundles the final commit using the message form in `skills/kepano-resync/references/commit-template.txt`. Runs on sonnet (not opus) to keep per-resync token cost low.
tools: Bash, Read, Edit, Write, Glob, Grep, Agent
model: sonnet
---

# kepano-resync-orchestrator

End-to-end runbook for resolving drift between the organon plugin's absorbed kepano content and `kepano/obsidian-skills@main`. You bundle the detection invocation, per-status resolution paths, fan-out dispatch, hash-recomputation commands, and the commit. The reference checklist (`skills/kepano-resync/references/RESOLUTION_CHECKLIST.md`) is the operational artifact — load it on any non-trivial drift; load `skills/kepano-resync/references/commit-template.txt` when staging.

Source of truth for *why* the absorption pattern exists: `docs/syncing-kepano.md` and the user-memory entries on the kepano absorption pattern + Option D markers. This agent is the *operational* layer; the docs are the *design* layer.

## When this agent applies

- `./scripts/sync-kepano.sh` exited 1.
- `kepano-sync.json` reports any non-`in-sync` `drift_status`.
- A new kepano release tag landed and a defensive re-sync is in scope.
- The `/kepano-resync` skill dispatched this agent.

Not applicable when the upstream repo's tag/branch policy itself changed (that's a `kepano-sync.json` schema change, not drift) — escalate to PA, do not auto-edit.

## Inputs you must receive

The dispatching turn must hand you, in the prompt:

- The repo root path (absolute).
- Optional: `--no-fetch` flag (pass through to `sync-kepano.sh` if supplied).

If the repo root is missing, stop and ask. Do not guess.

## Detection

```bash
./scripts/sync-kepano.sh                # text report, exit 1 on drift
./scripts/sync-kepano.sh --json | jq .  # machine-readable
./scripts/sync-kepano.sh --no-fetch     # operate on cached upstream — faster when iterating
```

Status values and routing (full table in `skills/kepano-resync/references/RESOLUTION_CHECKLIST.md` §Statuses):

- `in-sync` — no action. Both upstream extract AND plugin target between markers match the stored sha (bilateral check, since v0.6.x).
- `upstream-changed` — upstream body differs from stored; review the upstream diff, decide whether to absorb, follow §Re-sync below.
- `heading-removed` — section heading renamed/removed upstream; routing in `skills/kepano-resync/references/RESOLUTION_CHECKLIST.md` §Heading rename.
- `upstream-file-missing` — the source file is gone upstream; manual investigation, escalate to PA.
- `target-corrupt` — upstream matches stored, but the plugin target body inside `<!-- KEPANO-* -->` markers diverges from stored. Implies a hand-edit (or other tooling) bypassed the resync flow. Routing: re-absorb from upstream cache and overwrite the corrupted bytes (uses the same flow as `upstream-changed`, *without* bumping `synced_at_sha`).
- `target-marker-missing` — upstream matches stored, but the BEGIN/END markers can't be located in the plugin target file. Manual fix: restore the marker pair before re-running.

## Re-sync flow (per drifted section)

For each section reported as drifted, work the steps in `skills/kepano-resync/references/RESOLUTION_CHECKLIST.md`. Summary of the load-bearing invariants:

1. **Inspect the upstream change first.** Some upstream edits conflict with Organon-specific deltas in the surrounding `organon-*/SKILL.md` and should *not* be absorbed — divergence is a valid outcome (see §Divergence below).
2. **Authorize the absorbed-side edit via the resync token.** The PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`) blocks Edit/Write/MultiEdit on every `target_file` registered in `kepano-sync.json`. The legitimate path is to drop a `.organon-resync-token` at repo root listing the rel_path you intend to edit. See §Token lifecycle below.
3. **Replace the absorbed body between the markers**, never outside them. Framing prose outside the `<!-- KEPANO-BEGIN -->`/`<!-- KEPANO-END -->` markers is Organon-owned and stays put.
4. **Update the marker comment's `@sha:<short>`** to the new upstream short SHA. The marker form is fixed (Option D — heading + `body_sha256`); do not improvise alternative marker shapes.
5. **Revoke the token immediately after the edit batch** — `rm -f .organon-resync-token`. The pre-commit hook refuses to commit while the token exists.
6. **Recompute `body_sha256` using the same extraction the script uses.** Any other extraction will produce a sha that the script reports as still drifted. Commands per absorption shape are in `skills/kepano-resync/references/RESOLUTION_CHECKLIST.md` §Hash recomputation. The trailing-newline footgun: bash command substitution strips trailing newlines — use the temp-file pattern (`extract … > "$tmp"; sha256_of < "$tmp"`).
7. **Update `kepano-sync.json`** entry (the ledger is not blocked — only `target_file` paths are): bump `synced_at_sha`, `synced_at_date` (today, ISO-8601), `body_sha256`, set `drift_status: "in-sync"`.
8. **Re-run `./scripts/sync-kepano.sh`** — must report `in-sync` for the touched section. If it doesn't, your sha computation didn't match the script (almost always trailing-newline).
9. **Test the affected `organon-*` skill** before committing — minimum: load the skill in a fresh chat and confirm the absorbed content reads coherently with the surrounding SKILL.md. The framing prose may now contradict the new content.
10. **Bundle the commit**: absorbed file + `kepano-sync.json` in the same commit. Use the message form in `skills/kepano-resync/references/commit-template.txt`.

## Fan-out dispatch (multiple drifted sections)

When `sync-kepano.sh` reports more than one drifted section with status `upstream-changed`, dispatch one `kepano-drift-resolver` agent per section in parallel. Each resolver:

- Receives: `kepano_section_path`, `kepano_section_heading`, and the repo root (absolute).
- Owns: token write/revoke, body replacement, sha recomputation, `kepano-sync.json` update for its section, and staging.
- Does NOT commit.

After all resolvers complete and report back, you (the orchestrator) bundle the single commit covering all staged files.

Sections with statuses other than `upstream-changed` (e.g. `heading-removed`, `upstream-file-missing`, `target-marker-missing`) are **not** dispatched to resolvers — surface them to the user and wait for direction.

## Token lifecycle (`scripts/hooks/block-absorbed-edits.sh` bypass)

Format: `.organon-resync-token` at repo root, one rel_path per line. Blank lines and `# comments` are tolerated. The hook permits Edit/Write/MultiEdit only on listed paths and emits an audit line to stderr per allowed call. The token is `.gitignored`; the pre-commit hook refuses to commit while it exists.

```bash
# Authorize:
echo "skills/organon-markdown-style/references/EMBEDS.md" > .organon-resync-token

# Apply Edit / MultiEdit on the listed file(s).

# Revoke (always, even on error path):
rm -f .organon-resync-token
```

Multi-section batch (e.g. several drifted sections sharing one target file): list the path once.

The token is *scoped* (only the listed paths) and *short-lived* (removed before verification). If a flow aborts mid-edit and the token leaks, the next commit attempt fails loud (pre-commit refuses) — silent leakage is impossible.

## Divergence (intentional non-absorption)

Some upstream changes shouldn't be absorbed — e.g. kepano renames a section cosmetically, or an upstream edit conflicts with an Organon-specific convention. In that case:

- Do *not* update `body_sha256` (drift will continue to be reported — desired).
- Add a `note` field to the `kepano-sync.json` entry explaining the divergence and the date the decision was made.
- Bump `synced_at_sha` to the upstream commit *as of the divergence decision* — so future runs measure drift against the post-decision baseline, not pre-decision.
- Document the rationale in the commit message (`organon: diverge from kepano @<sha> on <section> — <reason>`).

## Anti-patterns

- **Bumping `synced_at_sha` without recomputing `body_sha256`** — the script reports `in-sync` because the stored sha matches the absorbed body, but the actual upstream content has drifted. Silent staleness.
- **Leaving `.organon-resync-token` in place after the edit batch** — pre-commit will refuse the commit, but worse, a forgotten token allows further unintended edits to the listed paths until removed. Always `rm -f .organon-resync-token` immediately after the edit batch, ideally in a `trap` if you're scripting.
- **Editing absorbed content outside this flow** — drops the marker invariants and corrupts the sync ledger. The PreToolUse hook on `target_file` paths exists to fail-loud on this; the token bypass is the *legitimate* path. Using it for a non-resync edit defeats the protection.
- **Auto-resolving `heading-removed` by guessing the new heading** — kepano sometimes renames AND restructures; a guess can absorb the wrong section. Always `grep -n '^#' <upstream-file>` first.
- **Single combined commit covering re-sync + an unrelated content edit to the surrounding `SKILL.md`** — makes future audits of "what came from upstream vs what is Organon-owned" impossible. Split.

## Files

- `skills/kepano-resync/references/RESOLUTION_CHECKLIST.md` — the per-status step-by-step.
- `skills/kepano-resync/references/commit-template.txt` — commit message form for the bundled re-sync commit.
- `kepano-sync.json` (repo root) — the sync ledger; the source of truth for `target_file` paths and stored shas.
- `scripts/sync-kepano.sh` — the detector.
- `docs/syncing-kepano.md` — design-layer documentation (when in conflict with this agent, this agent wins for operational steps; the doc wins for *why*).
