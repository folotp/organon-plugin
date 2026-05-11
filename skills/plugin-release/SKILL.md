---
name: plugin-release
description: Cut a new release of the organon plugin — bump `version` in `.claude-plugin/plugin.json`, package the `.plugin` archive (zip), tag the commit, create a GitHub Release on `folotp/organon-plugin`, and upload the `.plugin` as a Release asset (since v0.4.0 the asset is the distribution channel — the gitignored `.plugin` is *not* committed). User-only — pushes tags, creates Releases, uploads assets. Codifies the `gh release create` flag-combo gotcha (`--notes-from-tag` is incompatible with `--repo` for cross-repo invocation) and the `organon-v<version>.plugin` asset naming. Use this skill EVERY TIME a new release is being cut — silent failure modes are committing the `.plugin` archive (gitignored, breaks cleanly), forgetting to upload the asset (Release exists but is empty), and the gh CLI flag-combo trap (cryptic error from gh).
disable-model-invocation: true
allowed-tools:
  - Agent
---

# plugin-release

> **BLOCKING REQUIREMENT — DO NOT PROCEED INLINE**
>
> **THE FIRST AND ONLY ACTION THIS SKILL TAKES IS TO DISPATCH THE `plugin-release-executor` SUB-AGENT.** The main session MUST NOT execute the release runbook inline. All pre-flight checks, version bumping, packaging, tagging, and GitHub Release creation live in `.claude/agents/plugin-release-executor.md`. This skill is a routing shim — its entire job is to hand off to that agent.

## How to dispatch

```js
Agent({
  description: "Execute plugin release",
  subagent_type: "plugin-release-executor",
  prompt: "<version bump type (patch/minor/major)>, repo root: <absolute path>, release notes: <any maintainer notes or leave blank>, dry-run: <true|false>"
})
```

## Args to forward

- **Version bump type**: `patch`, `minor`, or `major` (see semver semantics in the executor runbook).
- **Repo root absolute path**: the working directory; pass explicitly so the executor resolves all paths unambiguously.
- **Release notes / maintainer notes**: any copy the user wants in the GitHub Release body; leave blank to let the executor apply the template.
- **Dry-run flag**: `true` to run all pre-flight and packaging steps without pushing the tag or creating the Release.

## When NOT to delegate inline

These edge cases still route through the executor, but with `dry-run: true` so the maintainer can intervene before the GitHub Release is created:

- Release notes must be hand-authored before `gh release create` (pass them explicitly after review).
- Unusual asset name or non-standard archive contents (executor supports override flags).
- Releasing from a branch other than `main` — confirm the branch name and pass it in the prompt.
- Any doubt about pre-flight gate status — run dry-run, inspect output, then re-invoke without the flag.

In all cases, do **not** fall back to running the runbook steps directly in the main session.

## Runbook location

The complete release runbook is in `.claude/agents/plugin-release-executor.md`.
