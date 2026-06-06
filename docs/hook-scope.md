# Hook scope — what fires where

A repeatedly-asked question: which hooks fire when, and is anything imposed on consumers of the plugin? Answer: **no, nothing**. All hooks live in `.claude/settings.json` of this source repo and fire only when a Code session is opened against `~/Developer/organon-plugin`.

## Verification recipe

```bash
# 1. Plugin manifest declares zero hooks.
jq '.hooks // "none"' .claude-plugin/plugin.json
# expected: "none"

# 2. Project-level hooks are scoped to .claude/settings.json (in-repo).
jq '.hooks | keys' .claude/settings.json
# expected: ["PostToolUse","PreToolUse","Stop","UserPromptSubmit"]

# 3. No hook script is registered with a path outside ${CLAUDE_PROJECT_DIR}.
jq '.. | objects | select(.command) | .command' .claude/settings.json | grep -v 'CLAUDE_PROJECT_DIR'
# expected: empty
```

## What is shipped vs not

| Hook | Fires when | Shipped in `.plugin` asset? |
|---|---|---|
| `block-absorbed-edits.sh` (PreToolUse, Edit\|Write\|MultiEdit) | session opened against this source repo | no |
| `enforce-skill-delegation.sh` (PreToolUse, Skill) | same | no |
| `postedit-shfmt.sh` (PostToolUse, Edit\|Write\|MultiEdit) | same | no |
| `userprompt-branch-check.sh` (UserPromptSubmit) | same | no |
| `stop-shellcheck.sh` (Stop) | same | no |

The distributed `.plugin` archive contains `.claude-plugin/plugin.json` (no hook key), `.mcp.json` (the bundled remote MCP server — this one *does* ship to consumers, unlike hooks), `skills/`, `scripts/`, `docs/`, `README.md`, and `kepano-version.txt` — never `.claude/settings.json`. Consumer Code or Cowork sessions install the plugin's skills, commands, and MCP server; they do not inherit any hook from this repo.

## v1.0.0 history

- v0.x had a `SessionStart` hook that emitted a one-line drift summary at the top of every session opened in this repo (~32 tokens). Retired in v1.0.0 — kepano upstream checks now live in the pre-commit gate (where they're release-relevant) and in the `release-readiness` agent.
- v0.x had a `PostToolUse` validate-sync-json hook that re-ran `sync-kepano.sh` after edits to `kepano-sync.json`. Retired in v1.0.0 — `kepano-sync.json` no longer exists; the version-pin model uses `kepano-version.txt` (a one-line file that doesn't need post-edit validation).
