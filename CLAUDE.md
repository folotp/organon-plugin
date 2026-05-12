# organon-plugin — Claude orientation

This is the source repo for the **organon** Claude Code plugin (`folotp/organon-plugin`). Distribution channel: GitHub Release with a `.plugin` asset, consumed by the `folotp/claude-marketplace`.

## Branch policy

- **Never commit directly to `main`.** Required pattern: feature/release branch → PR → merge-commit. `Co-Authored-By` trailers are rejected. Recent merge commits (`612cf86`, `6fc7db1`) are the canonical examples.
- The repo has `allow_merge_commit=true` set explicitly to support the merge-commit pattern.
- Branch naming: `feat/`, `fix/`, `chore/`, `perf/`, `docs/` prefixes by intent.

## Release flow

The `plugin-release` skill (`/plugin-release`, user-invokable) is the runbook. Critical invariants:

- The single source of truth for the version is `.claude-plugin/plugin.json` `version` (semver).
- The `.plugin` archive is **gitignored** (`*.plugin` in `.gitignore`). Distribution is via GitHub Release asset, never committed.
- **Pre-flight gates** (see `release-readiness` subagent for parallel pre-flight, or run sequentially):
  1. Working tree clean on `main` (or release branch).
  2. `./scripts/kepano-check-upstream.sh` exits 0 (pinned sha matches upstream).
  3. `plugin-dev:plugin-validator` agent passes.
  4. (Optional, on minor/major) `python3 scripts/token-harness.py` regression check.
- **Tag flow**: push `main` *before* the tag — pushing the tag against an out-of-date remote leaves a dangling reference.
- **`gh release create` flag-combo gotcha**: `--notes-from-tag` is incompatible with `--repo`. Inside the repo, omit `--repo`. Cross-repo, use `--notes` or `--notes-file` instead. Don't combine with `--notes-from-tag`.

## Kepano absorption — version-pin model

The plugin carries 9 references absorbed verbatim from `kepano/obsidian-skills` (generic Obsidian syntax). One upstream sha is pinned in `kepano-version.txt`. Check: `./scripts/kepano-check-upstream.sh`. Refresh runbook: `docs/refreshing-kepano.md`.

A **PreToolUse hook** (`scripts/hooks/block-absorbed-edits.sh`) blocks direct `Edit|Write|MultiEdit` on the 9 absorbed paths (hardcoded list) to prevent silent drift from the pin. A scoped, audit-logged `.organon-resync-token` allows refresh-time edits; the pre-commit hook refuses to commit while the token exists.

Hooks declared in `.claude/settings.json` fire only when working in **this** source repo. They are not shipped in the distributed plugin (`.claude-plugin/plugin.json` declares no hooks), so they do not run in Code or Cowork consumer sessions.

Vault-side absorption was retired in v1.0.0 — the Organon vault is PA's own, and the plugin is now the canonical home for frontmatter registre / vocabularies / methodologies. Edit those references directly.

## Repo layout

| Path | Purpose |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (version, description, keywords). |
| `skills/<name>/SKILL.md` | 9 skills total — 7 description-triggered, 2 user-only (`disable-model-invocation: true`). |
| `skills/<name>/references/` | Lazy-loaded refs. 9 absorbed (kepano, pinned to one upstream sha); rest are Organon-owned. |
| `skills/<name>/<agent>.md` | Skill-exclusive executor agents co-located with their owning skill (2: `memory-audit-executor`, `plugin-release-executor`). Symlinked from `.claude/agents/` for runtime discovery. |
| `.claude/agents/*.md` | General-purpose plugin agents: `changelog-synthesizer`, `markdown-link-validator`, `readme-inventory-checker`, `release-readiness`, `token-harness-regression`. |
| `commands/<name>.md` | 2 slash-command wrappers (`/plugin-release`, `/organon-memory-audit`). |
| `scripts/kepano-check-upstream.sh` | Compares pinned sha vs upstream HEAD (exit 0 = in-sync, 1 = upstream advanced, ≥2 = gate-unavailable). |
| `scripts/hooks/` | PreToolUse + PostToolUse + UserPromptSubmit + Stop hooks (in-repo only — not shipped). |
| `scripts/token-harness.py` | Token-cost measurement; methodology in `docs/token-harness-methodology.md`. |
| `eval-workspace/iteration-N/` | **Gitignored.** Token harness output and benchmark notes per iteration. |
| `kepano-version.txt` | One line: `kepano/obsidian-skills@<sha>`. |

## Working with absorbed files — DO NOT bypass the hook

If you need to update content in kepano-absorbed files (`PROPERTIES.md`, `MARKDOWN_SYNTAX.md`, `CALLOUTS.md`, `EMBEDS.md`, `BASES_SYNTAX.md`, `FUNCTIONS_REFERENCE.md`, `CANVAS_SPEC.md`, `EXAMPLES.md`, `MERMAID_SYNTAX.md`) — do **not** edit them directly. The PreToolUse hook blocks: a casual edit drifts the absorbed content from the upstream pin.

The legitimate path: follow `docs/refreshing-kepano.md` — bump `kepano-version.txt` to a new upstream sha, rewrite the affected references in the same commit, and the pre-commit gate confirms the new pin is in-sync before the commit lands.

### Resync token (`.organon-resync-token`)

To edit an absorbed reference as part of a refresh, drop a scoped, audit-logged token at repo root:

- File: `.organon-resync-token` (repo root, `.gitignored`).
- Format: one rel_path per line; blank lines and `# comments` tolerated.
- Hook behavior: `block-absorbed-edits.sh` allows Edit/Write/MultiEdit *only* on listed paths and writes one stderr audit line per allowed call.
- Cleanup: skill removes the token immediately after the edit batch (`rm -f .organon-resync-token`).
- Safety net: the pre-commit hook **refuses to commit while the token exists** — silent leakage is impossible.

Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks`, sed/python via Bash, or any other "or similar" route. The token is the legitimate path; using it for a non-resync edit defeats the protection.

## Tooling floor

- `mcp-tools-istefox` ≥ 0.4.5 (consumer expectation, not a build dep).
- `tiktoken` (Python) for the harness — install via `pip install --user tiktoken`.
- `jq`, `gh`, `git`, `zip`, `shasum`/`sha256sum` for scripts.

## Don't

- Don't commit `.plugin` archives (gitignored — distribution is via Release asset).
- Don't bypass `block-absorbed-edits.sh` with `--dangerously-skip-hooks` or similar.
- Don't run `kepano-check-upstream.sh` without `--no-fetch` in tight loops (it `git ls-remote`s by default).
- Don't add Co-Authored-By trailers — PA rejects them.
- Don't introduce `Co-Authored-By: Claude` or similar attribution. Commit messages are PA's voice.
