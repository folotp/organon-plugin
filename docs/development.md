# Shared development workflow

## Setup

The minimum supported tool versions live in `config/toolchain.json`: Git 2.31, uv 0.13.7, jq 1.6, shfmt 3.6, ShellCheck 0.9, and Info-ZIP 3.0. These are supported minimums, not exact shell-tool pins; CI package managers may supply newer versions. Python libraries and the skills validator revision remain locked by `uv.lock`. The launcher uses Python 3.9+ (including Apple's system Python); uv selects the project Python 3.11+ separately. Doctor reports both interpreters and detected tool versions, and fails missing, unsupported, or unparseable required tooling. CI runs doctor as part of the same check on Linux/macOS. Shell code remains Bash 3.2 compatible.

On macOS, install the command-line tools with Homebrew. `uv sync --locked` prepares the project environment. A missing/offline cache is a failed check, never a skipped gate. Under a sandbox, request approved access for a blocked existing cache or prepare an explicitly writable cache/environment before checking. `UV_CACHE_DIR` and `UV_PROJECT_ENVIRONMENT` are supported explicit per-invocation uv settings; avoid silently changing global settings. Keep environments outside version control.
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

Start the agent in that worktree, preferably with `./scripts/dev session claude` or `./scripts/dev session codex`. The launcher resolves the repository root even when called from a subdirectory and preserves client flags, trust and permissions. Do not switch another agent's branch or overwrite its files. PR descriptions record scope, verification, and remaining issues; tracked docs hold lasting decisions.

Hooks are installed at Git's resolved hook path, respecting `core.hooksPath`. The launcher resolves the current worktree at commit time. Worktrees commonly share this hook file: installation affects all of them. Unmanaged hooks are preserved and require a manual merge. Older branches without `scripts/dev` fail explicitly after installation; update them before committing. `--uninstall` removes only this managed launcher.

## Commands

| Command | Behavior |
|---|---|
| `scripts/dev session claude\|codex [args]` | Launch the client from the current worktree root |
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

`AGENTS.md` is canonical. Claude imports it; Codex loads it directly. `.claude/agents/` contains thin wrappers around shared commands. `.codex/hooks.json` provides SessionStart, native patch protection, formatting feedback and advisory Stop lint. Review/trust the exact hook definitions using Codex `/hooks`; changed definitions require review again. See `docs/hook-scope.md` for supported payloads and limits. Local command hooks may be unavailable in cloud orchestration; correctness depends on Git/CI, not those reminders. Installed marketplace skills remain distinct from this checkout: test unreleased skills in an isolated agent configuration selecting this checkout, with the installed duplicate disabled.

Sources: https://learn.chatgpt.com/docs/agent-configuration/agents-md, https://learn.chatgpt.com/docs/hooks, https://code.claude.com/docs/en/memory.

## Branch protection and reverted work

Main requires a pull request and the two matrix checks, including for administrators. The shared local pre-commit guard rejects main and detached HEAD; it checks the actual index even when working-tree edits differ. Release tags must point to the exact merged remote main commit. A release never needs a direct main push.

After a squash-merged revert, do not stack a replacement PR on the reverted branch and assume its commits restore the changes. Git may regard the original commits as already merged and produce an empty PR (as #96 did). Branch from current main, revert the revert or reapply the intended patch, then inspect `git diff origin/main...HEAD` and the PR Files changed before merging.

A headless client loading `--plugin-dir` is not authorized to switch its source checkout. Use disposable worktrees and read-only tools for investigation. Record client-specific observations in `docs/verification/shared-ai-setup.md`; an unreproduced historical switch is not proof of its cause.
