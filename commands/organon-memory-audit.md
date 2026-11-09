---
description: Three-pole drift audit (plugin reality + canonical vault note + per-surface implementations) and instruction-quality checks over Organon-related memory and instruction stores. Surface-aware. Manual or scheduled.
disable-model-invocation: true
allowed-tools: Agent AskUserQuestion Skill
---

Claude surfaces only. Dispatch `memory-audit-executor`, then walk its findings. Full runbook (surface detection, three-pole reads, integrity gate, triage, quality checks) lives in executor, off main session's context.

## How to dispatch

```
Agent({
  description: "Audit organon memory",
  subagent_type: "organon:memory-audit-executor",
  prompt: "<forward args: repo root absolute path>"
})
```

## Args to forward

- **Organon tool prefix** — the prefix the main session sees (`mcp__claude_ai_organon__` or `mcp__organon__`), or `none`. Executor fails loud if it sees none.
- **Repo root absolute path** — absolute path to organon-plugin repo (e.g. `/Users/pierreandre/Developer/organon-plugin`). Required for pole 1 reads, integrity gate script.
- **Per-pole scope flag** — forward `--scope=global`, `--scope=project[=<slug>]`, or `--scope=all` verbatim. Default: `--scope=global`.
- **Interaction mode flag** — forward `--mode=interactive` or `--mode=report-only` verbatim. Default: `--mode=interactive`.
- **Checks flag** — forward `--checks=drift`, `--checks=quality`, or `--checks=all` verbatim. Default: `--checks=drift`. Catalogue: `docs/memory-audit/references/QUALITY_CHECKS.md`.
- **Surface override** — forward `--surface=code|thread|app` if passed (legacy `cowork`/`chat` → `app`); executor skips surface-detection probes.

## When NOT to delegate

No edge case justifies inline audit. Executor is read-only and runs on Opus (unversioned alias, tracks latest); runbook lives exclusively in its agent file. Walk below stays here: subagent can't prompt or write.

Executor unavailable (missing/broken agent file) → stop and fix it; no inline run — runbook stays off main context.

## Walk (`--mode=interactive`, after executor returns)

Show report verbatim first. `--mode=report-only` → stop there.

Per finding, one at a time, never bulk. Show target, current, proposed, `Why:`/`reasoning`.

| Bucket | Choices |
|---|---|
| 1, 2, 4 | `apply / skip / defer` |
| 3 | Recommendation only, nothing to apply |
| 5 | `apply-now / edit-first / decline` |

Before apply: re-read target, confirm current text still present. Moved → report it, re-propose.

| Target | Write path |
|---|---|
| Vault note | Load `organon-vault-write` first; Organon MCP tools only (`mcp__claude_ai_organon__*` on Code/Desktop, `mcp__organon__*` in claude.ai cloud), never raw file ops — keeps atomic frontmatter, link-safe patch and rename |
| `organon-*` skill | `Edit` in repo, on feature branch; on `main` → refuse, offer branch. Never commit from walk — change ships through normal PR flow |
| No organon-plugin git checkout, skill target | Recommendation only — fixes ship via the repo; never edit the installed plugin copy. Findings still come from the installed plugin root |
| `~/.claude/CLAUDE.md`, project `CLAUDE.md`, memory files | `Edit` |
| Settings → General, project instructions, M365 per-app | Corrected text in code block for PA to paste; never claim written |
| kepano-pinned file (`upstream-pinned`) | Not offered; route to `docs/refreshing-kepano.md` |

`AI Bootstrap.md`, `Vault Conventions.md`, any `organon-*` SKILL.md: per-item PA confirmation always, no exceptions — these steer every session.

## Runbook location

`agents/memory-audit-executor.md`.
