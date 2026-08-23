# MCP tool loading — persisted vs on-demand vs unused

The istefox connector (`obsidian-mcp.folot.net`) uses adaptive tool loading: every tool starts `inactive`.
`activate_tool`/`activate_tools` promotes a tool to `active` (`persist:false`, default — in-memory,
connector-process-scoped, lost on restart/reload) or `promoted` (`persist:true` — connector-side, survives
reloads). The connector also auto-promotes a tool after 3 calls. **100% connector-side state — no file in
this repo sets it.** This doc records current classification + rationale so maintainers don't re-derive it.

Tool Loading mode: **Adaptive** (not "All tools" — 6 of ~52 tools are Obsidian-UI-active-file tools
irrelevant to headless MCP clients; not "Core set" — the connector's actual baseline doesn't include
`get_vault_file`/`patch_vault_file`/`set_note_property`, so every write/read would need an activation
round-trip first).

## Verification recipe

```
mcp__plugin_organon_organon__tool_catalog
```

Returns `{name, status: promoted|active|inactive, call_count}` per tool, vault-wide count (not per
client/session). Diff against the tables below; anything `promoted` that isn't in Tier A, or `inactive`
with rising `call_count` that isn't in Tier B, is drift — bring to PA, don't auto-resolve (see § No demote
mechanism).

## Tier A — persisted (`persist:true`, always loaded)

| Tool | Calls | Rationale |
|---|---|---|
| `get_vault_file_partial` | 490 | preferred partial-read, organon-vault-read |
| `get_vault_file` | 236 | last-resort full read, still heavy volume |
| `patch_vault_file` | 200 | heading/block/frontmatter patch |
| `search_and_replace` | 125 | scoped regex edit |
| `search_vault_simple` | 122 | keyword search fallback |
| `search_vault_smart` | 89 | semantic pre-filter, organon-session-discipline Rule 8 |
| `set_note_property` | 86 | atomic frontmatter write |
| `append_to_vault_file` | 67 | body write pattern |
| `list_vault_files` | 48 | NFC/troubleshooting, dir listing |
| `create_vault_file` | 46 | template persist step |
| `get_note_property` | 28 | atomic frontmatter read (pre-existing promotion, not itemised in #53) |
| `execute_template` | 12 | structured note creation |
| `get_server_info` | 6 | health check (pre-existing promotion, not itemised in #53) |
| `rename_vault_file` | 0 | link-safe rename — explicit skill dependency, organon-vault-write |
| `delete_note_property` | 0 | atomic frontmatter delete — explicit skill dependency |

## Tier B — on-demand (`inactive`, real skill dependency, `activate_tools(persist:false)` guard)

| Tool | Owning skill | Guard location |
|---|---|---|
| `get_files_by_tag`, `list_property_values`, `get_backlinks`, `get_outgoing_links`, `find_broken_links`, `find_orphaned_notes`, `execute_dataview_query`, `get_recent_files`, `get_vault_files` | organon-vault-read | `SKILL.md` §On-demand tools |
| `rename_heading`, `get_or_create_periodic_note`, `append_to_periodic_note`, `create_vault_directory`, `delete_vault_directory`, `delete_vault_file` | organon-vault-write | `SKILL.md` §On-demand tools |
| `get_canvas`, `add_canvas_node`, `connect_canvas_nodes` | organon-canvas | `canvas-author.md` step 0 (PR #55) |

All 18: no promotion evidence yet (0 calls). Deliberately not persisted — let real demand (auto-promote at
3 calls, or a future explicit `persist:true`) earn it, rather than assuming need up front. First-time
decision on the 3 canvas tools (raised in #53's comment): stay on-demand, not persisted — occasional use,
existing guard already covers the cost.

## Tier C — inactive, no dependency (leave alone)

`patch_active_file`, `delete_active_file`, `show_file_in_obsidian` — UI-active-file tools, irrelevant to
headless MCP clients. `create_vault_binary_file`, `get_vault_overview`, `get_note_outline`,
`list_bookmarks` — explicitly out of scope, `docs/plans/2026-05-31-issues-44-43-telemetry.md`.
`list_obsidian_commands`, `execute_obsidian_command` — not authorized, `organon-frontmatter/SKILL.md` §
Linter delegation. `fetch` — unrelated to vault.

No skill references Tier C. Keep it that way — the skill layer is what bounds auto-promotion; a tool
never called can't cross the 3-call threshold.

## No demote mechanism

`activate_tool`/`activate_tools` only promote — no exposed tool un-persists. If Tier A ever needs
shrinking, that's an out-of-repo action (Obsidian plugin's `data.json` or its settings UI), PA-only.

## Shared-counter caveat

`call_count` is vault-wide across every surface (Code/Cowork/Chat/Excel) — a speculative call from any one
of them counts toward auto-promotion everywhere. Route tool use through the documented skill decision
trees (organon-vault-read/write) and organon-session-discipline Rule 8, not ad hoc exploration.

## Provenance

Issue #53 shipped 6 deliberate persist promotions + noted 7 already-promoted-by-call-count. Its comment
flagged the 3 canvas tools and asked for a full data-driven optimization pass, deferred to a dedicated
session. This doc **is** that pass — Tier A/B/C above reflect a fresh evaluation against live
`tool_catalog` data, not an inherited assumption that the prior persisted set was already correct.
