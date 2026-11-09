---
name: organon-vault-read
description: "Use before any MCP read against the Organon vault (path contains `Organon`) when the target path is not already hardcoded by another skill or given verbatim by PA. Routes the read to the cheapest tool that returns enough information — atomic frontmatter (`get_note_property`), partial reads (`get_vault_file_partial` modes: frontmatter / heading / block / document-map), graph nav (`get_backlinks`, `get_outgoing_links`), tag and property indexes (`list_tags`, `get_files_by_tag`, `list_property_values`), search (`search_vault_smart` → `search_vault_simple` fallback, `search_vault` DQL/JsonLogic, `execute_dataview_query` in-process), or `get_recent_files`. Reserves full `get_vault_file` for cases where the entire body is genuinely required."
license: MIT
compatibility: Requires the Organon MCP connector.
---

# organon-vault-read

Tool names are bare. Match them to the Organon connector's tools in your tool list, whatever prefix your platform adds.

Token-minimisation for vault reads. Mirror of `organon-vault-write`. Assume cheaper read exists; reach for full `get_vault_file` only after decision tree rules out every partial path.

Unfamiliar key → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`.

## Decision tree — cheapest tool first

Apply in order; first match wins.

1. **Single frontmatter key, known path?** → `get_note_property{ path, key }`.
2. **Enumerate values of a key vault-wide?** → `list_property_values{ key }`. Distinct values + counts; no body read.
3. **Frontmatter block only?** → `get_note_properties{ path }`. One JSON object, native YAML types, from the metadata cache. The canonical whole-frontmatter read; `get_vault_file_partial mode=frontmatter` reads one field only.
4. **Single heading section?** → `get_vault_file_partial{ filename, mode: "heading", target: "<heading text>" }`.
5. **Single block ref (`^id`)?** → `get_vault_file_partial{ filename, mode: "block", target: "<id>" }`.
6. **Heading outline (TOC) only?** → `get_vault_file_partial{ filename, mode: "document-map" }`. Also lists block ids, frontmatter keys.
7. **All notes with a tag?** → `get_files_by_tag{ tag, includeNested? }`.
8. **Global tag list with counts?** → `list_tags`.
9. **Who links to a note?** → `get_backlinks{ path }`.
10. **Where does a note link?** → `get_outgoing_links{ path }`.
11. **DQL filter (TABLE / LIST / TASK)?** → `execute_dataview_query{ query }` (in-process, 0.7.0+). Prefer over `search_vault` when Dataview installed — same expressivity, no REST dependency.
12. **JsonLogic / DQL via REST?** → `search_vault{ query }`. Only when `execute_dataview_query` unavailable.
13. **Exploratory — don't know which note?** → `search_vault_smart{ query }`. Read plausible paths in rank order (folder + title check); follow with cheapest partial-read from rules 1-6. Fallback if provider not ready: `search_vault_simple`. See `organon-session-discipline` Rule 8.
14. **Keyword search with context windows?** → `search_vault_simple{ query }`.
15. **Recently edited notes?** → `get_recent_files{ limit? }`. Context heuristic only — never primary semantic filter.
16. **Size, dates or link counts, no body?** → `get_file_info{ path }`. Size check before deciding full vs chunked read.
17. **Tasks (`- [ ]`) across vault, folder or note?** → `list_tasks`. Metadata cache; no body read.
18. **Folder structure / attachments?** → `list_vault_folders` or `get_vault_tree` (incl. empty folders); `list_attachments` (non-note files, vault-wide, under a folder, or linked from one note).
19. **Full body of 2+ known paths (sweep, refactor wave, comparison)?** → `get_vault_files{ paths }` (≤ 20 per call, text or json format). One round-trip instead of N `get_vault_file` calls; a missing/binary/folder path errors per-entry without failing the rest.
20. **Genuinely need full body of one note?** → `get_vault_file{ path }`. Acceptable: (a) single-note refactor touching multiple sections, (b) faithful quotation, (c) note < ~80 lines where partial overhead dominates. Large or unknown size → `document-map`, then `mode=lines` windows: the connector truncates text past its size ceiling.

See `references/READ_TOOL_MATRIX.md` for cost-class table.

## Adaptive tool loading — canonical (read + write)

Connector exposes only `active`/`promoted` tools. Inactive → absent from your tool list, not broken.
`activate_tools{ names }` promotes connector-side: `persist:false` (default) until Obsidian reloads,
`persist:true` permanent. Auto-promotes at 3 calls. Idempotent.

Client sees the change only if it re-fetches the tool list (`tools/list_changed`). Hosted clients don't
mid-session: activation succeeds, tool stays missing. It appears from the next session on. Cause:
client-side refresh + connector notifies only the caller's request stream (`docs/mcp-tool-loading.md`
§Hosted-client caveat). Claude branch: claude.ai-hosted connector never refreshes, Code and cloud,
subagents included (`No such tool available`).

Inactive by default (Tier B, `docs/mcp-tool-loading.md`): `find_orphaned_notes`, `get_file_info`,
`list_tasks`, `list_attachments`, `get_vault_tree`.

Tool needed, not in your list:

1. `activate_tools{ names: [...needed] }` once, `persist:false`. Never `persist:true` unasked — PA decides.
2. Appears → use it.
3. Still missing → don't retry, don't probe `tool_catalog`. Use the fallback below, tell PA in one line
   that the tool is active from the next session.
4. `activate_tools` itself absent → read-only or restricted token; fallback only.

| Missing | Fallback |
|---|---|
| `get_note_properties` | `document-map` (keys) → `get_note_property` per key |
| `get_file_info` | `document-map`; size unknown → chunked `mode=lines` reads |
| `list_tasks` | `search_vault_simple{ query: "- [ ]" }` scoped to folder |
| `list_vault_folders` / `get_vault_tree` / `list_attachments` | `list_vault_files{ directory }` per level |
| `find_orphaned_notes` | `get_backlinks` on candidates; vault-wide → report unavailable |

Write-side fallbacks: `organon-vault-write` §On-demand tools.

## Integrity / graph-health scans

Two vault-wide scan tools — not per-target reads. `find_orphaned_notes` inactive by default, see §Adaptive tool loading above. Use
these instead of looping `get_outgoing_links` over every note when checking whole-vault health.

- **`find_broken_links`** — scans the full vault for unresolvable links (wiki / embed / frontmatter). Per broken link: source path, 1-based line number, link type, and raw syntax. No arguments required; returns immediately.
- **`find_orphaned_notes`** — lists notes with zero incoming links. `exclude_folders` filters the **output** only; all notes are still scanned internally. Useful as a first pass before deciding whether an isolated note is intentional or lost.

Both are cheaper than an ad-hoc `get_outgoing_links` loop and produce structured, actionable output in a single call.

## Output shape reminders

- `search_vault_smart` returns path, score, start line and a chunk excerpt per hit. Path-filter use: `compact:true` (path + score only) or `excerptLength:<n>`; `groupByFile:true` → one hit per note, `limit` counts notes.
- `search_vault_simple` returns paths + short context windows.
- `get_vault_file_partial mode=frontmatter target=<key>` returns single field; `target` required. Whole block → `get_note_properties`.
- `get_note_property` returns raw scalar/array. JSON-array fields (`tags`, `aliases`, `references`) come back as arrays.

## NFC normalisation (read-side)

Same as `organon-vault-write`: apply NFC to every path/title with accented characters before any MCP call. On 404 for a path that should exist: try NFC variant → `list_vault_files` parent → byte-compare. Common offenders: `é`, `à`, `ç`, `œ`.

## YAML quoting — partial-read parser

`get_vault_file_partial mode=frontmatter` uses strict parser that rejects unquoted scalars containing `:`. If partial read returns "File has no frontmatter" on a note that has one, suspect unquoted scalar with `:`. Fix: `set_note_property` with quoted value (or `patch_vault_file targetType:frontmatter` rewrite). Write-side risk retired in mcp-tools-istefox 0.4.x — strict parser bites only on partial reads now.

## Footguns

- `search_vault_smart` can return `"not ready"` (Smart Connections cold) or time out (bridge hang). Always have `search_vault_simple` fallback; never make smart-search a hard prerequisite.
- `get_vault_file_partial mode=heading` is heading-text-sensitive. Pass exactly as it appears in body (em-dashes, accents included). On miss, fall back to `get_vault_file_partial mode=document-map` to discover actual text.
- `execute_dataview_query` requires Dataview plugin in Obsidian. On "Dataview not available" error, route to `search_vault` (JsonLogic).
- `get_outgoing_links` includes embeds by default (`embed: true` per entry); `includeEmbeds:false` → regular links only. Also returns frontmatter links (`layer`).
- Inactive tools aren't in your list at all — follow §Adaptive tool loading, don't guess names.
- `list_tags` includes legacy `notetype/*`, `statut/*`, `source/*`, `domain/*`, `topic/*` namespaces — filter caller-side per `organon-frontmatter` § Legacy namespaces.
- **Recurring param-name mistake**: `path` (not `filename`/`filepath`) on single-file tools, except `get_vault_file_partial` → `filename`; `directory` (not `folder`) on `list_vault_files`. Guessing the wrong key fails loud (*"Key '…' does not exist on schema"*) — check the tool's actual schema rather than pattern-matching from a different tool.

## Anti-patterns

- Full `get_vault_file` to inspect one key → use `get_note_property`.
- Loop `get_vault_file` over N candidates from `search_vault_simple` → re-rank via `search_vault_smart`, partial-read plausible matches.
- Manual regex on full body to extract heading → use `get_vault_file_partial mode=heading`.
- Pre-fetch every backlink body when only count matters → `get_backlinks` returns list; partial-read only what matters.

## Cross-references

- Write side: `organon-vault-write`.
- Exploratory pre-filter: `organon-session-discipline` Rule 8.
- Frontmatter schema: `organon-frontmatter`.
- Cost-class table: `references/READ_TOOL_MATRIX.md`.
