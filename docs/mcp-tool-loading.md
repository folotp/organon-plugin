# MCP tool loading — persisted vs on-demand vs unused

The istefox connector (`organon-claude.folot.net`) uses adaptive tool loading: every tool starts `inactive`.
`activate_tool`/`activate_tools` promotes a tool to `active` (`persist:false`, default — in-memory,
connector-process-scoped, lost on restart/reload) or `promoted` (`persist:true` — connector-side, survives
reloads). The connector also auto-promotes a tool after 3 calls. **100% connector-side state — no file in
this repo sets it.** This doc records current classification + rationale so maintainers don't re-derive it.

Tool Loading mode: **Adaptive** (not "All tools" — 63 tools, several Obsidian-UI-active-file tools
irrelevant to headless MCP clients; not "Core set" — the connector's actual baseline doesn't include
`get_vault_file`/`patch_vault_file`/`set_note_property`, so every write/read would need an activation
round-trip first).

Scope: this doc covers Claude's token. Each agent has its own host and token (`organon-claude`, `organon-chatgpt`, `organon-gemini`), each with its own tool set. ChatGPT and Gemini are read-only for now.

## Verification recipe

```
tool_catalog
```

Prefix: `mcp__claude_ai_organon__*` (Code/Desktop) or `mcp__organon__*` (claude.ai cloud). Same connector, same state.

Returns `{name, status: promoted|active|inactive, call_count}` per tool, vault-wide count (not per
client/session). Diff against the tables below; anything `promoted` that isn't in Tier A, or `inactive`
with rising `call_count` that isn't in Tier B, is drift — bring to PA, don't auto-resolve (see § No demote
mechanism).

## Tier A — loaded (`promoted` or baseline `active`)

