# Development hook scope

All hooks in this repository are development adapters; none belong in the runtime package.

- Claude bindings live in `.claude/settings.json`. The edit guard and branch reminder call shared code through `scripts/dev`; formatting/lint feedback remains advisory. The skill-delegation reminder is Claude-only.
- Codex's `.codex/hooks.json` binds a SessionStart branch reminder on supported local clients. No assumption of command-hook support in cloud orchestration.
- The Git pre-commit launcher calls `scripts/dev check-staged`, independent of the editing agent. It rejects commits on main/detached HEAD, active resync tokens, and failing checks of the actual index snapshot.
- CI runs `scripts/dev check --base <base-sha>` independently of local hook installation.

Install with `scripts/dev install-hooks`. Git resolves the shared hook location for linked worktrees; the launcher resolves the active worktree for each commit. See `docs/development.md` for setup and older-branch compatibility.

Local hooks are not a security boundary and can be bypassed by Git options; required PR checks and repository rules supply the merge gate. Package selection lives in `config/package-files.json`, with archive verification in `scripts/dev package`.
