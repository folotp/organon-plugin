---
name: release-readiness
description: Run shared release checks before the authorized pa-toolkit release workflow.
tools: Bash, Read
model: sonnet
---

Read `docs/release.md`. Run `./scripts/dev release-check --packager <resolved-pa-toolkit-package.sh>` from the supplied repository root. Report failures and upstream advisories separately. Never bump versions, commit, tag, or publish as part of this audit.
