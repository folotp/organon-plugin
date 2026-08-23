# Read tool matrix — intent → tool → cost class

Cost classes: **S** = single field/scalar (cheapest). **M** = single section/heading/block. **L** = full body. **XL** = body + dependent chain.

## By intent

| Intent | Tool | Cost | Notes |
|---|---|---|---|
| One frontmatter key | `get_note_property` | S | Atomic. No body read. |
| Enumerate key values vault-wide | `list_property_values` | S | Distinct values + counts. |
| Full frontmatter only | `get_vault_file_partial mode=frontmatter` | S | Strict parser — quoted scalars required. |
| One heading section | `get_vault_file_partial mode=heading` | M | Heading text must match exactly. |
| One block ref `^id` | `get_vault_file_partial mode=block` | M | Rejected if inside table cell or fenced block. |
| Heading outline (TOC) | `get_vault_file_partial mode=outline` | S | Heading tree only, no body. |
| Notes with a tag | `get_files_by_tag` | S | Optional nested-tag traversal. |
| Global tag list with counts | `list_tags` | S | Includes legacy namespaces — filter caller-side. |
| Who links to a note | `get_backlinks` | S | No embeds. |
| Where note links | `get_outgoing_links` | S | No embeds. |
| DQL filter / aggregation | `execute_dataview_query` | varies | In-process (0.7.0+). Requires Dataview plugin. |
| DQL/JsonLogic via REST | `search_vault` | varies | When in-process DQL unavailable. |
| Exploratory semantic search | `search_vault_smart` | S | Paths + scores only, no body. Top K then partial-read. |
| Keyword search with context | `search_vault_simple` | M | Short snippet windows. |
| Recently edited notes | `get_recent_files` | S | Heuristic, not semantic. |
| Full body | `get_vault_file` | L | Last resort. |
| Full body of 2+ known paths | `get_vault_files` | L (batched) | ≤ 20 paths/call, one round-trip. Per-path errors don't fail the batch. |
| Full body + every linked note | `get_vault_file` (loop) | XL | Almost always wrong — re-rank first. |

## Replacement table — old idiom → new canonical

| Old idiom | New canonical |
|---|---|
| `get_vault_file` then regex on frontmatter | `get_note_property` |
| `search_vault_simple "tag:foo"` | `get_files_by_tag{ tag: "foo" }` |
| Full read + scan for `[[X]]` references | `get_backlinks{ path: "X" }` |
| Manual scan for heading `## Section` | `get_vault_file_partial mode=heading target="Section"` |
| `get_vault_file` to confirm block ref exists | `get_vault_file_partial mode=block target="<id>"` (errors if absent) |
| `search_vault_simple` then full reads of every hit | `search_vault_smart` → top 3 → partial reads |
| Manual DQL via REST | `execute_dataview_query` (if Dataview installed) |
| Loop `get_vault_file` over a known path list | `get_vault_files{ paths }` (≤ 20 per call) |

## Quick rules of thumb

- **One field → one S call.** Don't escalate past S unless enclosing context also needed.
- **Search before reading.** `search_vault_smart` returns paths only; 3 partial reads cost less than 1 full body of wrong note.
- **Backlinks aren't bodies.** `get_backlinks` = path list = graph query, not content fetch.
- **Outline first on big notes.** `mode=outline` (S) reveals right `mode=heading target=…` to call next.
