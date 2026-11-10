# Development contract

This repository ships Organon vault skills, not the Obsidian MCP server.

## Sources and boundaries
- `skills/`: portable runtime skills and references; use bare MCP tool names and skill-relative references. See `docs/cross-platform-skills.md`.
- `agents/`, `commands/`: Claude runtime adapters. `.claude/agents/`: development wrappers.
- `plugin.json`: sole version source; preserve `.claude-plugin/plugin.json` symlink.
- `scripts/dev`: shared development command; `docs/development.md`: setup and workflow.
- Architecture, source ownership and change procedures: `docs/development-architecture.md`.
- Vault access is unnecessary for development checks. Use an explicitly selected test vault for integration tests; never infer permission to change Organon from a repository task.

## Workflow
- One branch and linked worktree per independently editing agent. Never commit directly to `main`.
- Branch prefixes: `feat/`, `fix/`, `chore/`, `perf/`, `docs/`.
- PA's local worktree base: `/Users/pierreandre/Developer/Worktrees/organon-plugin/`. Other machines may choose any destination.
- Before committing run `./scripts/dev check`; the Git hook additionally checks the staged snapshot. Report unavailable checks honestly.
- For substantial refactors, explain the plan first. Preserve unrelated changes.
- Keep durable decisions in tracked docs and shared runbooks, not private agent memory.
- Shell: Bash 3.2 compatible, `shfmt -i 4 -ci`; Python tooling is locked with uv. Flag new dependencies.

## Code and documentation

Code must explain its own intent through precise names, coherent functions and explicit contracts. Add docstrings or nearby comments for non-obvious inputs/outputs, side effects, failure behavior, invariants and the reasons behind important decisions; do not narrate obvious statements. Complement the code with repository architecture/design documents and operational runbooks. Update code, related docs, examples and tests together in the same PR. Preserve one authoritative implementation of each policy; client adapters refer to it. Documentation is part of completion, not a later task. A reviewer must be able to understand, operate and modify the change without this conversation or private agent memory.

## Protected references and releases
- Protected paths are listed once in `config/protected-references.json`. Follow `docs/refreshing-kepano.md`; never bypass protection through a different editing tool.
- A refresh changes the pin and affected references together. Adaptation-only exceptions require maintainer approval recorded in that config's `exceptions` list with the exact new SHA-256 and reason.
- `.organon-resync-token` is a temporary edit allowance, never a commit allowance; remove it after editing.
- Release implementation stays in `folotp/pa-toolkit`. Read `docs/release.md`; run `./scripts/dev release-check` before the existing release workflow.
- Do not publish, tag, or release unless requested. Never commit generated archives, environments, or evaluation output.
