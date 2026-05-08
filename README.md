# organon

Organon vault conventions for Claude — packaged as a Cowork/Claude Code plugin.

## What this plugin provides

Ten skills total: seven description-triggered (load automatically when working with the Organon Obsidian vault at `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`) plus three user-only skills invoked via slash command.

### Core (4 skills, validated in chat 1.A)

- **organon-vault-write** — MCP write discipline via `mcp-tools-istefox` 0.4.5+. Covers Templater-first routing for structured notes (two-step render-then-create / one-step render-and-create via `execute_template`), YAML scalar quoting, frontmatter array vs scalar semantics, `tags:` array shape, heading patch safety, NFC normalization, footguns.
- **organon-frontmatter** — Schema, key ordering, controlled vocabularies, ULID forward-only, `creator:` dual-mode (UI vs MCP), archive/supersession, alias-only versioning, ADR/BL/BUG/INC field requirements. Vocabularies externalized to `references/VOCABULARIES.md` (loaded on-demand).
- **organon-markdown-style** — Body conventions: no H1 in body, language by folder (`99 - Méta/AI/` in EN, rest in FR), typographic apostrophes, no trailing whitespace, no systematic block anchors, table+block-ref pitfall.
- **organon-session-discipline** — 7 behavioral rules: arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder.

### Aux (3 skills, new in v0.2.0 — chat 1.B)

- **organon-bases** — Bases-default policy (Dataview is fallback only with explicit auth, even against directive prompts), Excluded-files trap diagnostic, dv-light optimised config, Organon vocabulary filters.
- **organon-canvas** — Purpose discriminator (cartography of existing notes vs. freeform sketches), placement beside the domain, file-node filename-only paths for vault-move robustness, language by folder for labels, ID convention (kepano 16-char hex).
- **organon-diagramming** — Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for note-cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways), Excalidraw bridge skeleton, plugin compression-OFF invariant, preview-before-persist pattern.

### User-only (3 skills, invoked via slash command — `disable-model-invocation: true`)

- **kepano-resync** (`/kepano-resync`, since v0.4.1) — End-to-end runbook for resolving drift detected by `scripts/sync-kepano.sh`. Re-sync workflow, marker invariants, hash recomputation, divergence handling.
- **plugin-release** (`/plugin-release`, since v0.4.1) — Cut releases: bump version in `plugin.json`, package the `.plugin` archive, tag, create the GitHub Release with the archive uploaded as a Release asset.
- **organon-memory-audit** (`/organon-memory-audit`, since v0.5.0) — Three-pole drift audit aligning plugin/skill/tool reality, the canonical-snippets vault note, and per-surface implementations (Code / Cowork / Chat). Two scope modes (`--scope=global|project|all`) and two interaction modes (`--mode=interactive|report-only`). Edits never auto-applied — drifts and staleness are raised for human-in-the-loop approval.

## Absorbed kepano content (since v0.4.0)