Snapshot: connector v3.3.0, `tool_catalog` 2026-11-09. `promoted` covers both deliberate `persist:true`
(#53) and auto-promotion at 3 calls; the catalog doesn't distinguish them.

| Tool | Status | Owning skill |
|---|---|---|
| `get_vault_file_partial`, `get_vault_file`, `get_vault_files`, `get_note_property`, `get_note_properties` | promoted | organon-vault-read |
| `list_vault_folders` | promoted (auto, #121 probe 2026-11-09) | organon-vault-read |
| `search_vault_simple`, `search_vault_smart`, `search_files_by_name`, `list_vault_files` | promoted | organon-vault-read, session-discipline Rule 8 |
| `get_outgoing_links`, `get_backlinks`, `find_broken_links`, `get_files_by_tag`, `list_property_values`, `get_recent_files`, `execute_dataview_query` | promoted (auto) | organon-vault-read |
| `patch_vault_file`, `search_and_replace`, `set_note_property`, `delete_note_property`, `append_to_vault_file`, `create_vault_file`, `execute_template`, `rename_vault_file`, `rename_heading` | promoted | organon-vault-write |
| `get_server_info` | promoted | health check, memory-audit probe |
| `get_canvas`, `add_canvas_node`, `connect_canvas_nodes`, `update_canvas_node`, `delete_canvas_node` | promoted (`persist:true`, 2026-11-08) | organon-canvas via `canvas-author` |
| `delete_vault_file`, `delete_vault_directory` | promoted (`persist:true`, 2026-11-09, #121) | organon-vault-write; PA confirms every delete (session-discipline Rule 1) |
| `list_tags`, `search_vault`, `tool_catalog`, `activate_tool`, `activate_tools` | active (baseline) | — |

## Tier B — on-demand (`inactive`, real skill dependency, `activate_tools(persist:false)` guard)

| Tool | Owning skill | Guard location |
|---|---|---|
| `find_orphaned_notes`, `get_file_info`, `list_tasks`, `list_attachments`, `get_vault_tree` | organon-vault-read | `SKILL.md` §Adaptive tool loading |
| `update_note_properties`, `rename_tag`, `ensure_block_id`, `set_task_status`, `create_vault_directory` | organon-vault-write | `SKILL.md` §On-demand tools |

**Hosted-client caveat (diagnosed 2026-11-09, #121):** hosted clients fix their tool list at session (and
subagent) start. `activate_tools` succeeds connector-side, the tool never appears (`No such tool
available`); usable from the next session on. Two independent causes:

| Layer | Defect | Upstream |
|---|---|---|
| claude.ai-hosted connector path (Claude Code local + cloud) | Ignores `tools/list_changed` on both delivery paths — activation POST stream and `subscriptions/listen`. Even a correctly delivered listen-stream notice (auto-promotion fan-out, verified on the wire) doesn't refresh the session. | anthropics/claude-code#108596 |
| Connector 3.3.0 | Explicit `activate_tool`/`activate_tools` notify only on the caller's POST stream, never via `subscriptions/listen` fan-out. Modern-era (`2026-07-28`) clients get nothing. Auto-promotion does fan out. | istefox/obsidian-mcp-connector#669 |

Cleared: Cloudflare Access/Worker/tunnel (passes the notice intact). Claude Code direct to the local
transport (`claude mcp add --transport http`, 127.0.0.1) refreshes in ~2 s — Mac-only, not a general fix.
ChatGPT/Codex apps: same symptom (run E); listen-stream behaviour untested.

Workaround: `persist:true` for any tool a session or subagent needs dependably (done: 5 canvas tools, 2
delete tools). Skill procedure + per-tool fallbacks: `organon-vault-read` §Adaptive tool loading.

Otherwise deliberately not persisted — let real demand earn promotion. Skills also carry a drift rule: a tool missing
from the client's list → `activate_tools` before concluding it's unavailable, so a stale tier here costs one
idempotent call, not a failure.

## Tier C — inactive, no dependency (leave alone)

`show_file_in_obsidian` — UI, irrelevant to headless clients. `create_vault_binary_file`,
`get_vault_overview`, `list_bookmarks` — out of scope, `docs/plans/2026-05-31-issues-44-43-telemetry.md`.
`get_note_outline` — `get_vault_file_partial mode=document-map` covers it (adds block ids + frontmatter
keys); `promoted` since the #121 probe (2026-11-09, test calls), still no skill dependency. `list_obsidian_commands`, `execute_obsidian_command` — not authorized, `organon-frontmatter/SKILL.md`
§ Linter delegation.

`unavailable` on this token (no skill may route to them): `get_active_file`, `update_active_file`,
`append_to_active_file`, `patch_active_file`, `delete_active_file`, `get_workspace_state`,
`get_or_create_daily_note`, `get_or_create_periodic_note`, `append_to_periodic_note`, `fetch`.

No skill references Tier C. Keep it that way — the skill layer is what bounds auto-promotion; a tool
never called can't cross the 3-call threshold.

## Connector 3.3.0 assessment (#87)

New since the last pass, and what changed in the skills:

| Tool / schema change | Skill change |
|---|---|
| `get_note_properties` (whole frontmatter, metadata cache) | Canonical whole-frontmatter read everywhere (#112). Upstream `get_note_property` description still points to `get_vault_file_partial mode=frontmatter` — stale, that mode reads one field (upstream istefox/obsidian-mcp-connector#668). |
| `update_note_properties` (multi-key atomic write) | Replaces looping `set_note_property` for 2+ keys on one note; touch-on-edit migrations, BUG→INC back-links. |
| `rename_tag`, `ensure_block_id`, `set_task_status` | Added to organon-vault-write with guardrails (PA confirm for vault-wide rename; no systematic anchors). |
| `get_file_info`, `list_tasks`, `list_attachments`, `list_vault_folders`, `get_vault_tree` | Added to organon-vault-read decision tree. |
| `update_canvas_node`, `delete_canvas_node` | Canvas runbook + `canvas-author` allowlist. |
| `search_vault_smart` excerpts (`excerptLength`, `compact`, `groupByFile`) | Read guidance and Rule 8 no longer claim paths-only (#112). |
| `get_outgoing_links` embeds + frontmatter links by default (`includeEmbeds`) | "No embeds" footgun removed (#112). |
| `get_vault_file` truncates past its size ceiling | Chunked-read rule in all three subagents (#115). |

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
