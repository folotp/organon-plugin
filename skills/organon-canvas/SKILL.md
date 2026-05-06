---
name: organon-canvas
description: Apply when creating or editing a JSON Canvas (`.canvas`) file in the Organon Obsidian vault (path contains "iCloud~md~obsidian/Documents/Organon"). Organon-specific canvas conventions — purpose discriminator (cartography of *existing* vault notes vs. freeform sketch — sketches go to Excalidraw instead), placement beside the domain the canvas serves, file-node `file:` paths must resolve via Obsidian's filename-based wiki resolution, language by folder for labels and group titles. Use this skill EVERY TIME a `.canvas` file is being authored — picking the wrong tool (canvas when Excalidraw fits, or vice versa) creates artifacts that don't belong in the vault. JSON Canvas 1.0 spec is bundled in `references/CANVAS_SPEC.md` (absorbed from kepano).
---

# organon-canvas

The full JSON Canvas 1.0 spec — node types (`text`, `file`, `link`, `group`), edge attributes, ID generation, layout guidelines, validation — lives in `references/CANVAS_SPEC.md` (verbatim absorption from kepano `obsidian-skills`, cf. `kepano-sync.json` at repo root for sync metadata and `scripts/sync-kepano.sh` for the re-sync workflow). Complete worked examples (mind maps, project boards, research canvases, flowcharts) are in `references/EXAMPLES.md`. This skill covers only the **Organon-specific deltas** : when a `.canvas` is the right artifact, where it lives, and how its content references vault notes coherently. Edge cases → `get_vault_file('99 - Méta/AI/Diagramming conventions.md')`.

## Purpose discriminator — canvas is for cartography of existing notes

A JSON Canvas in Organon serves **one** purpose : **cartographying notes that already exist** as first-class nodes (zettel visuel, MOC structurant, project mapping). Edges express relations between vault notes ; nodes are predominantly `file` nodes pointing at notes, with `text` nodes used sparingly for headings or annotations.

If the artifact is a freeform sketch, whiteboard-style diagram, or hand-drawn-style visual, **don't** use canvas — use Excalidraw via the connector + bridge (see `organon-diagramming`). If the artifact is a structured process flow / sequence / decision tree expressible as code, **don't** use canvas — use Mermaid inline.

> **Bad** : creating a `.canvas` file with text nodes describing a workflow that has no anchor in existing vault notes — should be Mermaid.
> **Good** : a `.canvas` with file nodes pointing at `[[VLT-BUG-014]]`, `[[VLT-BUG-015]]`, `[[VLT-BUG-018]]` and edges showing their causal relationships — canvas is the right tool.

This is the rule from *Diagramming conventions* §Decision heuristic : *« Does the diagram need to reference existing vault notes as first-class nodes? → JSON Canvas. »*

## Placement — beside the domain the canvas serves

A canvas file lives **beside the domain it cartographies**. A finance map → `01 - Finances et patrimoine/<name>.canvas`. A vault-tooling map → `99 - Méta/Outils/<name>.canvas`. Cross-cutting canvases (e.g. mapping the whole AI subsystem or the documentation system) → `99 - Méta/`. Filename in French (em-dash for series titles : `Carte — <domaine>.canvas`), exception : files under `99 - Méta/AI/` use English.

The `.canvas` file has **no frontmatter** — it's pure JSON. It is not an Organon note ; it's an artifact attached to the domain.

## File nodes — paths that survive Obsidian's resolution

`file` node `file:` attribute takes a path within the vault (e.g. `"99 - Méta/Outils/VLT-BUG-018.md"`). Obsidian resolves wiki links by filename, not path, so the file's filename component must be unique across the vault for resolution to be stable.

For Organon notes with reference codes (`VLT-BUG-018`, `FIN-DEC-090`, etc.) : the alias-only convention (cf. `organon-frontmatter`) means `[[VLT-BUG-018]]` resolves regardless of path. In a canvas `file:` attribute, prefer the **filename without folder path** if you're confident the filename is unique (`"VLT-BUG-018.md"`) — Obsidian's resolution will handle it and the canvas remains robust to file moves. Use the full path only when the filename is ambiguous (common note titles like `Index.md` or short generic names).

