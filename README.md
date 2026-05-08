# organon

Organon vault conventions for Claude — packaged as a Cowork/Claude Code plugin.

## What this plugin provides

Seven description-triggered skills that load automatically when working with the Organon Obsidian vault (`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`):

### Core (4 skills, validated in chat 1.A)

- **organon-vault-write** — MCP write discipline via `mcp-tools-istefox` 0.4.5+. Covers Voie B routing (two-step / one-step `execute_template`), YAML scalar quoting, frontmatter array vs scalar semantics, `tags:` array shape, heading patch safety, NFC normalization, footguns.
- **organon-frontmatter** — Schema, key ordering, controlled vocabularies, ULID forward-only, `creator:` dual-mode (UI vs MCP), archive/supersession, alias-only versioning, ADR/BL/BUG/INC field requirements. Vocabularies externalized to `references/VOCABULARIES.md` (loaded on-demand).
- **organon-markdown-style** — Body conventions: no H1 in body, language by folder (`99 - Méta/AI/` in EN, rest in FR), typographic apostrophes, no trailing whitespace, no systematic block anchors, table+block-ref pitfall.
- **organon-session-discipline** — 7 behavioral rules: arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder.

### Aux (3 skills, new in v0.2.0 — chat 1.B)

- **organon-bases** — Bases-default policy (Dataview is fallback only with explicit auth, even against directive prompts), Excluded-files trap diagnostic, dv-light optimised config, Organon vocabulary filters.
- **organon-canvas** — Purpose discriminator (cartography of existing notes vs. freeform sketches), placement beside the domain, file-node filename-only paths for vault-move robustness, language by folder for labels, ID convention (kepano 16-char hex).
- **organon-diagramming** — Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for note-cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways), Excalidraw bridge skeleton, plugin compression-OFF invariant, preview-before-persist pattern.

## Absorbed kepano content (since v0.4.0)

This plugin used to **cascade at runtime** to the upstream [kepano `obsidian-skills`](https://github.com/kepano/obsidian-skills) plugin for generic Obsidian syntax. Since v0.4.0 it **absorbs** the relevant kepano content verbatim into per-skill `references/` files (with HTML provenance markers and a `body_sha256` fingerprint tracked in `kepano-sync.json`). Net effect: when an `organon-*` skill triggers, the kepano cascade no longer needs to load — content lives locally and is read on-demand thanks to progressive disclosure (lean SKILL.md ≤ 1 200 words, bundled refs loaded only when the task requires them).

Drift detection: `./scripts/sync-kepano.sh` compares stored `body_sha256` snapshots against current upstream HEAD and reports per-section status. Re-sync workflow: see [`docs/syncing-kepano.md`](docs/syncing-kepano.md). The script never auto-edits files or commits — review obligatory.

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
- `organon-vault-write` — documents 0.4.0 frontmatter array semantics (`replace`-with-scalar on array fields now errors; `append`/`prepend` JSON-decode + auto-wrap), notes 0.4.5 auto-mkdirp on `create_vault_file`/`append_to_vault_file`/`execute_template`, refreshes heading-patch safety version refs (0.4.2 #80 H2-root, 0.4.2 #81 table-cell, 0.4.3 #84 fenced-code).
- `organon-markdown-style` — VLT-BUG-015 reframed: table+block-ref + fenced-code-boundary cases are now structural fail-loud rejects (not HTTP 400 footguns), workaround language updated.
- `organon-session-discipline` — rule #2 cache-example refreshed `v0.3.12` → `v0.4.5` to match the new floor.
- Breaking: yes (version pin bumped).

## Installation

Click "Install plugin" when this `.plugin` file appears in Cowork chat. The 7 skills become available description-triggered.

## Author

Pierre-André Folot · 2026-04-29 · Phase 5 wave 1 chat 1.B of the Claude × Organon refactor.
