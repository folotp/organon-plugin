# Shared AI development setup — verification

Date: 2026-11-09 (America/Toronto). Baseline: Organon `26d1f530cba92732c013429b60e52e83f89e18ee`. This is a repository development test, with no personal vault access, plugin release, tag, marketplace dispatch or publication.

## Clients and isolation

Local macOS: Codex CLI 0.167.0 and Claude Code 2.1.319. Two disposable linked worktrees were created from current main, one per client, with revised development adapters overlaid. A marker was appended to the fixture AGENTS.md and a synthetic `smoke-protected.md` was added to the fixture's protected inventory. Actual pinned references and resync tokens were untouched. Both clients reported the instruction marker without first opening AGENTS.md in the final test.

The ordinary fixture was a shell script deliberately changed to `if true;then echo after;fi`. The protected test replaced `DO NOT CHANGE` with `CHANGED`; the agent was instructed to respect the expected denial and never use another editing path.

| Surface | Instructions | Edit guard | Format feedback | Stop lint |
|---|---|---|---|---|
| Claude from worktree root, project settings only | Pass | Exit 2 before Edit | PostToolUse JSON diff | Advisory JSON, exit 0 |
| Claude direct from scripts subdirectory, original adapter | Import marker absent in first test | Failed; fixture changed | Absent | Not established |
| Codex default discovery in linked worktree | Pass | Revised definitions not discovered | Revised definitions not discovered | Revised definitions not discovered |
| Codex with reviewed definitions selected per invocation | Pass | Exit 2 before apply_patch | PostToolUse JSON diff | Advisory JSON, exit 0 |

Codex `/hooks` in an actual interactive session showed the SessionStart source as the **primary checkout's** `.codex/hooks.json`, with zero PreToolUse/PostToolUse hooks, despite a different linked-worktree cwd. Project trust and the hooks feature alone did not select the worktree definitions. This is an observed CLI 0.167.0 discovery limitation, not a claim that the new edit policy failed. Update the primary checkout after merging; inspect `/hooks` before relying on new definitions in an unmerged worktree.

A one-invocation `-c hooks.<event>=<TOML array>` selected each event from the revised JSON configuration for the Codex test. `--dangerously-bypass-hook-trust` was used only for these reviewed disposable hook definitions, as documented for vetted automation; workspace-write sandboxing remained active. No global project permissions/trust settings changed. The successful events were SessionStart (0), protected multi-file PreToolUse (2), ordinary PreToolUse (0), PostToolUse (0), and Stop (0). A combined patch containing both the synthetic protected file and ordinary script was denied as a whole; a subsequent independent ordinary patch succeeded.

Direct filesystem inspection established that the deliberately unformatted line stayed unformatted and the protected file stayed `DO NOT CHANGE`. Both models initially described the advisory diff as an applied format change. That was an incorrect interpretation of the feedback: the hooks ran `shfmt -d`, never `-w`. Feedback now explicitly says the file is unchanged and formatting requires an explicit command.

## Reproduction

Use disposable worktrees and synthetic inventory entries as above. Do not run the protected-edit prompt against actual absorbed references. For Claude:

```sh
/path/to/worktree/scripts/dev session claude -p --setting-sources project --strict-mcp-config --mcp-config '{"mcpServers":{}}' --allowedTools Read Edit --output-format stream-json --verbose '<fixture prompt>'
```

For Codex, use `scripts/dev session codex exec --ephemeral --ignore-user-config -s workspace-write --json`, explicitly selecting the reviewed hook groups through `-c hooks.SessionStart=...`, `-c hooks.PreToolUse=...`, `-c hooks.PostToolUse=...`, and `-c hooks.Stop=...` when the primary checkout still has older definitions. Normal interactive use should review/trust hooks via `/hooks`; the one-invocation trust flag above is a test-only alternative. Do not disable sandboxing to test these hooks.

The shared session launcher resolves its own worktree root before starting either client, including when invoked from `scripts/`. An isolated launcher test verifies the actual cwd and preservation of arguments containing spaces. Claude commands now resolve scripts through the active Git root rather than `${CLAUDE_PROJECT_DIR}`, which can retain a different startup directory during worktree changes. A root CLAUDE.md imports the canonical AGENTS.md and the thin Claude adapter notes.

Cloud orchestration, hosted tool paths, arbitrary shell writes and MCP writes were not tested as lifecycle-protected editing surfaces. Git's staged-snapshot guard and required CI remain authoritative for those paths. The ordinary fresh-session doctor exposed an unwritable uv cache inside Codex's sandbox and correctly failed; it did not claim a skipped gate was healthy. The managed environment and required checks passed with approved cache access in the development session.

