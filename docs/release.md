# Release workflow

The general release implementation remains in `folotp/pa-toolkit`; do not duplicate it here. A development task does not authorize publishing.

## Preflight and packaging

Resolve the intended installed or local `pa-toolkit/skills/plugin-release/scripts/package.sh` explicitly, then run:

```sh
./scripts/dev release-check --packager /path/to/pa-toolkit/skills/plugin-release/scripts/package.sh
```

For the actual archive, use `scripts/dev package --packager <same-path> --output <directory>` as this repository's packaging entry point in the pa-toolkit release workflow. It stages only `config/package-files.json` inputs in a temporary directory, delegates archive creation to pa-toolkit, and verifies the archive's exact file inventory. Do not call the generic packager directly on this source checkout: its broad inclusion rules can include development adapters and local artifacts. No pa-toolkit source change is required by this wrapper; automated callers of its generic packager must adopt this repository entry point before the next release.

The package retains portable skills, Claude runtime agents/command, documentation, the memory-audit upstream-check script, protected-reference inventory, metadata, assets, README, license, and provenance pin. It excludes automatically loaded development instructions, hooks, tests, environments, development scripts, and CI. Runtime hooks and bundled MCP configuration remain absent.

The pin-to-upstream-HEAD comparison is an advisory update signal, never proof of adapted-content equivalence. Other required check failures stop release. An optional `claude plugin validate <staged-package-root>` is a client compatibility smoke test, not a dependency of shared validation.

## Release notes

Read `git log --first-parent <previous-tag>..HEAD`, including subjects and bodies. Include both merge commits and single-parent PR commits; never use `--merges` as the sole source. Use explicit PR numbers/branch names only when present in Git history. Group changes by documented prefixes; preserve uncategorized changes under Other. Follow pa-toolkit's release-notes template when available, and mark unverifiable compatibility claims for review. Return a draft; publishing belongs to the authorized release workflow.

## Release boundaries

Version source: root `plugin.json`; preserve the Claude manifest symlink. Update the README release entry together with the version. Run tests before committing. Merge through a PR and push main before creating the tag. Keep archives out of Git. GitHub release publication triggers the existing marketplace notification workflow.
