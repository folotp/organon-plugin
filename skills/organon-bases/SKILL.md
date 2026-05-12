---
name: organon-bases
description: Use when editing a `.base` (Obsidian Bases) view filtering or summarising Organon vault notes (path contains `Organon`). Bases is the default; Dataview only with explicit user authorization. Covers the Excluded-files trap and canonical filters on Organon vocabularies (`type:`, `status:`, `tags`, folder roots). Full grammar in `references/BASES_SYNTAX.md`.
allowed-tools:
  - Agent
---

# organon-bases

> **BLOCKING REQUIREMENT — DO NOT PROCEED INLINE**
>
> The first and only action this skill takes is to dispatch the `bases-author` sub-agent. The main session MUST NOT execute the `.base` authoring runbook inline. All tool-choice policy, Excluded-files diagnostic, Organon-vocabulary filters, file placement, and embedding rules live in `.claude/agents/bases-author.md`. This skill is a routing shim — its entire job is to hand off to that agent on sonnet.

## How to dispatch

```js
Agent({
  description: "Author or edit a .base view",
  subagent_type: "bases-author",
  prompt: "<task: what to build/change>, vault context: <relevant folders or note types>, output path: <absolute path or domain folder>"
})
```

Forward verbatim any user constraints (folder, filter shape, summary type). The sub-agent owns the full runbook and the lazy-loads of `references/BASES_SYNTAX.md` + `references/FUNCTIONS_REFERENCE.md` — running it on sonnet keeps the kepano-absorbed grammar off the main opus context.

## Runbook location

`.claude/agents/bases-author.md` (co-located at `skills/organon-bases/bases-author.md`).
