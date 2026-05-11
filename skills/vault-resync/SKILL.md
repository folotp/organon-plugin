---
name: vault-resync
description: Resolve drift detected by `scripts/sync-vault.sh` against the live Organon vault (`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`). Run when the script exits 1 (drift) — re-extract the absorbed vault body, replace it inside the `<!-- VAULT-BEGIN -->` / `<!-- VAULT-END -->` markers in the plugin target file, recompute `body_sha256`, bump `synced_at_date` in `vault-sync.json`, and stage the bundled commit. User-only — has side effects on absorbed content and the sync ledger. Skipping the marker update or bumping `synced_at_date` without recomputing `body_sha256` is the recurring failure mode this skill prevents. Vault-side parallel to `kepano-resync` (same Option D markers, same hash-recompute discipline) — but the vault detector hashes only the live vault file, not the plugin target, which makes direct edits to plugin targets *silently invisible* to drift detection. The PreToolUse hook is the primary protection there; this skill is the legitimate update path.
disable-model-invocation: true
allowed-tools:
  - Agent
---

# vault-resync

**BLOCKING REQUIREMENT**: This skill MUST dispatch the `vault-resync-orchestrator` sub-agent as its first and only action. The main session MUST NOT execute the re-sync runbook inline. The full runbook lives in `.claude/agents/vault-resync-orchestrator.md`.

## How to dispatch

```javascript
Agent({
  description: "Resolve vault drift",
  subagent_type: "vault-resync-orchestrator",
  prompt: "<forward args: repo root, any specific section, or 'all' for full sweep>"
})
```

## Args to forward

- **Repo root absolute path** — e.g. `/home/user/organon-plugin` (the working directory of the invoking session).
- **Optional drifted `vault_path`** — scope the run to a single entry by passing the `vault_path` value from `vault-sync.json` (omit for a full sweep of all drifted entries).
- **`--scope` flag** — if `scripts/sync-vault.sh` supports a `--scope` argument, forward it verbatim to restrict the detector to a subsystem (e.g. `--scope vocabularies`).

## When NOT to delegate

**Intentional de-absorption** of a vault section is not a re-sync — it is a coupling removal. If PA decides a vault section should no longer be absorbed into the plugin:

1. Edit `vault-sync.json` directly to remove (or annotate) the entry.
2. Then edit the plugin target file as Organon-owned content — no resync token needed once the entry is removed from the ledger.

Do not invoke `vault-resync-orchestrator` for this path. See the CLAUDE.md section "Working with absorbed files" for the full de-absorption guidance.

## Runbook location

The complete step-by-step runbook (detection, per-status resolution paths, token lifecycle, hash-recomputation commands, commit template) lives in `.claude/agents/vault-resync-orchestrator.md`.
