# Development hook scope

All hooks in this repository are development adapters; none belong in the runtime package.

- Claude bindings live in `.claude/settings.json`. The edit guard and branch reminder call shared code through `scripts/dev`; formatting/lint feedback remains advisory. The skill-delegation reminder is Claude-only.
- Codex's `.codex/hooks.json` binds SessionStart, PreToolUse/PostToolUse (`apply_patch|Edit|Write`), and Stop. Native `tool_name: apply_patch` carries its patch in `tool_input.command`. The adapter checks every Add/Update/Delete/Move header, resolving relative paths against payload `cwd`; absolute and normalized paths use the same protected inventory and exact scoped-token entries. Unsupported/malformed edit payloads fail with exit 2 and stderr. Claude `tool_input.file_path` shares the same path policy.
- Post-edit formatting returns bounded JSON context and never modifies files. Stop returns bounded advisory JSON, skips a repeated `stop_hook_active`, and never requests an automatic continuation. Missing lint tools produce explicit unavailable feedback. There is no recursive Stop loop.
- Local Codex requires project trust and review of each exact hook definition via `/hooks`. No global configuration changes are needed. For vetted disposable automation the documented one-invocation hook-trust flag may be used; it does not bypass the tool sandbox. Untrusted/unreviewed hooks are skipped by the client. Cloud task orchestration and hosted tool paths have no verified repository lifecycle coverage: use Git/CI gates.
- Arbitrary shell writes, MCP writes, and nested orchestration patches are outside these edit matchers. Do not claim coverage just because native apply_patch works. Git validates every staged editing path; required CI independently enforces policy.
- The Git pre-commit launcher calls `scripts/dev check-staged`, independent of the editing agent. It rejects commits on main/detached HEAD, active resync tokens, and failing checks of the actual index snapshot.
- CI runs `scripts/dev check --base <base-sha>` independently of local hook installation.

Install with `scripts/dev install-hooks`. Git resolves the shared hook location for linked worktrees; the launcher resolves the active worktree for each commit. See `docs/development.md` for setup and older-branch compatibility.

Local hooks are not a security boundary and can be bypassed by Git options; required PR checks and repository rules supply the merge gate. Package selection lives in `config/package-files.json`, with archive verification in `scripts/dev package`.

Official contracts checked 2026-11-09: https://learn.chatgpt.com/docs/hooks and https://code.claude.com/docs/en/hooks. Fresh local client evidence and limits: [verification report](verification/shared-ai-setup.md).

Linked-worktree caveat (Codex CLI 0.167.0): `/hooks` showed project definitions from the primary checkout, even when the session cwd was a linked worktree. During development, changing only the linked worktree’s hooks does not prove they are active. Inspect `/hooks`; for isolated tests, explicitly select the reviewed hook definitions through invocation-local `-c hooks.<event>=...` configuration. After merging, update the primary checkout so discovery sees the new definitions. Commands still resolve the active worktree via Git, and the shared policy inventory comes from that worktree. No global trust setting is changed by the session launcher.
