---
name: vault-resync
description: Resolve drift detected by `scripts/sync-vault.sh` against the live Organon vault (`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`). Run when the script exits 1 (drift) — re-extract the absorbed vault body, replace it inside the `<!-- VAULT-BEGIN -->` / `<!-- VAULT-END -->` markers in the plugin target file, recompute `body_sha256`, bump `synced_at_date` in `vault-sync.json`, and stage the bundled commit. User-only — has side effects on absorbed content and the sync ledger. Skipping the marker update or bumping `synced_at_date` without recomputing `body_sha256` is the recurring failure mode this skill prevents. Vault-side parallel to `kepano-resync` (same Option D markers, same hash-recompute discipline) — but the vault detector hashes only the live vault file, not the plugin target, which makes direct edits to plugin targets *silently invisible* to drift detection. The PreToolUse hook is the primary protection there; this skill is the legitimate update path.
disable-model-invocation: true
---

# vault-resync

End-to-end runbook for resolving drift between the organon plugin's absorbed vault content and the live Organon vault. Bundles the detection invocation, per-status resolution paths, hash-recomputation commands, and the commit template. The reference checklist (`references/RESOLUTION_CHECKLIST.md`) is the operational artifact — load it on any non-trivial drift; load `references/commit-template.txt` when staging.

Source of truth for *why* the absorption pattern exists: `docs/syncing-vault.md` and the v0.5.0 release notes (Tier 1 + Tier 2 absorption). This skill is the *operational* layer; the doc is the *design* layer.

## When this skill applies

- `./scripts/sync-vault.sh` exited 1.
- `vault-sync.json` reports any non-`in-sync` `drift_status`.
- A vault registre / vocabulaire / méthodologie note was edited and a defensive re-sync is in scope (e.g., a FIN-BL or SD-BL touched the registre).
- The user explicitly invokes `/vault-resync`.

Not applicable when: the vault path itself moved (that's a `vault-sync.json` `vault_root` schema change, not drift) — escalate to PA, do not auto-edit.

## Detection

```bash
./scripts/sync-vault.sh                 # text report, exit 1 on drift
./scripts/sync-vault.sh --json | jq .   # machine-readable
```

The script reads each entry's `vault_path`, snapshots the live vault file via `mktemp` (atomicity guard against Obsidian/Linter rewriting mid-script), extracts the body per `extract_mode`, and hashes the result. No upstream fetch — the vault is local.

Status values and routing (full table in `references/RESOLUTION_CHECKLIST.md` §Statuses):

- `in-sync` — no action.
- `vault-changed` — body differs ; review the vault diff, decide whether to absorb, follow §Re-sync below.
- `section-missing` — section heading was renamed or removed in the vault file ; routing in `references/RESOLUTION_CHECKLIST.md` §Heading rename.
- `vault-file-missing` — the source file is gone from the vault ; manual investigation, escalate to PA.

## Re-sync flow (per drifted entry)

For each entry reported as drifted, work the steps in `references/RESOLUTION_CHECKLIST.md`. Summary of the load-bearing invariants:

1. **Inspect the vault change first.** Most vault edits are improvements (PA owns both ends), but some upstream edits may conflict with Organon-specific framing in the surrounding plugin reference file's prose. Divergence is a valid outcome (see §Divergence below).
2. **Replace the absorbed body between the markers**, never outside them. Framing prose outside the `<!-- VAULT-BEGIN -->` / `<!-- VAULT-END -->` markers is Organon-owned and stays put.
3. **Update the marker comment's `@synced:<date>`** to today's ISO-8601 date. The marker form is fixed (Option D — heading + `body_sha256`); do not improvise alternative marker shapes.
4. **Recompute `body_sha256` using the same extraction the script uses.** Any other extraction will produce a sha that the script reports as still drifted. Commands per `extract_mode` are in `references/RESOLUTION_CHECKLIST.md` §Hash recomputation. The trailing-newline footgun: bash command substitution strips trailing newlines — use the temp-file pattern (`extract … > "$tmp"; sha256_of < "$tmp"`).
5. **Update `vault-sync.json`** entry: bump `synced_at_date` (today, ISO-8601), `body_sha256`, set `drift_status: "in-sync"`.
6. **Re-run `./scripts/sync-vault.sh`** — must report `in-sync` for the touched entry. If it doesn't, your sha computation didn't match the script (almost always trailing-newline).
7. **Test the affected `organon-frontmatter` skill** before committing — minimum: load it in a fresh chat and confirm the absorbed content reads coherently with the surrounding `SKILL.md`. The framing prose may now contradict the new content (e.g., a vocabulary added or removed).
8. **Bundle the commit**: absorbed file + `vault-sync.json` in the same commit. Use the message form in `references/commit-template.txt`.

## Two-entry coupling for vocabulary changes

The vault file `[[Registre des clés de frontmatter]]` carries a governance rule: "ajouter une valeur à un enum = éditer la note vocabulaire + ajuster cette ligne du Registre dans la même unité de travail." So a vocab change usually surfaces as drift on **two** entries:

- The Vocabulaire `Valeurs` section (target: `references/VOCABULARIES.md` §<key>).
- The corresponding cell/row in `references/REGISTRE_KEYS.md`.

If only one entry drifts, that's a vault governance violation worth flagging to PA before re-syncing — PA fixes the vault, then both entries drift, then this skill resolves both in one bundled commit.

## Divergence (intentional non-absorption)

Some vault changes shouldn't be absorbed — e.g. PA renames a section cosmetically in the vault, or a vault edit conflicts with a plugin-specific framing decision. In that case:

- Do *not* update `body_sha256` (drift will continue to be reported — desired).
- Add a `note` field to the `vault-sync.json` entry explaining the divergence and the date the decision was made.
- Bump `synced_at_date` to *today* — so future runs measure drift against the post-decision baseline, not pre-decision (semantic same as `kepano-resync` bumping `synced_at_sha`, but without an upstream sha).
- Document the rationale in the commit message ("organon: diverge from vault on <entry> — <reason>").

Note: vault-side divergence is rarer than kepano-side — PA owns both ends, so the usual move is to fix the conflict in the vault rather than diverge in the plugin.

## Anti-patterns

- **Bumping `synced_at_date` without recomputing `body_sha256`** — the script reports `in-sync` because the stored sha matches the live vault body, but if you forgot to update the absorbed copy in the plugin target, the plugin now silently lies. The script *cannot* catch this: it hashes only the live vault file, never the plugin target.
- **Editing absorbed plugin content outside this skill's flow** — the PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`) blocks this for a reason: drops the marker invariants and corrupts the sync ledger silently. Don't override it.
- **Auto-resolving `section-missing` by guessing the new heading** — the vault file may have been intentionally restructured; a guess can absorb the wrong section. Always `grep -n '^#' <vault-file>` first.
- **Single combined commit covering re-sync + an unrelated content edit to the surrounding `SKILL.md`** — makes future audits of "what came from the vault vs what is plugin-owned" impossible. Split.

## Files

- `references/RESOLUTION_CHECKLIST.md` — the per-status step-by-step.
- `references/commit-template.txt` — commit message form for the bundled re-sync commit.
- `vault-sync.json` (repo root) — the sync ledger; the source of truth for `target_file` paths and stored shas.
- `scripts/sync-vault.sh` — the detector.
- `docs/syncing-vault.md` — design-layer documentation (when in conflict with this skill, this skill wins for operational steps; the doc wins for *why*).
