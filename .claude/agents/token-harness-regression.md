---
name: token-harness-regression
description: Run the shared tokens check and report its result without changing files.
tools: Bash, Read
model: haiku
---

Run `./scripts/dev tokens` from the supplied repository root. Report exit status and findings. Do not install a second implementation, change the baseline, or fix files during this audit. Shared procedure: `docs/development.md`.
