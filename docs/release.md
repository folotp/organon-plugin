# Release workflow

The general release implementation remains in `folotp/pa-toolkit`; do not duplicate it here. A development task does not authorize publishing.

## Preflight and packaging

Resolve the intended installed or local `pa-toolkit/skills/plugin-release/scripts/package.sh` explicitly, then run:

```sh
./scripts/dev release-check --packager /path/to/pa-toolkit/skills/plugin-release/scripts/package.sh
```

The pa-toolkit shared entry point is `skills/plugin-release/scripts/release.py`, with its agent-neutral procedure in `skills/plugin-release/references/runbook.md`. This repository's `config/release.json` explicitly supplies `scripts/dev release-check` and `scripts/dev package`. Both dry-run and build invoke the same contract; the driver returns the verified absolute archive path in a JSON receipt for upload.

```sh
python3 /path/to/pa-toolkit/skills/plugin-release/scripts/release.py /path/to/clean/organon-worktree --packager /path/to/pa-toolkit/skills/plugin-release/scripts/package.sh --output /tmp/organon-release --result /tmp/organon-release-result.json --dry-run
```

The dry-run builds and checks a temporary archive, cleans staging, and returns `planned_archive` with a null `archive`. Omit `--dry-run` only to build a retained archive; that command still does not publish. Pass the receipt's `archive` explicitly to the authorized upload. The repository must be clean, including from a linked worktree. The wrapper stages only `config/package-files.json`, invokes the generic packager, and verifies exact inventory. Never call the generic packager directly on this source checkout.

Source changes in a local pa-toolkit checkout do not change an installed marketplace copy. Select the updated checkout explicitly until a separately authorized pa-toolkit release distributes the new entry point. CI pins a merged pa-toolkit commit and exercises this same release-driver dry-run. Update the pin deliberately when adopting functional driver/packager changes; see the maintenance guide.
The package retains portable skills, Claude runtime agents/command, documentation, the memory-audit upstream-check script, protected-reference inventory, metadata, assets, README, license, and provenance pin. It excludes automatically loaded development instructions, hooks, tests, environments, development scripts, and CI. Runtime hooks and bundled MCP configuration remain absent.

The pin-to-upstream-HEAD comparison is an advisory update signal, never proof of adapted-content equivalence. Other required check failures stop release. An optional `claude plugin validate <staged-package-root>` is a client compatibility smoke test, not a dependency of shared validation.

## Release notes

Read `git log --first-parent <previous-tag>..HEAD`, including subjects and bodies. Include both merge commits and single-parent PR commits; never use `--merges` as the sole source. Use explicit PR numbers/branch names only when present in Git history. Group changes by documented prefixes; preserve uncategorized changes under Other. Follow pa-toolkit's release-notes template when available, and mark unverifiable compatibility claims for review. Return a draft; publishing belongs to the authorized release workflow.

## Release boundaries

Version source: root `plugin.json`; preserve the Claude manifest symlink. Update the README release entry together with the version. Run tests before committing. Merge through a PR and verify that the exact release commit is already on remote main before creating the tag. Keep archives out of Git. GitHub release publication triggers the existing marketplace notification workflow.
