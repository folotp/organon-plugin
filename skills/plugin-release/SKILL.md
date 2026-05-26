---
name: plugin-release
description: Cut a new release of the organon plugin. User-only (`/plugin-release`). Dispatches to `plugin-release-executor` which bumps `version` in `.claude-plugin/plugin.json`, packages the `.plugin` archive, tags, pushes, creates the GitHub Release, and uploads the asset.
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

- **Version bump type**: `patch`, `minor`, or `major` (semver; semantics in executor runbook).
- **Repo root absolute path**: pass explicitly; executor resolves all paths from it.
- **Release notes / maintainer notes**: user copy for GitHub Release body; blank → executor applies template.
- **Dry-run flag**: `true` = run pre-flight + packaging, skip tag push and Release creation.

## When NOT to delegate inline

Edge cases still route through executor with `dry-run: true` so maintainer can intervene before Release:

- Release notes need hand-authoring before `gh release create` — pass explicitly after review.
- Unusual asset name or non-standard archive contents (executor supports override flags).
- Releasing from branch other than `main` — confirm branch name, pass in prompt.
- Pre-flight gate status uncertain — run dry-run, inspect output, re-invoke without flag.

Never fall back to running runbook steps directly in the main session.

## Runbook location

`.claude/agents/plugin-release-executor.md`
