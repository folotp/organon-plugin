<context>
Repo: folotp/organon-plugin. Distributed via GitHub Release .plugin asset; consumed by folotp/claude-marketplace.
.mcp.json bundles the remote Obsidian MCP server, keyed organon (→ obsidian-mcp.folot.net, HTTP). Ships to consumers; tool prefix mcp__plugin_organon_organon__*.
</context>

<workflow>
Release: /plugin-release runbook. Version SOT: .claude-plugin/plugin.json (semver). .plugin = gitignored, Release asset only.
Push main before tag. gh release create: --notes-from-tag incompatible with --repo — use --notes-file for cross-repo invocation.
Kepano: 9 absorbed files pinned to kepano-version.txt sha. block-absorbed-edits.sh blocks direct edits; .organon-resync-token is the legitimate refresh path. See docs/refreshing-kepano.md.
Hooks: fire in this source repo only — not in distributed plugin, not in consumer Code/Cowork sessions. See docs/hook-scope.md.
</workflow>

<constraints>
Never commit directly to main. Prefixes: feat/ fix/ chore/ perf/ docs/.
Never edit kepano-pinned files directly; don't run kepano-check-upstream.sh without --no-fetch in tight loops. Don't commit .plugin archives.
</constraints>
