## Context
- Repo: folotp/organon-plugin. Distributed via GitHub Release .plugin asset; consumed by folotp/pa-marketplace.
- Uses the claude.ai-hosted Organon connector (→ organon-claude.folot.net, HTTP) for the remote Obsidian MCP server — no bundled .mcp.json (removed 43a9042; was shadowing the connector). Tool prefix mcp__claude_ai_organon__*.

## Workflow
- Release: /pa-toolkit:plugin-release (folotp/pa-toolkit, single source of the release runbook for all PA plugins). Repo pre-flight for it: .claude/agents/release-readiness.md gates, incl. ./scripts/kepano-check-upstream.sh and ./scripts/validate-specs.sh. Version SOT: root plugin.json (semver; Agent Plugins 1.0.0). .claude-plugin/plugin.json = symlink to it. .plugin = gitignored, Release asset only.
- Push main before tag. gh release create: --notes-from-tag incompatible with --repo — use --notes-file for cross-repo invocation.
- Kepano: 9 absorbed files pinned to kepano-version.txt sha. block-absorbed-edits.sh blocks direct edits; .organon-resync-token is the legitimate refresh path. See docs/refreshing-kepano.md.
- Hooks: fire in this source repo only — not in distributed plugin, not in consumer Code/Cowork sessions. See docs/hook-scope.md.
- Portability: skills/ = Agent Skills spec, no product names except literal values or labelled Claude branches; say "agent"/"AI agent". Rules + per-surface install: docs/cross-platform-skills.md. Gate: ./scripts/validate-specs.sh.
- Tool loading: adaptive, connector-side only. Persisted/on-demand/inactive classification + rationale: docs/mcp-tool-loading.md.

## Constraints
- Never commit directly to main. Prefixes: feat/ fix/ chore/ perf/ docs/.
- Never edit kepano-pinned files directly. kepano-check-upstream.sh fetches on every call — pass --no-fetch in tight loops to skip the redundant network round-trip.
- Don't commit .plugin archives.
