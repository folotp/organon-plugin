---
name: kepano-resync
description: Resolve drift detected by `scripts/sync-kepano.sh` against the upstream kepano `obsidian-skills` repo. Run when the script exits 1 (drift) — regenerate `body_sha256`, update the absorbed file under `skills/*/references/` between its `<!-- KEPANO-BEGIN -->`/`<!-- KEPANO-END -->` markers, bump `synced_at_sha`/`synced_at_date` in `kepano-sync.json`, and stage the bundled commit. User-only — has side effects on absorbed content and the sync ledger. Skipping the marker update or bumping `synced_at_sha` without recomputing `body_sha256` is the recurring failure mode this skill prevents.
disable-model-invocation: true
---

# kepano-resync

End-to-end runbook for resolving drift between the organon plugin's absorbed kepano content and `kepano/obsidian-skills@main`. Bundles the detection invocation, per-status resolution paths, hash-recomputation commands, and the commit template. The reference checklist (`references/RESOLUTION_CHECKLIST.md`) is the operational artifact — load it on any non-trivial drift; load `references/commit-template.txt` when staging.

Source of truth for *why* the absorption pattern exists: `docs/syncing-kepano.md` and the user-memory entries on the kepano absorption pattern + Option D markers. This skill is the *operational* layer; the docs are the *design* layer.

## When this skill applies

- `./scripts/sync-kepano.sh` exited 1.
- `kepano-sync.json` reports any non-`in-sync` `drift_status`.
- A new kepano release tag landed and a defensive re-sync is in scope.
- The user explicitly invokes `/kepano-resync`.

Not applicable when: the upstream repo's tag/branch policy itself changed (that's a `kepano-sync.json` schema change, not drift) — escalate to PA, do not auto-edit.

## Detection

```bash
./scripts/sync-kepano.sh                # text report, exit 1 on drift
./scripts/sync-kepano.sh --json | jq .  # machine-readable
./scripts/sync-kepano.sh --no-fetch     # operate on cached upstream — faster when iterating
```

Status values and routing (full table in `references/RESOLUTION_CHECKLIST.md` §Statuses):

- `in-sync` — no action.
- `upstream-changed` — body differs ; review the upstream diff, decide whether to absorb, follow §Re-sync below.
- `heading-removed` — section heading renamed/removed upstream ; routing in `references/RESOLUTION_CHECKLIST.md` §Heading rename.
- `upstream-file-missing` — the source file is gone upstream ; manual investigation, escalate to PA.

## Re-sync flow (per drifted section)

For each section reported as drifted, work the steps in `references/RESOLUTION_CHECKLIST.md`. Summary of the load-bearing invariants:

1. **Inspect the upstream change first.** Some upstream edits conflict with Organon-specific deltas in the surrounding `organon-*/SKILL.md` and should *not* be absorbed — divergence is a valid outcome (see §Divergence below).
2. **Authorize the absorbed-side edit via the resync token.** The PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`) blocks Edit/Write/MultiEdit on every `target_file` registered in `kepano-sync.json`. The legitimate path is to drop a `.organon-resync-token` at repo root listing the rel_path you intend to edit. See §Token lifecycle below.
3. **Replace the absorbed body between the markers**, never outside them. Framing prose outside the `<!-- KEPANO-BEGIN -->`/`<!-- KEPANO-END -->` markers is Organon-owned and stays put.
4. **Update the marker comment's `@sha:<short>`** to the new upstream short SHA. The marker form is fixed (Option D — heading + `body_sha256`); do not improvise alternative marker shapes.
5. **Revoke the token immediately after the edit batch** — `rm -f .organon-resync-token`. The pre-commit hook refuses to commit while the token exists.
6. **Recompute `body_sha256` using the same extraction the script uses.** Any other extraction will produce a sha that the script reports as still drifted. Commands per absorption shape are in `references/RESOLUTION_CHECKLIST.md` §Hash recomputation. The trailing-newline footgun: bash command substitution strips trailing newlines — use the temp-file pattern (`extract … > "$tmp"; sha256_of < "$tmp"`).
7. **Update `kepano-sync.json`** entry (the ledger is not blocked — only `target_file` paths are): bump `synced_at_sha`, `synced_at_date` (today, ISO-8601), `body_sha256`, set `drift_status: "in-sync"`.
8. **Re-run `./scripts/sync-kepano.sh`** — must report `in-sync` for the touched section. If it doesn't, your sha computation didn't match the script (almost always trailing-newline).
9. **Test the affected `organon-*` skill** before committing — minimum: load the skill in a fresh chat and confirm the absorbed content reads coherently with the surrounding SKILL.md. The framing prose may now contradict the new content.
10. **Bundle the commit**: absorbed file + `kepano-sync.json` in the same commit. Use the message form in `references/commit-template.txt`.

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

The token is *scoped* (only the listed paths) and *short-lived* (skill removes it before verification). If a flow aborts mid-edit and the token leaks, the next commit attempt fails loud (pre-commit refuses) — silent leakage is impossible.

## Divergence (intentional non-absorption)

Some upstream changes shouldn't be absorbed — e.g. kepano renames a section cosmetically, or an upstream edit conflicts with an Organon-specific convention. In that case:

- Do *not* update `body_sha256` (drift will continue to be reported — desired).
- Add a `note` field to the `kepano-sync.json` entry explaining the divergence and the date the decision was made.
- Bump `synced_at_sha` to the upstream commit *as of the divergence decision* — so future runs measure drift against the post-decision baseline, not pre-decision.
- Document the rationale in the commit message ("organon: diverge from kepano @<sha> on <section> — <reason>").

## Anti-patterns

- **Bumping `synced_at_sha` without recomputing `body_sha256`** — the script reports `in-sync` because the stored sha matches the absorbed body, but the actual upstream content has drifted. Silent staleness.
- **Leaving `.organon-resync-token` in place after the edit batch** — pre-commit will refuse the commit, but worse, a forgotten token allows further unintended edits to the listed paths until removed. Always `rm -f .organon-resync-token` immediately after the edit batch, ideally in a `trap` if you're scripting.
- **Editing absorbed content outside this skill's flow** — drops the marker invariants and corrupts the sync ledger. The PreToolUse hook on `target_file` paths exists to fail-loud on this; the token bypass is the *legitimate* path. Using it for a non-resync edit defeats the protection.
- **Auto-resolving `heading-removed` by guessing the new heading** — kepano sometimes renames AND restructures; a guess can absorb the wrong section. Always `grep -n '^#' <upstream-file>` first.
- **Single combined commit covering re-sync + an unrelated content edit to the surrounding `SKILL.md`** — makes future audits of "what came from upstream vs what is Organon-owned" impossible. Split.

## Files

- `references/RESOLUTION_CHECKLIST.md` — the per-status step-by-step.
- `references/commit-template.txt` — commit message form for the bundled re-sync commit.
- `kepano-sync.json` (repo root) — the sync ledger; the source of truth for `target_file` paths and stored shas.
- `scripts/sync-kepano.sh` — the detector.
- `docs/syncing-kepano.md` — design-layer documentation (when in conflict with this skill, this skill wins for operational steps; the doc wins for *why*).
