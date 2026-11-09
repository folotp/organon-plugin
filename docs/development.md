# Shared development workflow

## Setup

Install Git, Python 3.11+, uv 0.13.7, jq, ShellCheck, shfmt, and zip. On macOS, Homebrew supplies these tools. Python libraries and the skills validator revision are pinned in `pyproject.toml` and fully resolved in `uv.lock`; `uv run --locked` refuses stale lockfiles. CI exercises Linux and macOS; shell scripts retain macOS Bash 3.2 compatibility. The shell-tool versions come from each runner's package manager; `doctor` reports the installed paths.

```sh
./scripts/dev doctor
./scripts/dev install-hooks
./scripts/dev check
```

The first check downloads the locked development environment. No MCP connector or vault is needed. `config/plugin.schema.json` is a vendored copy of the Agent Plugins 1.0.0 schema from https://agent-plugins.org/schemas/1.0.0/plugin.schema.json; refresh deliberately with dependency updates.

## Concurrent agents and worktrees

Use one branch and worktree for each independently editing agent. PA's base is `/Users/pierreandre/Developer/Worktrees/organon-plugin`; the helper requires an explicit destination and works on other machines.

```sh
./scripts/dev worktree chore/example /Users/pierreandre/Developer/Worktrees/organon-plugin/example
```

Start the agent in that worktree. Do not switch another agent's branch or overwrite its files. PR descriptions record scope, verification, and remaining issues; tracked docs hold lasting decisions.

Hooks are installed at Git's resolved hook path, respecting `core.hooksPath`. The launcher resolves the current worktree at commit time. Worktrees commonly share this hook file: installation affects all of them. Unmanaged hooks are preserved and require a manual merge. Older branches without `scripts/dev` fail explicitly after installation; update them before committing. `--uninstall` removes only this managed launcher.

## Commands

| Command | Behavior |
|---|---|
| `scripts/dev doctor` | Dependency and local hook diagnostics |
| `scripts/dev check` | Schemas, shell lint/format, links, inventory, protected references, token regression, package contract, infrastructure tests |
| `scripts/dev check --base <commit>` | Also compare protected paths against the specified PR base |
| `scripts/dev check --staged` | Validate an isolated export of the Git index; refuses main/detached HEAD and active resync tokens |
| `scripts/dev format` | Apply shell formatting explicitly |
| `scripts/dev tokens` | Compare inline/delegated main and total modeled tokens to tracked baseline |
| `scripts/dev baseline` | Explicitly replace token baseline after reviewing methodology/content changes |
| `scripts/dev package --packager <path> --output <directory>` | Stage runtime allowlist, invoke pa-toolkit, verify archive entries |
| `scripts/dev release-check --packager <path>` | Require clean tree, run checks and archive verification; upstream freshness advisory |

The link check parses explicit Markdown links and images, including reference links; it skips code examples, external URLs, vault wikilinks, and heading-fragment validation. Inventory checks current skills, commands, and release version; historical changelog content is not a current inventory claim. Semantic wording review remains an agent task.

## CI and testing

`.github/workflows/validate.yml` runs the same complete check on pull requests and main pushes. Configure required checks `Checks (ubuntu-latest)` and `Checks (macos-latest)` in the repository's GitHub rules once the workflow exists on GitHub. Adding workflow YAML alone does not enable branch protection.

Infrastructure tests use temporary repositories outside the vault. Live vault behavior belongs in a separately authorized TEST-Vault session. The release and installed-plugin smoke tests are separate from deterministic checks.

## Agent adapters

`AGENTS.md` is canonical. Claude imports it; Codex loads it directly. `.claude/agents/` contains thin wrappers around shared commands. `.codex/hooks.json` provides a local SessionStart branch reminder where supported. Local command hooks may be unavailable in cloud orchestration; correctness depends on Git/CI, not those reminders. Installed marketplace skills remain distinct from this checkout: test unreleased skills in an isolated agent configuration selecting this checkout, with the installed duplicate disabled.

Sources: https://learn.chatgpt.com/docs/agent-configuration/agents-md, https://learn.chatgpt.com/docs/hooks, https://code.claude.com/docs/en/memory.
