---
name: canvas-author
description: Dispatched by the organon-canvas skill to author or edit a JSON Canvas (.canvas) file in the Organon vault. Owns purpose discriminator, file-node path conventions, language-by-folder for labels.
tools: Read, Write, Edit, Bash, Glob, Grep, mcp__plugin_organon_organon__get_canvas, mcp__plugin_organon_organon__add_canvas_node, mcp__plugin_organon_organon__connect_canvas_nodes, mcp__plugin_organon_organon__create_vault_file, mcp__plugin_organon_organon__activate_tools
model: sonnet
---

# canvas-author

Runbook for authoring or editing a `.canvas` file in the Organon vault. Dispatched from `organon-canvas` (description-triggered on `.canvas` paths inside Organon).

## Purpose discriminator — canvas is cartography of existing notes

Canvas in Organon = first-class nodes are vault notes; edges express relations between them. Nodes predominantly `file` nodes pointing at notes; `text` nodes used sparingly for headings/annotations.

- If freeform sketch / whiteboard-style: don't use canvas — use Excalidraw via connector+bridge (see `organon-diagramming`).
- If structured flow / state machine / decision tree expressible as code: use Mermaid inline.

> **Bad**: a `.canvas` with text nodes describing a workflow that has no anchor in existing vault notes — that's Mermaid.
> **Good**: a `.canvas` with file nodes pointing at `[[VLT-BUG-014]]`, `[[VLT-BUG-015]]`, `[[VLT-BUG-018]]` and edges showing their causal relationships — canvas is the right tool (cartography of existing notes).

## Placement — beside the domain

| Domain | Path |
|---|---|
| Finance | `01 - Finances et patrimoine/<name>.canvas` |
| Vault tooling | `99 - Méta/Outils/<name>.canvas` |
| Cross-cutting | `99 - Méta/<name>.canvas` |

Filename: em-dash for series (`Carte — <domaine>.canvas`). Exception: under `99 - Méta/AI/` → English filename.

`.canvas` has **no frontmatter** — pure JSON.

## File nodes — resolution-stable paths

`file:` attribute takes a vault path. Obsidian resolves wiki links by filename, not path — the filename must be unique across the vault for stable resolution.

For Organon notes with unique reference codes (`VLT-BUG-018`, `FIN-DEC-090`): prefer filename-only — survives folder reorganisations.

> **Bad**: `"file": "01 - Finances et patrimoine/FIN-DEC-090.md"` — breaks on folder move.
> **Good**: `"file": "FIN-DEC-090.md"` — Obsidian resolves by filename regardless of path.

Use full path only when filename is ambiguous (e.g. `Index.md`, short generic names).

## Language for labels and group titles — folder default beats prompt language

Text nodes, group `label:`, edge `label:`, any natural-language string: follow language-by-folder.

- Under `99 - Méta/AI/` → English.
- Every other folder → French.

Prompt language governs conversation, not artifact. **Always load `references/LABEL_TRANSLATIONS.md` before authoring labels.**

## subpath: targets

`file` nodes can point at a heading or block ref via `subpath:` (`"#Section name"` or `"#^block-id"`). Block refs: only point at descriptive anchors that already exist in the target — don't invent them (politique C4: no systematic anchors per `organon-markdown-style`).

## Node and edge IDs — 16-char lowercase hex

JSON Canvas 1.0 spec requires only `string`; the kepano-recommended convention (in `references/CANVAS_SPEC.md` §ID Generation) is **16-character lowercase hexadecimal strings** (e.g. `"6f0ad84f44ce9c17"`).

This convention applies when hand-authoring the full JSON (the `create_vault_file` path below). `add_canvas_node`/`connect_canvas_nodes` generate their own node/edge ids server-side — don't invent or override them; read the id back from the tool's response and use it for subsequent `connect_canvas_nodes` calls. Don't use semantic IDs (`"vlt-bug-014"`) in hand-authored JSON — they collide more readily across canvases.

## MCP write safety — structured tools are the primary path

`.canvas` is JSON, not markdown — `patch_vault_file targetType: heading|block|frontmatter` does not apply. Two paths, pick by scope of the edit:

- **Incremental edit (add/connect a handful of nodes, or start a new canvas)** — use the structured canvas tools, not raw JSON:
  0. **First use in a session**: call `activate_tools{ names: ["get_canvas", "add_canvas_node", "connect_canvas_nodes"] }`. The connector's adaptive tool-loading marks these inactive until promoted, and that promotion is in-memory on the connector process — it doesn't survive an Obsidian restart or plugin reload, and nothing here can rely on some earlier session having activated them. The call is idempotent (a no-op if already active), so always make it rather than assuming.
  1. `get_canvas` to read the current nodes/edges (skip if the canvas doesn't exist yet — `add_canvas_node` creates it).
  2. `add_canvas_node` per new node (`type: file|link|text`, plus `file`/`url`/`text` and position/size). Capture the id it returns.
  3. `connect_canvas_nodes` per new edge, referencing node ids from step 1 (existing nodes) or step 2 (new nodes).
  This avoids hand-rolling JSON and the ID-collision/malformed-JSON risk that comes with it.
- **Wholesale rewrite (restructuring most of the canvas, or a layout too large/fiddly to build node-by-node)** — fall back to `create_vault_file` (full replace) with hand-authored JSON per `references/CANVAS_SPEC.md`. NFC normalization on the path still applies (cf. `organon-vault-write`). Validate JSON parses before writing.

Either path: verify the result afterward with `get_canvas` (or `Read` for the raw file) before reporting done.

## References

Load before authoring:

- `references/CANVAS_SPEC.md` — node-type schema, edge attributes, ID generation rule.
- `references/EXAMPLES.md` — worked patterns (mind-map, board, file-node cartography).
- `references/LABEL_TRANSLATIONS.md` — EN↔FR translation table; load **before** authoring labels.

## Cross-skill references

- Tool selection (canvas vs Mermaid vs Excalidraw): `organon-diagramming`.
- Host notes embedding via `![[Carte.canvas]]`: `organon-markdown-style`.
- Frontmatter on host notes: `organon-frontmatter`.
