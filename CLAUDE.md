<context>
Repo: folotp/organon-plugin. Distributed via GitHub Release .plugin asset; consumed by folotp/claude-marketplace.
Uses the claude.ai-hosted Organon connector (→ obsidian-mcp.folot.net, HTTP) for the remote Obsidian MCP server — no bundled .mcp.json (removed 43a9042; was shadowing the connector). Tool prefix mcp__claude_ai_organon__*.
</context>

<workflow>
Release: /pa-toolkit:plugin-release (folotp/pa-toolkit, single source of the release runbook for all PA plugins). Repo pre-flight for it: .claude/agents/release-readiness.md gates, incl. ./scripts/kepano-check-upstream.sh. Version SOT: .claude-plugin/plugin.json (semver). .plugin = gitignored, Release asset only.
Push main before tag. gh release create: --notes-from-tag incompatible with --repo — use --notes-file for cross-repo invocation.
Kepano: 9 absorbed files pinned to kepano-version.txt sha. block-absorbed-edits.sh blocks direct edits; .organon-resync-token is the legitimate refresh path. See docs/refreshing-kepano.md.
Hooks: fire in this source repo only — not in distributed plugin, not in consumer Code/Cowork sessions. See docs/hook-scope.md.
Tool loading: adaptive, connector-side only. Persisted/on-demand/inactive classification + rationale: docs/mcp-tool-loading.md.
</workflow>

<constraints>
Never commit directly to main. Prefixes: feat/ fix/ chore/ perf/ docs/.
Never edit kepano-pinned files directly. kepano-check-upstream.sh fetches on every call — pass --no-fetch in tight loops to skip the redundant network round-trip. Don't commit .plugin archives.
</constraints>
