# Contributor notes

Operational detail moved out of `AGENTS.md` so the always-loaded orientation stays lean. Read this when you actually need to do one of these things.

## Tooling floor

- `mcp-tools-istefox` ≥ 3.3.0 — the server the claude.ai-hosted Organon connector talks to (no bundled `.mcp.json` in this plugin — removed 43a9042); describes the tool surface the remote endpoint must expose, not a build dep on this repo. The endpoint (`https://organon-claude.folot.net/mcp`) is PA's Obsidian instance behind a cloudflared tunnel + Cloudflare Access. Tool-loading state (persisted/on-demand/inactive) is tracked in `docs/mcp-tool-loading.md`, not here.
- `uv` — runs `scripts/token-harness.py` (`uv run scripts/token-harness.py`); its `tiktoken` dependency is declared inline (PEP 723), so no separate install. Don't use pip.
- `jq`, `gh`, `git`, `zip`, `shasum`/`sha256sum` — used by scripts and hooks.

## Working with absorbed files — DO NOT bypass the hook

The protected-reference inventory is `config/protected-references.json`.

Direct `Edit|Write|MultiEdit` on any of them is blocked by the PreToolUse hook. The legitimate path is a refresh: follow `docs/refreshing-kepano.md`, bump `kepano-version.txt` to a new upstream sha, rewrite the affected references in the same commit. The shared check validates the refresh policy, not upstream byte equivalence.

## Resync token (`.organon-resync-token`)

Scoped, short-lived, audit-logged bypass for refresh-time edits.

- **File**: `.organon-resync-token` at repo root (gitignored).
- **Format**: one rel_path per line; blank lines and `# comments` tolerated.
- **Hook behavior**: `block-absorbed-edits.sh` allows Edit/Write/MultiEdit *only* on listed paths and writes one stderr audit line per allowed call.
- **Cleanup**: remove immediately after the edit batch (`rm -f .organon-resync-token`).
- **Safety net**: the pre-commit hook **refuses to commit while the token exists** — silent leakage is impossible.

Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks`, sed/python via Bash, or any other "or similar" route. The token is the legitimate path; using it for a non-resync edit defeats the protection.

## Pre-commit hook installation

Managed pre-commit gate at Git's resolved hooks path (shared across linked worktrees by default). Installed by `scripts/hooks/install-git-hooks.sh`. The launcher calls tracked shared code; remove via `--uninstall`. Unmanaged hooks are preserved. See `docs/development.md`.
