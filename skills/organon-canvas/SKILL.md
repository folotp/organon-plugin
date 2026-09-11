---
name: organon-canvas
description: Use when editing a JSON Canvas (`.canvas`) file in the Organon vault (path contains `Organon`). Cartography of existing vault notes (sketches go to Excalidraw instead). File-node `file:` paths resolve via Obsidian's filename-based wiki resolution. Language-by-folder applies to labels and group titles.
allowed-tools:
  - Agent
---

# organon-canvas

This skill is a routing shim: its only action is to dispatch the `canvas-author` sub-agent rather than run the `.canvas` authoring runbook inline. Purpose-discriminator logic, file-node path conventions, language-by-folder enforcement, ID generation, and MCP write safety all live in `.claude/agents/canvas-author.md`, loaded on sonnet — this keeps that kepano-absorbed spec off the main opus context.

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