> **Bad** : `"file": "01 - Finances et patrimoine/FIN-DEC-090.md"` for a note with a unique reference code — breaks if the note ever moves to a sibling folder.
> **Good** : `"file": "FIN-DEC-090.md"` — survives folder reorganisations because Obsidian resolves by filename.

## Language for labels and group titles — folder default beats prompt language

Text nodes, group `label:`, edge `label:`, and any natural-language string inside the `.canvas` JSON follow the **language-by-folder** rule from *Vault Conventions* / `organon-markdown-style` : a canvas under `99 - Méta/AI/` uses English labels ; **every other folder uses French**. The prompt language governs the conversation tone, not the artifact content. A French-folder canvas with English labels is a fail even if the chat was in English.

This is the most-missed rule on canvases — when drafting in an English chat session, the default-English instinct slips into the JSON labels even though the artifact will live in a French folder. Translate every label before writing.

> **Bad** (canvas under `99 - Méta/Outils/Accès à Obsidian par Claude/`, French folder, but English labels in JSON) :
> ```json
> {"text": "Common root cause: YAML schema drift", "label": "causes"}
> ```
>
> **Good** (same folder, French labels) :
> ```json
> {"text": "Cause racine commune : dérive de schéma YAML", "label": "cause"}
> ```

Common label translations to keep ready when drafting :

| English (default instinct) | French (folder default) |
|---|---|
| `cause`, `causes`, `causal link` | `cause`, `lien causal` |
| `root cause` | `cause racine` |
| `related to`, `related` | `relié à`, `connexe` |
| `parent`, `child`, `sibling` | `parent`, `enfant`, `frère` |
| `depends on`, `dependency` | `dépend de`, `dépendance` |
| `supersedes`, `superseded by` | `remplace`, `remplacé par` |
| `leads to`, `triggers` | `mène à`, `déclenche` |
| `blocks`, `blocked by` | `bloque`, `bloqué par` |
| `extends`, `refines` | `étend`, `affine` |
| `Project Overview`, `Summary` | `Vue d'ensemble`, `Synthèse` |

## Embeds and `subpath:`

`file` nodes can target a heading or block ref via `subpath:` (`"#Section name"` or `"#^block-id"`). For Organon notes : remember that block refs are subject to politique C4 (no systematic anchors per `organon-markdown-style`) — only point `subpath:` at headings or at descriptive ad-hoc anchors that already exist in the target note. Don't invent an anchor and rely on it being there.

## Node and edge IDs — the kepano convention, not an Organon rule

JSON Canvas 1.0 spec only requires `id` to be a string ; there is no formal Obsidian standard. The kepano-recommended convention (now absorbed in `references/CANVAS_SPEC.md` §ID Generation) is **16-character lowercase hexadecimal strings** (64-bit random value, e.g. `"6f0ad84f44ce9c17"`). Use `secrets.token_hex(8)` in Python or equivalent to generate.

Don't substitute semantic IDs (`"vlt-bug-014"`, `"root-cause"`) — even though they parse as valid JSON Canvas, they collide more readily across canvases and break the kepano-recommended uniqueness budget. The deterministic readability gain isn't worth the convention drift. If you need a human-readable handle on a node, put it in the node's `text:` (text node) or accompanying `label:` (file/group node), not in the `id:`.

## MCP write safety

A `.canvas` file is JSON, not markdown — `patch_vault_file targetType: heading|block|frontmatter` does not apply. Use `create_vault_file` (full replace) for canvas edits. NFC normalization on the path still applies (cf. `organon-vault-write`). Validate JSON parses before writing.

For diagramming tool selection (canvas vs Mermaid vs Excalidraw vs SVG) → `organon-diagramming`. For host notes that embed a canvas via `![[Carte.canvas]]` → `organon-markdown-style`.