This plugin used to **cascade at runtime** to the upstream [kepano `obsidian-skills`](https://github.com/kepano/obsidian-skills) plugin for generic Obsidian syntax. Since v0.4.0 it **absorbs** the relevant kepano content verbatim into per-skill `references/` files (with HTML provenance markers and a `body_sha256` fingerprint tracked in `kepano-sync.json`). Net effect: when an `organon-*` skill triggers, the kepano cascade no longer needs to load — content lives locally and is read on-demand thanks to progressive disclosure (lean SKILL.md ≤ 1 200 words, bundled refs loaded only when the task requires them).

Drift detection: `./scripts/sync-kepano.sh` compares stored `body_sha256` snapshots against current upstream HEAD and reports per-section status. Re-sync workflow: see [`docs/syncing-kepano.md`](docs/syncing-kepano.md). The script never auto-edits files or commits — review obligatory.

## Absorbed vault content (since v0.5.0)

The plugin also **absorbs Organon vault content** into `organon-frontmatter/references/`: the canonical frontmatter key registry (`REGISTRE_KEYS.md`), ID prefix registry (`PREFIXES.md`), and 12 controlled vocabularies (sectioned inside `VOCABULARIES.md`) — all verbatim, all drift-tracked via `vault-sync.json`. Two distilled methodology references (`METHODOLOGY_ADR.md` and `METHODOLOGY_INC_BUG_BL.md`) carry Claude-actionable subsets of the vault methodologies (no markers — re-derive manually after material changes).

Net effect: when `organon-frontmatter` triggers (e.g., drafting an ADR / VLT-BUG / FIN-DEC), the schema, vocab, and methodology are already loaded — no MCP round-trip to the vault registre needed. The vault remains authoritative on disagreement (banner in each absorbed file).

Drift detection: `./scripts/sync-vault.sh` compares stored `body_sha256` snapshots against the live vault, with `mktemp` snapshotting for atomicity (Obsidian/Linter can rewrite files mid-script). Re-sync workflow: see [`docs/syncing-vault.md`](docs/syncing-vault.md). Mechanism is parallel to and independent of kepano absorption.

## Empirical validation

- **Chat 1.A — 4 core skills** : 3 iterations of skill-creator eval workflow. iter-3 final pass-rate **94 %** with_skill vs 82 % baseline (delta +12 pp).
- **Chat 1.B — 3 aux skills + B1 fix** : 2 iterations. iter-2 final pass-rate **98 %** with_skill (54/55) vs 78 % baseline (43/55) — delta **+20 pp**, 0 regressions, 11 with_skill-only wins.
- Detailed results in `refactor-phase4/wave-1-skills-bootstrap/eval-workspace/` of the Organon project workspace.

## Changes since v0.1.0

### v0.2.0 (chat 1.B initial)
- Added 3 aux skills : `organon-bases`, `organon-canvas`, `organon-diagramming`.
- Fixed B1 : `organon-session-discipline` description bumped from "6 behavioral rules" to "7" (the iter-3 « language coherence » rule was added without the description being updated).

### v0.2.1 (chat 1.B feedback patch)
- `organon-canvas` : explicit ID convention (kepano 16-char hex via cascade) + anti-pattern note on semantic IDs.
- `organon-diagramming` : preview-in-chat-before-persist pattern made explicit on the Excalidraw bridge.

### v0.2.2 (closure Phase 5)
- `organon-frontmatter` : Touch-on-edit refined (≤ 3 keys/edit threshold, canonical journal entry, explicit skip if edit > 10 lines).

### v0.3.0 (P7.1 — session-discipline cache)
- `organon-session-discipline` rule #2 made cache-aware: sha256 manifest + cached AI Bootstrap snapshot in project memory space, ~300 tok saved per cache hit.

### v0.4.0 (VLT-BL-0063 — kepano absorption B4-complet)
- Absorbed verbatim kepano `obsidian-skills` content (commit `fa1e131`) into 5 organon skills via HTML provenance markers and per-skill `references/` files.
- Added `kepano-sync.json` (drift fingerprints), `scripts/sync-kepano.sh` (drift detection — read-only), `docs/syncing-kepano.md` (re-sync runbook).
- Removed runtime cascade to kepano plugin — eliminates the additive cascade load (~1.1k–3.4k tokens saved per session depending on task shape).
- Regression eval: 50/51 (98 %) on representative tasks, matching chat 1.B baseline.

### v0.4.1 (automation runbooks)
- New user-only skills `kepano-resync` and `plugin-release` (both `disable-model-invocation: true`) — end-to-end runbooks for drift resolution and release cuts.

### v0.4.2 (slash-command wrappers)
- New `/kepano-resync` and `/plugin-release` thin slash-command wrappers — make the v0.4.1 runbooks reachable from the picker. No skill content changes.

### v0.4.3 (istefox 0.4.0–0.4.5 alignment)
- Min `mcp-tools-istefox` floor bumped 0.3.12+ → 0.4.5+ (in-process MCP, auto-mkdirp, fail-loud rejects for upstream #80/#81/#84). Min Obsidian: 1.7.2 (transitive).
- **Renamed "Voie B routing" → "Templater-first routing"** across SKILL/README/docs/token-harness — the design-era label was meaningless to readers; the new name describes what the routing actually does. Variants relabeled: "Two-step render-then-create" (BL/BUG/INC/ADR sequential IDs) and "One-step render-and-create" (Note/Concept/Person/etc. — domain-folder-mapped).
- `organon-vault-write` — heading-patch safety **rewritten** based on smoke-test ground truth on istefox 0.4.5: `createTargetIfMissing: false` is **incompatible with Organon's H2-root convention** (triggers istefox 0.4.2 #80 reject on every heading patch since every Organon note is H2-root by design); default `true` silently appends to EOF on missing target. Correct discipline: pre-verify the heading exists with `get_vault_file` before patching. The previous skill text recommending `false` is reversed.
- `organon-vault-write` — also documents 0.4.0 frontmatter array semantics (`replace`-with-scalar on array fields now errors; `append`/`prepend` JSON-decode + auto-wrap), notes 0.4.5 auto-mkdirp on `create_vault_file`/`append_to_vault_file`/`execute_template`, refreshes block-target rejects (0.4.2 #81 table-cell, 0.4.3 #84 fenced-code).
- `organon-markdown-style` — VLT-BUG-015 reframed: table+block-ref + fenced-code-boundary cases are now structural fail-loud rejects (not HTTP 400 footguns), workaround language updated.
- `organon-session-discipline` — rule #2 cache-example refreshed `v0.3.12` → `v0.4.5` to match the new floor.
- Breaking: yes (version pin bumped + heading-patch discipline reversed; callers passing `createTargetIfMissing: false` to Organon notes will now see fail-loud rejects).

### v0.5.0 (vault absorption)
- **Tier 1 — Verbatim absorption with drift tracking** under `skills/organon-frontmatter/references/`:
  - `REGISTRE_KEYS.md` ← full body of vault `[[Registre des clés de frontmatter]]` (~400 lines: global keys, per-type tables, per-domain tables, Tri Linter canonique, retired/in-migration keys).
  - `PREFIXES.md` ← full body of vault `[[Préfixes d'identifiants]]` (FIN/VLT/SD/SPA + reserved + sub-types + protocols).
  - `VOCABULARIES.md` refactored: Organon-curated framing prose for `type`/`status`/`content-model` (cross-linking to `REGISTRE_KEYS.md`) + 12 absorbed sections wrapping verbatim `## Valeurs` tables from each vault `Vocabulaire — <key>.md` (markers + per-section drift tracking).
- **Tier 2 — Distilled Claude-actionable references** (no drift markers; provenance banner only — re-derive manually after material methodology changes):
  - `METHODOLOGY_ADR.md` (~150 lines from vault's 206 — lifecycle, immutability, supersession, callout, anti-patterns).
  - `METHODOLOGY_INC_BUG_BL.md` (~140 lines from vault's 152 — atomic types, Phase A/B/C, promotion criteria, MCP write discipline).
- **Drift machinery** paralleling kepano: new `vault-sync.json` (14 entries), `scripts/sync-vault.sh` (live-FS read with `mktemp` atomic snapshot, parallel exit-code contract), `docs/syncing-vault.md`. Both `vault-sync` and `kepano-sync` mechanisms remain independent.
- **`organon-frontmatter/SKILL.md`** updated: references list expanded with cascade triggers ("read METHODOLOGY_ADR.md when drafting an ADR or transitioning its `status:`", etc.). Inline `type:` enum corrected from 9 values to 16 (post-FIN-BL-0107 promotion 2026-05-05). Supersession discipline rewritten to permit ADR/FIN-DEC `supersedes:` frontmatter and reference the `[!warning] Superseded` callout. `amends:` / `amended-by:` flagged as deprecated (SD-ADR-011).
- **New skill `organon-memory-audit`** (PR #7) — three-pole drift audit aligning plugin/skill/tool reality, canonical-snippets vault note, and per-surface implementations. Surface-aware (Code / Cowork / Chat), two scope modes, two interaction modes, edits never auto-applied. Invoked via `/organon-memory-audit`. Adds a third user-only skill alongside `kepano-resync` and `plugin-release`.
- **Hook hardening** (PRs #6, #8, post-Codex review):
  - `scripts/sync-vault.sh` and `scripts/sync-kepano.sh` — fixed `sha256sum`/`shasum` fallback that was unreachable on macOS without coreutils (`require_tool` exit-2 short-circuit before the fallback).
  - `scripts/hooks/block-absorbed-edits.sh` — extended to also scan `vault-sync.json` (previously only blocked kepano-absorbed files; vault-absorbed `REGISTRE_KEYS.md` / `PREFIXES.md` / `VOCABULARIES.md` were unprotected). Added leading-`./` path canonicalization (also fixed pre-existing kepano blind spot).
  - `scripts/hooks/validate-sync-json.sh` — fixed `if ! cmd; rc=$?` pattern that always read `$?` as the negation's exit code (always 0); informational drift exit 1 from `sync-kepano.sh` no longer falsely escalates to a validation block.
  - `organon-memory-audit/SKILL.md` — surface-detection probe and `PLUGIN_ROOT` default switched from hard-coded `/Users/pierreandre/...` to `~` / `$HOME` (portable to remote Code agents and other macOS users). Integrity gate dropped `--no-fetch` (stale cache was defeating the gate) and rewrote the gate to distinguish drift (`rc=1` → recommends re-sync) from gate-unavailable (`rc≥2` → separate report-header note, doesn't block pole-3 reads).
- Fixes the silent drift between plugin VOCABULARIES.md and vault registre that had accumulated since v0.4.0 (plugin had 9 `type:` values, vault had 16).
- Breaking: no — additive. Existing skills unchanged in behavior; new references load on-demand.

## Installation

Click "Install plugin" when this `.plugin` file appears in Cowork chat. The 7 description-triggered skills load automatically when working with the Organon vault; the 3 user-only skills (`/kepano-resync`, `/plugin-release`, `/organon-memory-audit`) are invoked explicitly via slash command.

## Author

Pierre-André Folot · 2026-04-29 · Phase 5 wave 1 chat 1.B of the Claude × Organon refactor.
