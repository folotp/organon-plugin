# organon-plugin — Claude orientation

This is the source repo for the **organon** Claude Code plugin (`folotp/organon-plugin`). Distribution channel: GitHub Release with a `.plugin` asset, consumed by the `folotp/claude-marketplace`.

## Branch policy

- **Never commit directly to `main`.** Required pattern: feature/release branch → PR → merge-commit. `Co-Authored-By` trailers are rejected. Recent merge commits (`612cf86`, `6fc7db1`) are the canonical examples.
- The repo has `allow_merge_commit=true` set explicitly to support the merge-commit pattern.
- Branch naming: `feat/`, `fix/`, `chore/`, `perf/`, `docs/` prefixes by intent.

## Release flow

The `plugin-release` skill (`/plugin-release`, user-invokable) is the runbook. Critical invariants:

- The single source of truth for the version is `.claude-plugin/plugin.json` `version` (semver).
- The `.plugin` archive is **gitignored** (`*.plugin` in `.gitignore`). Distribution is via GitHub Release asset, never committed.
- **Pre-flight gates** (see `release-readiness` subagent for parallel pre-flight, or run sequentially):
  1. Working tree clean on `main` (or release branch).
  2. `./scripts/sync-kepano.sh` exits 0 (no upstream drift).
  3. `plugin-dev:plugin-validator` agent passes.
  4. (Optional, on minor/major) `python3 scripts/token-harness.py` regression check.
- **Tag flow**: push `main` *before* the tag — pushing the tag against an out-of-date remote leaves a dangling reference.
- **`gh release create` flag-combo gotcha**: `--notes-from-tag` is incompatible with `--repo`. Inside the repo, omit `--repo`. Cross-repo, use `--notes` or `--notes-file` instead. Don't combine with `--notes-from-tag`.

## Drift gate — kepano absorption

The plugin absorbs upstream content from `kepano/obsidian-skills` (generic Obsidian syntax). Ledger: `kepano-sync.json`. Detector: `scripts/sync-kepano.sh`. Re-sync runbook: `kepano-resync` skill (`/kepano-resync`).

A **PreToolUse hook** (`scripts/hooks/block-absorbed-edits.sh`) blocks direct `Edit|Write|MultiEdit` on any file registered as a `target_file` in `kepano-sync.json` — direct edits invalidate the fingerprint silently. To update absorbed content, route through `/kepano-resync`.

A **PostToolUse hook** (`scripts/hooks/validate-sync-json.sh`) re-runs `sync-kepano.sh` after edits to `kepano-sync.json` to catch drift introduced by ledger edits.

A **SessionStart hook** runs the kepano detector with `--no-fetch` for a passive integrity check at session open. Note: this hook lives in `.claude/settings.json` of THIS source repo only — it is not shipped in the distributed plugin (`.claude-plugin/plugin.json` declares no hooks), so it fires only when working in this source repo, not in Code or Cowork consumer sessions.

Vault-side absorption was retired in v1.0.0 — the Organon vault is PA's own, and the plugin is now the canonical home for frontmatter registre / vocabularies / methodologies. Edit those references directly.

## Repo layout

| Path | Purpose |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (version, description, keywords). |
| `skills/<name>/SKILL.md` | 10 skills total — 7 description-triggered, 3 user-only (`disable-model-invocation: true`). |
| `skills/<name>/references/` | Lazy-loaded refs. Some absorbed (kepano) with HTML markers, most Organon-owned. |
| `skills/<name>/<agent>.md` | Skill-exclusive orchestrator agents co-located with their owning skill (3 total: `kepano-resync-orchestrator`, `memory-audit-executor`, `plugin-release-executor`). Symlinked from `.claude/agents/` for runtime discovery. |
| `.claude/agents/*.md` | General-purpose plugin agents not tied to a single skill: `changelog-synthesizer`, `kepano-drift-resolver`, `markdown-link-validator`, `readme-inventory-checker`, `release-readiness`, `token-harness-regression`. |
| `commands/<name>.md` | 3 slash-command wrappers (`/kepano-resync`, `/plugin-release`, `/organon-memory-audit`). |
| `scripts/sync-kepano.sh` | kepano drift detector (exit 0 = in-sync, 1 = drift, ≥2 = gate-unavailable). |
| `scripts/hooks/` | PreToolUse + PostToolUse hooks. |
| `scripts/token-harness.py` | Token-cost measurement; methodology in `docs/token-harness-methodology.md`. |
| `eval-workspace/iteration-N/` | **Gitignored.** Token harness output and benchmark notes per iteration. |
| `kepano-sync.json` | kepano drift ledger (per-section `body_sha256`, `synced_at_sha`, `synced_at_date`). |

## Working with absorbed files — DO NOT bypass the hook

If you need to update content in kepano-absorbed files (`PROPERTIES.md`, `MARKDOWN_SYNTAX.md`, `CALLOUTS.md`, `EMBEDS.md`, `BASES_SYNTAX.md`, `FUNCTIONS_REFERENCE.md`, `CANVAS_SPEC.md`, `EXAMPLES.md`, `MERMAID_SYNTAX.md`) — do **not** edit them directly. The PreToolUse hook will block, for good reason: the `body_sha256` would silently desync from upstream.

The legitimate paths:
- **kepano-absorbed**: invoke `/kepano-resync` (or the `kepano-drift-resolver` subagent for fan-out across drifted sections).
- **Intentional de-absorption**: delete the `kepano-sync.json` entry first, then edit as Organon-owned content.

### Resync token (`.organon-resync-token`)

The `kepano-resync` skill (and the `kepano-drift-resolver` subagent) needs the model to Edit absorbed files mid-flow — but the PreToolUse hook would block. The legitimate bypass is a **scoped, short-lived, audit-logged** token at repo root:

- File: `.organon-resync-token` (repo root, `.gitignored`).
- Format: one rel_path per line; blank lines and `# comments` tolerated.
- Hook behavior: `block-absorbed-edits.sh` allows Edit/Write/MultiEdit *only* on listed paths and writes one stderr audit line per allowed call.
- Cleanup: skill removes the token immediately after the edit batch (`rm -f .organon-resync-token`).
- Safety net: the pre-commit hook **refuses to commit while the token exists** — silent leakage is impossible.

Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks`, sed/python via Bash, or any other "or similar" route. The token is the legitimate path; using it for a non-resync edit defeats the protection.

## Tooling floor

- `mcp-tools-istefox` ≥ 0.4.5 (consumer expectation, not a build dep).
- `tiktoken` (Python) for the harness — install via `pip install --user tiktoken`.
- `jq`, `gh`, `git`, `zip`, `shasum`/`sha256sum` for scripts.

## Don't

- Don't commit `.plugin` archives (gitignored — distribution is via Release asset).
- Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks` or similar.
- Don't run `sync-kepano.sh` without `--no-fetch` in tight loops (it git-fetches by default).
- Don't add Co-Authored-By trailers — PA rejects them.
- Don't introduce `Co-Authored-By: Claude` or similar attribution. Commit messages are PA's voice.
