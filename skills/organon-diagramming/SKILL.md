---
name: organon-diagramming
description: Use when producing a Mermaid, Excalidraw, JSON Canvas, or SVG diagram for an Organon vault note (path contains `Organon`). Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways). Excalidraw is chat-render-only; the bridge persists to the vault. Plugin invariant: compression OFF.
---

# organon-diagramming

Canonical authority: `[[Diagramming conventions]]`. JSON Canvas spec: `organon-canvas` (bundles `references/CANVAS_SPEC.md`). Edge cases → `get_vault_file('99 - Méta/AI/Diagramming conventions.md')`.

## Tool-selection decision tree

First match wins:

1. **Vault notes as first-class nodes** (zettel map, MOC, project map)? → **JSON Canvas** beside the domain. See `organon-canvas`.
2. **Structured flow / sequence / state machine, inline in a note?** → **Mermaid** fenced block. Lazy-load `references/MERMAID_SYNTAX.md` when authoring.
3. **Freeform sketch or whiteboard-style visual?** → **Excalidraw** via connector + bridge (see below). Lazy-load `references/EXCALIDRAW_SKELETON.md` when persisting.
4. **One-shot chat illustration, not for vault?** → **SVG/HTML artifact**. Don't promote unless asked.

## Excalidraw — connector renders in chat, bridge persists

`create_view` is in-chat only; does not write `.excalidraw.md` files. Workflow: (1) `create_view` → PA validates → (2) bridge-persist after approval. Load `references/EXCALIDRAW_SKELETON.md`, wrap elements, `create_vault_file` to `99 - Méta/Media/Excalidraw/<name>.excalidraw.md`.

## Compression OFF invariant

Excalidraw plugin setting **"Compress Excalidraw JSON in Markdown" = OFF** (cf. `[[Diagramming conventions]]` §Plugin settings). Compressed JSON is base64'd, unreadable by MCP — breaks the bridge. Do not suggest re-enabling.

## File placement

| Tool | Location | Filename |
|---|---|---|
| Mermaid | inline in host note | n/a |
| JSON Canvas | beside the domain (or `99 - Méta/`) | `Carte — <domaine>.canvas` |
| Excalidraw | `99 - Méta/Media/Excalidraw/` | `<name>.excalidraw.md` |

Embedding: Mermaid is the codeblock. Canvas: `![[Carte.canvas]]`. Excalidraw: `![[Drawing.excalidraw]]` (sized: `![[Drawing.excalidraw|400]]`).
