# organon-plugin — Claude orientation

Source repo for the **organon** Claude Code / Cowork plugin (`folotp/organon-plugin`). Distributed via GitHub Release with a `.plugin` asset, consumed by `folotp/claude-marketplace`.

## Branch policy

- **Never commit directly to `main`.** Pattern: feature/release branch → PR → merge-commit.
- Branch prefixes by intent: `feat/`, `fix/`, `chore/`, `perf/`, `docs/`.
- `Co-Authored-By` trailers and any `Claude` attribution in commit messages are rejected — commits are PA's voice.

## Release flow

Runbook: `/plugin-release` (dispatches to `plugin-release-executor`). Invariants:

- Single source of truth for version: `.claude-plugin/plugin.json` `version` (semver).
- `.plugin` archive is `.gitignored`; distributed as a Release asset, never committed.
- Pre-flight via `release-readiness` agent — see its body for the 6 gates.
- Push `main` *before* the tag.
- `gh release create` flag-combo: `--notes-from-tag` is incompatible with `--repo` (cross-repo invocation needs `--notes-file` instead).

## Kepano absorption — version-pin model (v1.0.0+)

The plugin carries 9 references adapted from `kepano/obsidian-skills`. Pinned upstream sha lives in `kepano-version.txt`. Refresh runbook: `docs/refreshing-kepano.md`. The PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`) blocks direct edits on the 9 paths; legitimate refresh uses `.organon-resync-token` — see `docs/contributor-notes.md`.

## Hook scope invariant

Hooks declared in `.claude/settings.json` fire only when working in **this** source repo. They are not in the distributed plugin (`.claude-plugin/plugin.json` declares no hooks). Code or Cowork consumer sessions never see them. See `docs/hook-scope.md` for the audit recipe.

## Repo layout

| Path | Purpose |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest. |
| `.mcp.json` | Bundled remote MCP server (`mcp-tools-istefox` → `obsidian-mcp.folot.net`, HTTP). Ships to consumers. |
| `skills/<name>/SKILL.md` | 10 skills (8 description-triggered, 2 user-only). |
| `skills/<name>/<agent>.md` | Co-located executor/author agents; symlinked from `.claude/agents/`. |
| `kepano-version.txt` | Pinned upstream sha for absorbed content. |
| `scripts/token-harness.py` | Cost measurement; methodology in `docs/token-harness-methodology.md`. |
| `eval-workspace/iteration-N/` | Gitignored — harness output per iteration. |

## Don't

- Don't commit `.plugin` archives.
- Don't bypass `block-absorbed-edits.sh` (the `.organon-resync-token` is the legitimate path).
- Don't run `kepano-check-upstream.sh` without `--no-fetch` in tight loops.

See `docs/contributor-notes.md` for tooling floor, resync-token lifecycle details, and absorbed-files refresh.
