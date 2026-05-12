---
name: organon-memory-audit
description: Three-pole drift audit over Organon-related memory and instruction stores. User-only (`/organon-memory-audit`). Surface-aware (Code/Cowork/Chat). Flags: `--scope=global|project|all`, `--mode=interactive|report-only`. Edits never auto-applied — drifts and staleness raised for human triage.
disable-model-invocation: true
allowed-tools:
  - Agent
---

# organon-memory-audit

**BLOCKING REQUIREMENT: This skill MUST dispatch `memory-audit-executor` as its first and only action. The main session MUST NOT execute the audit runbook inline. The full runbook lives in `.claude/agents/memory-audit-executor.md`.**

## How to dispatch

```
Agent({
  description: "Audit organon memory",
  subagent_type: "memory-audit-executor",
  prompt: "<forward args: repo root absolute path>"
})
```

## Args to forward

- **Repo root absolute path** — the absolute path to the organon-plugin repo on the current filesystem (e.g. `/Users/pierreandre/Developer/organon-plugin`). Required for all filesystem-dependent operations (pole 1 reads, integrity gate scripts, drift ledger paths).
- **Per-pole scope flag** — if the user passed `--scope=global`, `--scope=project[=<slug>]`, or `--scope=all`, forward it verbatim. If absent, the executor defaults to `--scope=global`.
- **Interaction mode flag** — if the user passed `--mode=interactive` or `--mode=report-only`, forward it verbatim. Executor defaults to `--mode=interactive`.
- **Surface override** — if the user passed `--surface=code|cowork|chat`, forward it. Executor will skip surface-detection probes and use the specified branch.

## When NOT to delegate

There are no edge cases that justify inline execution. This skill is read-only and the executor is sonnet-pinned; the full audit runbook (surface detection, three-pole reads, integrity gate, four-bucket triage, interactive walk) is maintained exclusively in the executor agent file.

The only legitimate reason not to delegate is if `memory-audit-executor` itself is unavailable (e.g. the agent file is missing or broken). In that case, fix the executor — do not work around it by running the runbook inline.

## Runbook location

The full audit runbook is in `.claude/agents/memory-audit-executor.md`.
