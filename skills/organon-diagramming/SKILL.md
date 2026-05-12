---
name: organon-diagramming
description: Use when producing a Mermaid, Excalidraw, JSON Canvas, or SVG diagram for an Organon vault note (path contains `Organon`). Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways). Excalidraw is chat-render-only; the bridge persists to the vault. Plugin invariant: compression OFF.
---

# organon-diagramming

The canonical authority is `[[Diagramming conventions]]` in the vault ; this skill encodes its actionable rules. For JSON Canvas spec details, see `organon-canvas` (which bundles the absorbed kepano spec in `references/CANVAS_SPEC.md`). Generic Mermaid syntax (kepano-absorbed) lives in `references/MERMAID_SYNTAX.md` — load only when authoring a Mermaid block. Excalidraw `.excalidraw.md` skeleton lives in `references/EXCALIDRAW_SKELETON.md` — load only when persisting a connector drawing via the bridge. Edge cases → `get_vault_file('99 - Méta/AI/Diagramming conventions.md')`.

> **Optional cost-saving routing**: If the user's request is purely "which diagram tool should I use for X?" — a pure tool-selection question with no further diagramming work — consider dispatching the `diagramming-router` sub-agent on sonnet:
>
> `Agent({ description: "Route diagram tool choice", subagent_type: "diagramming-router", prompt: "<user's question, vault context>" })`
>
> For requests that involve actually authoring the diagram, reviewing existing diagrams, or applying diagramming conventions, continue with this skill inline — that work needs the main model's judgment.
>
> (`diagramming-router` agent: planned but not yet implemented — for now, continue inline.)

## Tool-selection decision tree

Apply in order — first match wins :

1. **Does the diagram need to reference *existing vault notes* as first-class nodes (zettel map, MOC, project map)?** → **JSON Canvas** (`.canvas` file beside the domain). See `organon-canvas`.
2. **Is it a process / flow / sequence / decision tree / state machine / org chart that fits naturally in code and lives inline in a note?** → **Mermaid** (fenced ` ```mermaid ` block in the host note). Versionable as text, re-renders automatically. Prefer Mermaid over Excalidraw whenever the diagram is structured enough to be code. For syntax: `references/MERMAID_SYNTAX.md`.
3. **Is it a freeform sketch, whiteboard-style visual, or hand-drawn-style diagram?** → **Excalidraw** via the connector (`create_view`), then **the bridge** to persist (see below). Without the bridge, the diagram only renders in chat — it does not land in the vault.
4. **Is it a one-shot illustration for the conversation only, not destined for the vault?** → **SVG / HTML artifact** in chat. Don't promote to the vault unless PA asks.

> **Bad** : drafting an Excalidraw drawing for a 4-step linear workflow — Mermaid would be cheaper to version and edit.
> **Bad** : creating a JSON Canvas with text nodes describing concepts that are *not yet vault notes* — should be Excalidraw or Mermaid.
> **Good** : a fenced Mermaid sequence diagram inside a `VLT-INC-NNNN.md` postmortem ; a `.canvas` mapping `[[VLT-BUG-014]]` ↔ `[[VLT-BUG-018]]` causal links ; an Excalidraw whiteboard sketch promoted via the bridge to `99 - Méta/Media/Excalidraw/`.

## Excalidraw — the connector renders in chat, the bridge persists

The Claude-side Excalidraw connector (`create_view`) is **in-chat rendering only**. It produces JSON elements that animate into the conversation. **It does not write `.excalidraw.md` files in the vault.**

**Use the chat render as a preview before persisting.** When PA asks for an Excalidraw drawing destined for the vault: (1) call `create_view` so PA sees the rendered diagram in chat, (2) wait for validation (« looks good » / « adjust X »), (3) only then run the bridge to persist. Iterating in chat is cheap ; rewriting a `.excalidraw.md` after the fact is more expensive than re-rendering. Mention the preview step explicitly when surfacing the work, so PA knows they can ask for changes before the file lands in the vault.

To persist after PA validates: load `references/EXCALIDRAW_SKELETON.md` for the verbatim file structure, wrap the elements, and `create_vault_file` to `99 - Méta/Media/Excalidraw/<name>.excalidraw.md`.

## Plugin settings invariant — compression OFF

The Obsidian Excalidraw plugin in this vault is configured with **« Compress Excalidraw JSON in Markdown » = OFF** (cf. `[[Diagramming conventions]]` §Plugin settings). Pourquoi : compressed JSON is base64'd and unreadable / un-diffable by MCP, breaking the bridge entirely. **Don't suggest re-enabling compression** — it kills MCP read/write. Other invariants : Excalidraw folder = `99 - Méta/Media/Excalidraw`, `.excalidraw.md` extension ON, default font Virgil, Linter compatibility OFF (plugin author recommends not linting drawings).

## File placement and naming

| Tool | Location | Filename |
|---|---|---|
| Mermaid | inline in the host note | n/a |
| JSON Canvas | beside the domain (or `99 - Méta/` cross-cutting) | `Carte — <domaine>.canvas` (FR) ; English under `99 - Méta/AI/` |
| Excalidraw | `99 - Méta/Media/Excalidraw/` (set by plugin) | `<name>.excalidraw.md` ; plugin uses `YYYY-MM-DD HH.mm.s` for default-named drawings |

## Embedding diagrams in notes

- Mermaid : already embedded (it's the codeblock).
- Canvas : `![[Carte.canvas]]` from a host note.
- Excalidraw : `![[Drawing.excalidraw]]` from a host note. Size control via `![[Drawing.excalidraw|400]]`.

For canvas-specific conventions → `organon-canvas`. For Bases views → `organon-bases`. For body prose around embedded diagrams → `organon-markdown-style`.
