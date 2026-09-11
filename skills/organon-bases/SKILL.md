---
name: organon-bases
description: Use when editing a `.base` (Obsidian Bases) view filtering or summarising Organon vault notes (path contains `Organon`). Bases is the default; Dataview only with explicit user authorization. Covers the Excluded-files trap and canonical filters on Organon vocabularies (`type:`, `status:`, `tags`, folder roots). Full grammar in `references/BASES_SYNTAX.md`.
allowed-tools:
  - Agent
---

# organon-bases

This skill is a routing shim: its only action is to dispatch the `bases-author` sub-agent rather than run the `.base` authoring runbook inline. Tool-choice policy, the Excluded-files diagnostic, vocabulary filters, file placement, and embedding rules all live in `.claude/agents/bases-author.md`, loaded on sonnet — this keeps that kepano-absorbed grammar off the main opus context.

## How to dispatch

```js
Agent({
  description: "Author or edit a .base view",
  subagent_type: "bases-author",
  prompt: "<task: what to build/change>, vault context: <relevant folders or note types>, output path: <absolute path or domain folder>"
})
```

Forward user constraints verbatim (folder, filter shape, summary type). Sub-agent owns the full runbook and lazy-loads `references/BASES_SYNTAX.md` + `references/FUNCTIONS_REFERENCE.md` — sonnet keeps kepano-absorbed grammar off main opus context.

## Runbook location

`.claude/agents/bases-author.md` (co-located at `skills/organon-bases/bases-author.md`).
