---
name: organon-diagramming
description: Apply when producing a Mermaid, Excalidraw, JSON Canvas, or one-shot SVG diagram attached to or destined for an Organon Obsidian vault note (path contains "iCloud~md~obsidian/Documents/Organon"). Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for cartography of existing notes, Excalidraw for freeform sketches via the connector+bridge, SVG for throwaways), Excalidraw connector caveat (chat-render-only — needs the bridge to land in the vault), plugin settings invariant (compression OFF), filename and folder conventions. Use this skill EVERY TIME a diagram is being produced for or attached to this vault — picking the wrong tool stays as friction in the vault forever, and saving connector output without the bridge silently strips it from the vault.
---

# organon-diagramming

No kepano cascade — there is no equivalent kepano skill for diagram tool-selection. The canonical authority is `[[Diagramming conventions]]` in the vault ; this skill encodes its actionable rules. For JSON Canvas spec details, cascade to `json-canvas` (kepano). For Mermaid syntax inside a markdown body, cascade to `obsidian-markdown` (kepano). Edge cases → `get_vault_file('99 - Méta/AI/Diagramming conventions.md')`.

## Tool-selection decision tree

Apply in order — first match wins :

1. **Does the diagram need to reference *existing vault notes* as first-class nodes (zettel map, MOC, project map)?** → **JSON Canvas** (`.canvas` file beside the domain). See `organon-canvas`.
2. **Is it a process / flow / sequence / decision tree / state machine / org chart that fits naturally in code and lives inline in a note?** → **Mermaid** (fenced ` ```mermaid ` block in the host markdown note). Versionable as text, re-renders automatically. Prefer Mermaid over Excalidraw whenever the diagram is structured enough to be code.
3. **Is it a freeform sketch, whiteboard-style visual, or hand-drawn-style diagram?** → **Excalidraw** via the connector (`create_view`), then **the bridge** to persist (see below). Without the bridge, the diagram only renders in chat — it does not land in the vault.
4. **Is it a one-shot illustration for the conversation only, not destined for the vault?** → **SVG / HTML artifact** in chat. Don't promote to the vault unless PA asks.

> **Bad** : drafting an Excalidraw drawing for a 4-step linear workflow — Mermaid would be cheaper to version and edit.
> **Bad** : creating a JSON Canvas with text nodes describing concepts that are *not yet vault notes* — should be Excalidraw or Mermaid.
> **Good** : a fenced Mermaid sequence diagram inside a `VLT-INC-NNNN.md` postmortem ; a `.canvas` mapping `[[VLT-BUG-014]]` ↔ `[[VLT-BUG-018]]` causal links ; an Excalidraw whiteboard sketch promoted via the bridge to `99 - Méta/Media/Excalidraw/`.

## Excalidraw — the connector renders in chat, the bridge persists

The Claude-side Excalidraw connector (`create_view`) is **in-chat rendering only**. It produces JSON elements that animate into the conversation. **It does not write `.excalidraw.md` files in the vault.**

**Use the chat render as a preview before persisting.** When PA asks for an Excalidraw drawing destined for the vault, the natural workflow is : (1) call `create_view` so PA sees the rendered diagram in chat, (2) wait for validation (« looks good » / « adjust X »), (3) only then run the bridge to persist. Iterating in chat is cheap ; rewriting a `.excalidraw.md` after the fact is more expensive than re-rendering. Mention the preview step explicitly when surfacing the work, so PA knows they can ask for changes before the file lands in the vault.

If the user wants a connector-generated drawing saved into Organon, perform the two-step bridge :

1. Call `create_view` with the `elements` array (in-chat render — also serves as the preview).
2. After PA validates the preview, wrap the elements in the Excalidraw plugin's `.excalidraw.md` file structure and save via `create_vault_file` to `99 - Méta/Media/Excalidraw/<name>.excalidraw.md`.

**Skeleton** (reproduce verbatim — the plugin parses these literal markers) :

````markdown
---
excalidraw-plugin: parsed
tags: [excalidraw]
---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠==

## Drawing
```json
{"type":"excalidraw","version":2,"source":"https://github.com/zsviczian/obsidian-excalidraw-plugin","elements":[ /* from create_view */ ],"appState":{"gridSize":null,"viewBackgroundColor":"#ffffff"},"files":{}}
```
%%
````

**Strip before saving** : any `cameraUpdate`, `delete`, or `restoreCheckpoint` pseudo-elements from `create_view` output. They are rendering directives for the connector, not real Excalidraw elements — leaving them in breaks the plugin's parser.

**Preserve verbatim** : the `excalidraw-plugin: parsed` frontmatter key, the warning sentence, the `## Drawing` heading, the closing `%%` markdown comment. The plugin matches these literally.

## Plugin settings invariant — compression OFF

The Obsidian Excalidraw plugin in this vault is configured with **« Compress Excalidraw JSON in Markdown » = OFF** (cf. `[[Diagramming conventions]]` §Plugin settings). Pourquoi : compressed JSON is base64'd and unreadable / un-diffable by MCP, breaking the bridge entirely. **Don't suggest re-enabling compression** — it kills MCP read/write. Other invariants : Excalidraw folder = `99 - Méta/Media/Excalidraw`, `.excalidraw.md` extension ON, default font Virgil, Linter compatibility OFF (plugin author recommends not linting drawings).

## Mermaid in Organon notes

Embed in the host markdown note with a fenced ` ```mermaid ` block. The host note follows Organon body conventions (no H1, language by folder, etc. — see `organon-markdown-style`). No special placement — the diagram lives where the prose lives.

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
