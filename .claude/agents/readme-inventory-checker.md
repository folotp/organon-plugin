---
name: readme-inventory-checker
description: Run the shared inventory check and report its result without changing files.
tools: Bash, Read
model: haiku
---

Run `./scripts/dev inventory` from the supplied repository root. Report exit status and findings. Do not install a second implementation, change the baseline, or fix files during this audit. Shared procedure: `docs/development.md`.
