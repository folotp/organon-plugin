---
name: organon-bases
description: Use when creating or editing a `.base` (Obsidian Bases) view filtering or summarising Organon vault notes (path contains `Organon`). Bases is the default; Dataview only with explicit user authorization. Covers the Excluded-files trap and canonical filters on Organon vocabularies (`type:`, `status:`, `tags`, folder roots). Full grammar in `references/BASES_SYNTAX.md`.
license: MIT
compatibility: Requires the Organon MCP connector.
allowed-tools: Agent
---

# organon-bases

Subagents available → dispatch as below as your first action, and don't read the runbook yourself. This keeps the Bases grammar off the main context.

No subagents, or dispatch fails → follow `references/AUTHOR_RUNBOOK.md` end-to-end, loading `references/BASES_SYNTAX.md` + `references/FUNCTIONS_REFERENCE.md` before authoring.

## Claude dispatch

```js
Agent({
  description: "Author or edit a .base view",
  subagent_type: "organon:bases-author",
  prompt: "Runbook: <this skill's directory>/references/AUTHOR_RUNBOOK.md. <task: what to build/change>, vault context: <relevant folders or note types>, output path: <absolute path or domain folder>"
})
```

Forward user constraints verbatim.
