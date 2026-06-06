# Contributor notes

Operational detail moved out of `CLAUDE.md` so the always-loaded orientation stays lean. Read this when you actually need to do one of these things.

## Tooling floor

- `mcp-tools-istefox` ≥ 0.8.0 — the connector the plugin's bundled MCP server (`.mcp.json`) talks to; describes the tool surface the remote endpoint must expose, not a build dep on this repo. The endpoint (`https://obsidian-mcp.folot.net/mcp`) is PA's Obsidian instance behind a cloudflared tunnel + Cloudflare Access.
- `tiktoken` (Python) — required by `scripts/token-harness.py`. Install: `pip install --user tiktoken`.
- `jq`, `gh`, `git`, `zip`, `shasum`/`sha256sum` — used by scripts and hooks.

## Working with absorbed files — DO NOT bypass the hook

The 9 kepano-absorbed references are:

- `skills/organon-bases/references/BASES_SYNTAX.md`
- `skills/organon-bases/references/FUNCTIONS_REFERENCE.md`
- `skills/organon-canvas/references/CANVAS_SPEC.md`
- `skills/organon-canvas/references/EXAMPLES.md`
- `skills/organon-diagramming/references/MERMAID_SYNTAX.md`
- `skills/organon-frontmatter/references/PROPERTIES.md`
- `skills/organon-markdown-style/references/CALLOUTS.md`
- `skills/organon-markdown-style/references/EMBEDS.md`
- `skills/organon-markdown-style/references/MARKDOWN_SYNTAX.md`

Direct `Edit|Write|MultiEdit` on any of them is blocked by the PreToolUse hook. The legitimate path is a refresh: follow `docs/refreshing-kepano.md`, bump `kepano-version.txt` to a new upstream sha, rewrite the affected references in the same commit. The pre-commit gate confirms the new pin is in-sync before the commit lands.

## Resync token (`.organon-resync-token`)

Scoped, short-lived, audit-logged bypass for refresh-time edits.

- **File**: `.organon-resync-token` at repo root (gitignored).
- **Format**: one rel_path per line; blank lines and `# comments` tolerated.
- **Hook behavior**: `block-absorbed-edits.sh` allows Edit/Write/MultiEdit *only* on listed paths and writes one stderr audit line per allowed call.
- **Cleanup**: remove immediately after the edit batch (`rm -f .organon-resync-token`).
- **Safety net**: the pre-commit hook **refuses to commit while the token exists** — silent leakage is impossible.

Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks`, sed/python via Bash, or any other "or similar" route. The token is the legitimate path; using it for a non-resync edit defeats the protection.

## Pre-commit hook installation

Managed pre-commit gate at `.git/hooks/pre-commit`. Installed by `scripts/hooks/install-git-hooks.sh`. Re-run with `--force` after editing the embedded HOOK template; remove via `--uninstall`.
