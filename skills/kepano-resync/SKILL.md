---
name: kepano-resync
description: Resolve drift detected by `scripts/sync-kepano.sh` against the upstream kepano `obsidian-skills` repo. Run when the script exits 1 (drift) — regenerate `body_sha256`, update the absorbed file under `skills/*/references/` between its `<!-- KEPANO-BEGIN -->`/`<!-- KEPANO-END -->` markers, bump `synced_at_sha`/`synced_at_date` in `kepano-sync.json`, and stage the bundled commit. User-only — has side effects on absorbed content and the sync ledger. Skipping the marker update or bumping `synced_at_sha` without recomputing `body_sha256` is the recurring failure mode this skill prevents.
disable-model-invocation: true
allowed-tools:
  - Agent
---

# kepano-resync

**BLOCKING REQUIREMENT: this skill MUST dispatch the `kepano-resync-orchestrator` sub-agent as its first and only action. The main session MUST NOT execute the re-sync runbook inline. All runbook logic lives in `.claude/agents/kepano-resync-orchestrator.md` and runs inside the sub-agent.**

## How to dispatch

```
Agent({
  description: "Resolve kepano drift",
  subagent_type: "kepano-resync-orchestrator",
  prompt: "<forward args: repo root, any specific section to resolve, or 'all' for full sweep>"
})
```

## Args to forward

- **Repo root absolute path** — pass the absolute path to the repository root (e.g. `/home/user/organon-plugin`).
- **Optional scoped section** — if the user specifies a single drifted section, forward `kepano_section_path` (rel path of the `kepano-sync.json` entry's `source_file`) and `kepano_section_heading` to limit the sweep to one section.
- **`--no-fetch` flag** — pass if the user is offline or explicitly requests operating on the cached upstream clone without a live fetch.

## When NOT to delegate

If the user wants to **intentionally de-absorb** a section — permanently removing the upstream coupling rather than re-syncing — that is not a re-sync flow. It requires editing `kepano-sync.json` directly first (deleting or nullifying the entry) before any content edit. The PreToolUse hook will still block the file edit until the ledger entry is gone. See CLAUDE.md §"Intentional de-absorption" for guidance.

Do not invoke this skill for `upstream-file-missing` status where PA escalation is needed; surface that case to the user directly.

## Runbook location

The full operational runbook is at `.claude/agents/kepano-resync-orchestrator.md` — all step-by-step logic, hash recomputation commands, token lifecycle, anti-patterns, and commit template references live there.
