# organon

Organon vault conventions for Claude — packaged as a Cowork/Claude Code plugin.

## What this plugin provides

Seven description-triggered skills that load automatically when working with the Organon Obsidian vault (`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`):

### Core (4 skills, validated in chat 1.A)

- **organon-vault-write** — MCP write discipline via `mcp-tools-istefox` 0.3.12+. Covers Voie B routing (two-step / one-step `execute_template`), YAML scalar quoting, `tags:` array shape, heading patch safety, NFC normalization, footguns.
- **organon-frontmatter** — Schema, key ordering, controlled vocabularies, ULID forward-only, `creator:` dual-mode (UI vs MCP), archive/supersession, alias-only versioning, ADR/BL/BUG/INC field requirements. Vocabularies externalized to `references/VOCABULARIES.md` (loaded on-demand).
- **organon-markdown-style** — Body conventions: no H1 in body, language by folder (`99 - Méta/AI/` in EN, rest in FR), typographic apostrophes, no trailing whitespace, no systematic block anchors, table+block-ref pitfall.
- **organon-session-discipline** — 7 behavioral rules: arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder.

### Aux (3 skills, new in v0.2.0 — chat 1.B)

- **organon-bases** — Bases-default policy (Dataview is fallback only with explicit auth, even against directive prompts), Excluded-files trap diagnostic, dv-light optimised config, Organon vocabulary filters.
- **organon-canvas** — Purpose discriminator (cartography of existing notes vs. freeform sketches), placement beside the domain, file-node filename-only paths for vault-move robustness, language by folder for labels, ID convention (kepano 16-char hex via cascade).
- **organon-diagramming** — Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for note-cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways), Excalidraw bridge skeleton, plugin compression-OFF invariant, preview-before-persist pattern.

## Cascade with kepano/obsidian-skills

Each Organon skill cascades to the [kepano `obsidian-skills` plugin](https://github.com/kepano/obsidian-skills) (already installed via Claude Desktop) for generic Obsidian syntax. Organon-specific deltas only — single source of truth, no duplication.

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

## Installation

Click "Install plugin" when this `.plugin` file appears in Cowork chat. The 7 skills become available description-triggered.

## Author

Pierre-André Folot · 2026-04-29 · Phase 5 wave 1 chat 1.B of the Claude × Organon refactor.