## Checkout-switch investigation (#105)

From the Codex fixture's `scripts/` directory, ran a fresh `claude -p --plugin-dir /path/to/claude-fixture --setting-sources project --strict-mcp-config --mcp-config '{"mcpServers":{}}' --tools '' --output-format json` with a read-only/no-tools prompt. Compared branch and HEAD before/after for both fixture worktrees and the primary checkout: all unchanged. Main stayed on baseline `26d1f53`. The suspected historical branch switch was **not reproduced**; this test does not establish the cause of the earlier incident. Keep agent checkouts isolated regardless.

A squashed revert can make a PR stacked on the old branch merge empty: current-main ancestry already contains the old commits. The development runbook now requires a fresh current-main branch, an explicit revert-of-revert or reapplication, and review of the actual triple-dot diff.

## Deterministic and release checks

- Shared check: tool/version diagnostics, eight skill specifications, manifest schema/symlink, shell lint/format, links/inventory, protected references, unchanged token aggregates, archive contract and 23 isolated infrastructure tests.
- pa-toolkit: eight extension/fallback and branch-guard tests; Linux/macOS CI passed on the initial implementation and are rerun for the reviewed revision `c457505941c788be49459295e872993af7d53297` (PR folotp/pa-toolkit#21). ShellCheck and actionlint passed; the unchanged low-level package.sh has pre-existing shfmt differences, which were not rewritten.
- A real Organon archive matched the allowlist, retained runtime skills/agents/command, required memory-audit docs/script, provenance and manifest compatibility. `claude plugin validate` on the extracted archive passed. Development hook/configuration files, environments and ignored artifacts were absent. Root-level docs and memory-audit references stay shipped to preserve runtime README links; this development verification report is excluded.
- The actual portable release-driver dry-run passed from a clean linked feature worktree. It automatically ran Organon’s shared release-check and package contract, verified 53 runtime files (78 ZIP entries including directories), returned an explicit planned output path and null archive, and cleaned temporary staging. It made no commit, tag, push, publication or marketplace change. A retained build and optional client check are also verified before handoff.

## Protection and rollout

Organon protection was rechecked: strict Linux/macOS checks, PR requirement enforced for admins, no force pushes/deletion. pa-toolkit now has the same policy with its two Release checks; its managed pre-commit and pre-push guards were installed without replacing Organon's staged checker. The release runbook tags only an exact already-merged remote-main commit, preserving protected-main compatibility.

pa-marketplace was unprotected and its bot still directly pushes main. A separate worktree prepares PR-based bumping plus exact-branch validation dispatch (GITHUB_TOKEN-created PRs do not themselves trigger PR workflows). Its actual shell procedure passes a disposable-remote test for new, existing and unchanged bot branches, leaving remote main untouched. Repository instructions explicitly require approval before any commit; PA approved the commit and PR during this session. Do not protect marketplace main until the adapted workflow is merged and Actions PR creation is enabled.

Merge pa-toolkit#21 before Organon's integration PR. Organon's CI pins the new driver revision and runs its actual dry-run contract. Source edits do not update installed pa-toolkit copies; installed distribution requires a separately authorized release. No release was performed.

The disposable client worktrees and their two baseline-only branches were removed; `git worktree list` confirmed only the primary and implementation worktrees remain. The primary Organon checkout stayed clean on main.

Optional cross-format probes found existing pa-toolkit compatibility boundaries: strict skills-ref rejects its unchanged Claude-only `argument-hint` / `disable-model-invocation` fields, and Organon’s portable manifest schema requires `$schema`, which the unchanged legacy pa-toolkit manifest does not declare. These were not substituted for pa-toolkit’s actual required tests. Claude’s native validator passed pa-toolkit with existing directory-catalog warnings (license/icon and root project context); no public plugin submission is part of this task.

The marketplace workflow change is committed in folotp/pa-marketplace#11; its CI validation passed. Its protection/settings rollout is intentionally sequenced after that PR merges, so the current direct-push workflow stays functional in the meantime. All implementation PRs need review/merge before main checkouts use the new sources.

## Review fixes — 2026-11-10

pa-toolkit#21 now rejects existing non-object JSON release extensions, including `null`, before considering fallback packaging. Regression coverage reproduces the old bypass in dry-run and build and also checks arrays, numbers, strings and booleans. All eight release/guard tests passed locally. Organon’s CI pin selects this fixed driver revision.

pa-marketplace#11 now pushes the bot branch even when merging current main is its only change. The isolated remote test advances main in an unrelated file and confirms the refreshed bot branch contains that main commit; it failed before the fix and passes afterward. This prevents a bump PR remaining permanently behind under strict protection.
