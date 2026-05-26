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

- **Repo root absolute path** — absolute path to organon-plugin repo (e.g. `/Users/pierreandre/Developer/organon-plugin`). Required for pole 1 reads, integrity gate scripts, drift ledger paths.
- **Per-pole scope flag** — forward `--scope=global`, `--scope=project[=<slug>]`, or `--scope=all` verbatim. Default: `--scope=global`.
- **Interaction mode flag** — forward `--mode=interactive` or `--mode=report-only` verbatim. Default: `--mode=interactive`.
- **Surface override** — forward `--surface=code|cowork|chat` if passed; executor skips surface-detection probes.

## When NOT to delegate

No edge case justifies inline execution. Skill is read-only; executor is sonnet-pinned; full runbook (surface detection, three-pole reads, integrity gate, four-bucket triage, interactive walk) lives exclusively in the executor agent file.

Only skip delegation if `memory-audit-executor` is unavailable (missing or broken agent file). Fix the executor — do not run the runbook inline.

## Runbook location

`.claude/agents/memory-audit-executor.md`.
