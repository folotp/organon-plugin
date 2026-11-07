# Cross-platform skills

One set of Organon rules for every AI agent. `skills/` is the single source; each agent loads the same files.

## Specs

| Spec | Version | Governs |
|---|---|---|
| [Agent Skills](https://agentskills.io/specification) | Unversioned; aligned to the text current on 2026-11-06 | `SKILL.md` and skill folders |
| [Agent Plugins](https://agent-plugins.org/) | 1.0.0 (1.1.0 is a working draft, not targeted) | Root `plugin.json` and the `skills/` location |

`./scripts/validate-specs.sh` checks both. A client must skip a skill that doesn't conform, so a failure means the skill may not load on that surface.

## Writing portable skills

- **Frontmatter:** only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. `allowed-tools` is a space-separated string.
- **Paths:** relative to the skill root, and inside the skill. A skill may be imported on its own, so it can't rely on repo paths.
- **Other skills:** refer to them by bare name (`organon-vault-read`).
- **Tools:** use bare names (`get_vault_file`). Each agent matches them to its own tool list, whatever prefix its platform adds, so no configuration is needed.
- **Wording:** say "the agent", or "AI agent" where it needs to be clearer. Name a product only for a literal value (`creator: Gemini`, a folder path) or a labelled platform branch such as "Claude dispatch".
- **Platform features:** give a fallback. Subagents are optional: `organon-bases` and `organon-canvas` keep their runbook in `references/AUTHOR_RUNBOOK.md`, and the files in `agents/` only point Claude's subagents at it.
- **Claude-only content:** stays outside `skills/`: `agents/`, `commands/`, `docs/memory-audit/`. Other clients ignore what they don't support.

## Manifest

Root `plugin.json` is the version source. `.claude-plugin/plugin.json` is a symlink to it, because Claude Code documents that path and not the root one.

Claude Code only loads subagents from `agents/`, and doesn't follow a symlink there. It doesn't load a plugin's `.claude/agents/`.

## Install and update

| Agent | Install | Update |
|---|---|---|
| Claude | Marketplace `folotp/pa-marketplace` | Release bumps the marketplace entry |
| ChatGPT | Same marketplace, through `.agents/plugins/marketplace.json` | Same |
| Gemini | Run `scripts/build-skill-bundles.sh`, then Create → Upload each zip at gemini.google.com | Same script lists changed skills. Use Replace skill for each |

`organon-memory-audit` audits Claude stores, so it's a Claude command rather than a skill.

## Limits

- Skills are guidance, not a control. Per-agent tokens are the real protection: ChatGPT and Gemini are read-only.
- Connector server instructions are hard-coded, so rules can't be delivered through MCP.
- Gemini custom apps are documented as US-only and English-only.
- OpenAI says plugin availability can vary by surface.
