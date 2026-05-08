---
name: plugin-release
description: Cut a new release of the organon plugin — bump `version` in `.claude-plugin/plugin.json`, package the `.plugin` archive (zip), tag the commit, create a GitHub Release on `folotp/organon-plugin`, and upload the `.plugin` as a Release asset (since v0.4.0 the asset is the distribution channel — the gitignored `.plugin` is *not* committed). User-only — pushes tags, creates Releases, uploads assets. Codifies the `gh release create` flag-combo gotcha (`--notes-from-tag` is incompatible with `--repo` for cross-repo invocation) and the `organon-v<version>.plugin` asset naming. Use this skill EVERY TIME a new release is being cut — silent failure modes are committing the `.plugin` archive (gitignored, breaks cleanly), forgetting to upload the asset (Release exists but is empty), and the gh CLI flag-combo trap (cryptic error from gh).
disable-model-invocation: true
---

# plugin-release

End-to-end runbook for cutting a `folotp/organon-plugin` release. The `.plugin` archive is gitignored (`.gitignore` line `*.plugin`) — it is *built* and *uploaded as a Release asset*, never committed. The marketplace (`folotp/claude-marketplace`) consumes the asset URL.

## Pre-flight

Run, in order, and stop on the first failure:

1. **Working tree is clean** on `main` (or the release branch if cutting from one). Uncommitted changes pollute the build.

   ```bash
   git status --porcelain  # must be empty
   git rev-parse --abbrev-ref HEAD
   ```

2. **Drift is resolved**: `./scripts/sync-kepano.sh` exits 0. If drift exists, route through `kepano-resync` first or document the divergence (see `kepano-resync` §Divergence) — don't ship a release with unacknowledged drift.

3. **Plugin validates**: invoke the `plugin-dev:plugin-validator` agent against the repo. Failures here ship in the asset — catch them now.

4. **Skills load coherently**: spot-check at least one skill in a fresh chat (the eval workflow under `evals/` is the formal version; spot-check is the fast version).

## Version bump

The single source of truth for the version is `.claude-plugin/plugin.json` `version`. Semver:

- **patch** (`0.4.0` → `0.4.1`): bug fix, doc clarification, no behavioral change to skills.
- **minor** (`0.4.0` → `0.5.0`): new skill added, new behavioral rule, kepano re-sync that changes absorbed content.
- **major** (`0.4.0` → `1.0.0`): breaking change to skill descriptions or removal of a skill (description-triggered loading means description changes are user-facing).

Bump the field with `Edit` (do not script it; one-line manual edit avoids accidentally rewriting the whole file). Then commit:

```bash
git add .claude-plugin/plugin.json
git commit -m "organon v<new-version> — <one-line summary>"
```

## Build the .plugin archive

Use `scripts/package.sh` from this skill (`skills/plugin-release/scripts/package.sh` — copy or invoke directly). The archive is a zip of the plugin tree minus build/eval/git noise; the produced file is `organon-v<version>.plugin` at the repo root.

```bash
bash skills/plugin-release/scripts/package.sh
ls -la organon-v*.plugin
```

The archive must contain at minimum: `.claude-plugin/plugin.json`, `skills/**`, `scripts/**`, `docs/**`, `README.md`, `kepano-sync.json`. It must *not* contain: `.git/`, `eval-workspace*/`, `evals/iteration-*/`, `__pycache__/`, `.DS_Store`, prior `*.plugin`/`*.skill` archives. Verify:

```bash
unzip -l organon-v<version>.plugin | grep -E '(eval-workspace|__pycache__|\.DS_Store|\.git/)'
# expected: no matches
```

## Tag and push

```bash
git tag -a v<version> -m "organon v<version> — <one-line summary>"
git push origin main
git push origin v<version>
```

Push `main` *before* the tag — pushing the tag first against an out-of-date remote can leave the tag pointing at a commit that doesn't exist on origin yet.

## Create the Release

The convention since v0.4.0:

```bash
gh release create v<version> \
    organon-v<version>.plugin \
    --title "organon v<version> — <one-line summary>" \
    --notes "<body — see references/release-notes-template.md>"
```

### Flag-combo gotcha (memory-recorded, v0.4.0+)

`--notes-from-tag` is **incompatible** with `--repo` when invoking gh from outside the repo's working directory. The error message is cryptic. Two safe forms:

- **Inside the repo** (preferred): omit `--repo`; let gh infer from the cwd.

  ```bash
  gh release create v<version> organon-v<version>.plugin \
      --title "..." --notes "..."
  ```

- **Outside the repo** (cross-repo invocation): pass `--repo folotp/organon-plugin` AND pass `--notes` explicitly (a string or `--notes-file <path>`). Do *not* combine with `--notes-from-tag`.

  ```bash
  gh release create v<version> organon-v<version>.plugin \
      --repo folotp/organon-plugin \
      --title "..." --notes-file release-notes.md
  ```

Verify the asset uploaded:

```bash
gh release view v<version> --json assets --jq '.assets[].name'
# expected: organon-v<version>.plugin
```

## Marketplace propagation

After the Release is up:

```bash
# In any client wanting the new version:
/plugin marketplace update folotp-marketplace
/plugin install organon@folotp-marketplace   # or update if already installed
```

The marketplace metadata in `folotp/claude-marketplace` may need a version bump entry — check `marketplace.json` in that repo (separate workflow; not in scope for this skill).

## Anti-patterns

- **Committing the `.plugin` file**: it's gitignored. If `git status` shows it staged, `git rm --cached` and re-add to `.gitignore`. Distribution is via Release asset, period.
- **Tagging before pushing main**: tag points at a commit not yet on origin → push of tag fails or creates a dangling reference. Always `push main` first.
- **Skipping the `plugin-validator` step**: a malformed `plugin.json` ships in the asset and breaks marketplace install — the marketplace doesn't validate at install time.
- **Reusing a tag**: `git tag -f` rewrites; `gh release delete` + recreate is the safer path if the asset needs to change post-publish. But if the tag is *consumed* (someone installed it), bump patch instead — never overwrite a published tag.
- **Forgetting `--no-verify` is not allowed here**: pre-commit hooks must pass; signing must not be skipped. PA's global rule.

## Files

- `scripts/package.sh` — builds `organon-v<version>.plugin` from the repo root.
- `references/release-notes-template.md` — body template for `gh release create --notes`.
