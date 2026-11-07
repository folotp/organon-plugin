---
name: organon-canvas
description: Use when creating or editing a JSON Canvas (`.canvas`) file in the Organon vault (path contains `Organon`). Cartography of existing vault notes (sketches go to Excalidraw instead). File-node `file:` paths resolve via Obsidian's filename-based wiki resolution. Language-by-folder applies to labels and group titles.
license: MIT
compatibility: Requires the Organon MCP connector.
allowed-tools: Agent
---

# organon-canvas

Subagents available → dispatch as below as your first action, and don't read the runbook yourself. This keeps the Canvas spec off the main context.

No subagents, or dispatch fails → follow `references/AUTHOR_RUNBOOK.md` end-to-end, loading `references/CANVAS_SPEC.md` + `references/EXAMPLES.md` + `references/LABEL_TRANSLATIONS.md` before authoring.

## Claude dispatch

```js
Agent({
  description: "Author or edit a .canvas file",
  subagent_type: "organon:canvas-author",
  prompt: "Runbook: <this skill's directory>/references/AUTHOR_RUNBOOK.md. <task: what to map/restructure>, target folder: <Organon path>, source notes: <wikilinks or filenames to cartograph>"
})
```

Forward user constraints verbatim.
