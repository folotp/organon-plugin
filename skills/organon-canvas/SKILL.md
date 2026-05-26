---
name: organon-canvas
description: Use when editing a JSON Canvas (`.canvas`) file in the Organon vault (path contains `Organon`). Cartography of existing vault notes (sketches go to Excalidraw instead). File-node `file:` paths resolve via Obsidian's filename-based wiki resolution. Language-by-folder applies to labels and group titles.
allowed-tools:
  - Agent
---

# organon-canvas

> **BLOCKING REQUIREMENT — DO NOT PROCEED INLINE**
>
> The first and only action this skill takes is to dispatch the `canvas-author` sub-agent. The main session MUST NOT execute the `.canvas` authoring runbook inline. All purpose-discriminator logic, file-node path conventions, language-by-folder enforcement, ID generation, and MCP write safety live in `.claude/agents/canvas-author.md`. This skill is a routing shim — its entire job is to hand off to that agent on sonnet.

## How to dispatch

```js
Agent({
  description: "Author or edit a .canvas file",
  subagent_type: "canvas-author",
  prompt: "<task: what to map/restructure>, target folder: <Organon path>, source notes: <wikilinks or filenames to cartograph>"
})
```

Forward user constraints verbatim (node notes, edge semantics, embed plans). Sub-agent owns the full runbook and lazy-loads `references/CANVAS_SPEC.md` + `references/EXAMPLES.md` + `references/LABEL_TRANSLATIONS.md` — sonnet keeps kepano-absorbed spec off main opus context.

## Runbook location

`.claude/agents/canvas-author.md` (co-located at `skills/organon-canvas/canvas-author.md`).
