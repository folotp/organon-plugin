---
name: organon-vault-write
description: Use before any MCP write against the Organon vault (path contains `Organon`) — `set_note_property` / `delete_note_property` / `update_note_properties` for atomic frontmatter, `patch_vault_file` / `create_vault_file` / `append_to_vault_file` for body, `rename_heading` / `rename_vault_file` for link-safe rename, `execute_template` for structured shapes. Mandates atomic-always frontmatter writes, canonical template paths (BL/BUG/INC/ADR + Note/Concept/Person/Book/Quote/Index/Organization), heading-patch safety incl. fenced-code H2 trap, EJS-literal Templater invariants, NFC normalisation.
license: MIT
compatibility: Requires the Organon MCP connector.
---

# organon-vault-write

Tool names are bare. Match them to the Organon connector's tools in your tool list, whatever prefix your platform adds.

Write tools missing → say writes aren't available, then show the full draft in chat (complete frontmatter + body). No other route: don't probe `tool_catalog` / `activate_tools` for write tools, don't save the draft to a local file or elsewhere. Drafting a note, even without writing it → load `organon-frontmatter` first.

Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`. Read-side → `organon-vault-read`.

## MCP write-tool surface (connector ≥ 3.3.0)

| Tool | Use for | Notes |
|---|---|---|
| `set_note_property` | Add/update single frontmatter key | Atomic. Bypasses full-frontmatter revalidation. Preferred over `patch_vault_file targetType:frontmatter`. |
| `delete_note_property` | Remove single frontmatter key | Atomic. |
| `update_note_properties` | Set and/or remove several keys on one note | One atomic write, one file version, one undo step. Preferred over looping `set_note_property` for 2+ keys on the same note. |
| `patch_vault_file` | Heading / block / multi-key frontmatter rewrite | `targetType`: `heading` \| `block` \| `frontmatter`. `operation` REQUIRED, **no default** — `replace`/`append`/`prepend`. Prefer atomic tools for frontmatter. Heading/block patches and `replace` have edge cases — `references/EDGE_CASES.md`. |
| `search_and_replace` | Regex find/replace, vault-wide or scoped | `dry_run:true` is the **default** safety gate — pass `false` to apply. `g` flag always injected. ReDoS-guarded. Scope via `scope`. |
| `create_vault_file` | Create note with full content | Auto-creates missing parent dirs (≥ 0.4.5). |
| `append_to_vault_file` | Append raw content to existing note | Caller responsible for idempotency. |
| `rename_heading` | Rename heading + update all vault refs | Link-safe. Replaces patch + manual sweep. |
| `rename_vault_file` | Rename file + preserve all incoming links | Link-safe. Replaces filesystem rename + sweep. |
| `rename_tag` | Rename a tag vault-wide | Inline `#tag` + `tags:` frontmatter, nested tags follow. Skips code blocks/URLs. Vault-wide blast radius → confirm with PA first. |
| `ensure_block_id` | Get or create a `^block-id` | Returns existing id if present. Only for a link PA asked for — no systematic anchors (`organon-markdown-style`). |
| `set_task_status` | Tick/untick one task | Only the `[ ]` status char changes. Replaces patch on task lines. |
| `execute_template` | Render Templater template | `createFile:false` → returns rendered string; `createFile:true` → creates file at `targetPath`. `arguments` is `{string:string}`. |
| `get_or_create_daily_note` / `get_or_create_periodic_note` | Ensure + return periodic note | Idempotent. `unavailable` on connector; confirm via `tool_catalog`. |
| `append_to_periodic_note` | Append to periodic note (today or specified) | `unavailable` on connector; confirm via `tool_catalog`. |
| `create_vault_directory` / `delete_vault_directory` / `delete_vault_file` | Filesystem ops | `delete_vault_file` requires explicit filename — never `delete_active_file`. |

## On-demand tools

Mechanism + 4-step procedure: `organon-vault-read` §Adaptive tool loading. Applies only to the tools below —
core write tools (`set_note_property`, `patch_vault_file`, `create_vault_file`, …) missing = read-only token,
see top; don't activate.

Inactive by default (Tier B): `update_note_properties`, `rename_tag`, `ensure_block_id`, `set_task_status`,
`create_vault_directory`, `delete_vault_directory`, `delete_vault_file`.

| Missing after activation | Fallback |
|---|---|
| `update_note_properties` | loop `set_note_property` / `delete_note_property` |
| `rename_tag` | `search_and_replace` on `#tag` (dry run first) + `tags:` per note; confirm scope with PA |
| `set_task_status` | `search_and_replace` scoped to the note, pattern anchored on the task text |
| `ensure_block_id` | Only if PA asked for the anchor: scoped `search_and_replace`, pattern = the paragraph's unique last line (`$`-anchored, `m` flag), replacement appends ` ^<id>`; dry run must show exactly 1 match. Not unique → report anchor creation unavailable. Block patches can't help: they need an existing `^id` |
| `create_vault_directory` | none needed — `create_vault_file` creates parents |
| `delete_vault_file` / `delete_vault_directory` | none — ask PA to delete in Obsidian |

## Atomic-always for frontmatter (canonical)

Use atomic tools (`set_note_property`, `delete_note_property`, `update_note_properties`) over `patch_vault_file targetType:frontmatter`. Two reasons:

1. **Safer.** Keys updated in place via `processFrontMatter`; malformed scalar elsewhere doesn't block the edit.
2. **Cheaper.** Payload carries only the changed keys vs JSON-encoded full-frontmatter rewrite.

Multi-key edits on one note: `update_note_properties` (one write, one undo step) — check its schema for the set/remove params. Tool unavailable → loop `set_note_property` / `delete_note_property`.

`patch_vault_file targetType:frontmatter` retained for: (a) bulk rewrite reshaping an entire key set, (b) legacy toolchains pinned below 0.6.0.

## Wire format reminders

### `set_note_property`

```json
{ "path": "Folder/Note.md", "key": "status", "value": "active" }
```

Arrays: pass real JSON array.

```json
{ "path": "Folder/Note.md", "key": "tags", "value": ["source/ia", "domain/tooling"] }
```

### `patch_vault_file targetType:frontmatter` (when needed)

`content` must be JSON-encoded string, not object. Internal double-quotes escaped as `\"`.

```json
{ "content": "\"Value with : colon\"", "contentType": "application/json" }
```

### `search_and_replace` (scoped regex edit)

Preferred for find/replace across one or many notes. `dry_run:true` is the **default** safety gate — it returns a match preview without mutating; pass `false` to apply. The `g` flag is always injected (all occurrences). ReDoS-guarded. Scope with `scope` (vault-relative paths or folder prefixes) to avoid vault-wide blast radius.

```json
{ "pattern": "old-token", "replacement": "new-token", "scope": ["Folder/Note.md"], "dry_run": false }
```

**Anti-pattern (retired):** read full body → build a manual regex → `patch_vault_file`. Use scoped `search_and_replace` instead — fewer calls, no re-emission of the body, built-in dry-run.

## Canonical template paths (Templater-first routing)

All structured shapes route through **active, domain-parameterised** templates. Templater resolves the ULID and sequential ID **server-side** — the session never computes them (no `list_vault_files` max-id dance, no manual ULID one-liner). The legacy `VLT-*-template.md` files are deprecated duplicates (archived under `99 - Méta/Templates/Déprécié/`); do not route to them.

Two routing classes, split by **how the filename is determined**:

### Auto-ID shapes — render-then-create (BL/BUG/INC/ADR)

| Shape | Template path |
|---|---|
| VLT-BL / SD-BL | `99 - Méta/Templates/BL-template.md` |
| VLT-BUG | `99 - Méta/Templates/BUG-template.md` |
| VLT-INC | `99 - Méta/Templates/INC-template.md` |
| VLT-ADR / SD-ADR | `99 - Méta/Templates/ADR-template.md` |

The filename **is** the id (`VLT-BL-0031.md`), and the id is generated *during* render — so the target path is unknown until after rendering. **In MCP mode the active templates do NOT self-relocate** (their `tp.file.move` runs in UI mode only). Two calls:

1. **Render to inspect** — `execute_template{ templatePath, arguments:{ domain:"VLT", titre:"<summary, no code>", id:"", … } }` with **no** `createFile` and **no** `targetPath`. Returns the rendered markdown string with `id:` + `ulid:` already resolved server-side. Read the `id:` from its frontmatter.
2. **Persist** — `create_vault_file{ path:"<cfg folder>/<id>.md", content:<the exact string from step 1> }`.

**Never run a second `execute_template` (`createFile:true`) to do step 2** — re-rendering regenerates the ULID and re-resolves `next_id`, yielding a *different* id/ulid than you inspected. Persist the captured render via `create_vault_file`. This is the #44 fix: the old static-gabarit path forced a manual ULID one-liner + `list_vault_files` max-id discovery (~5 calls); now it is one render + one create with zero manual ID work.

### Title-named shapes — one-step (`createFile:true`)

| Shape | Template path |
|---|---|
| Note | `99 - Méta/Templates/Note template.md` |
| Concept | `99 - Méta/Templates/Concept template.md` |
| Person | `99 - Méta/Templates/Person template.md` |
| Book | `99 - Méta/Templates/Book template.md` |
| Quote | `99 - Méta/Templates/Quote template.md` |
| Index | `99 - Méta/Templates/Index template.md` |
| Organization | `99 - Méta/Templates/Organization template.md` |
| Note de session de psychothérapie | `99 - Méta/Templates/Note de session de psychothérapie.md` |
| Note de journal personnel | `99 - Méta/Templates/Note de journal personnel.md` |
| Note de bilan personnel | `99 - Méta/Templates/Note de bilan personnel.md` |

Filename derives from the title, so the caller knows `targetPath` up front — render-and-create in one call:

```js
execute_template({
  templatePath: "99 - Méta/Templates/Note template.md",
  targetPath: "<folder>/<title>.md",
  createFile: true,
  arguments: { /* {string:string}, forwarded via tp.user.mcpTools.prompt(argName) */ }
})
```

Templater writes Linter-ordered frontmatter, `creator:` + `source/ia` (dual-mode via `tp.mcpTools`), `modified:`, and the full body skeleton. The prelude literal is `Claude`, so other agents, in either routing class, render without `createFile`, correct `creator:` per `organon-frontmatter`, then `create_vault_file` the result. Do not `create_vault_file` ad-hoc from a hand-built skeleton — bypassing the template re-implements upstream work and risks subtle divergence.

### Supersession — dedicated (`Supersede-ADR-template.md`)

Fits neither routing class above: it consumes a sequential ID **and** patches an existing source fiche. Covers `VLT-ADR`, `SD-ADR`, `FIN-DEC` — per `SD-ADR-011`, complete supersession is the only valid pattern for modifying an `accepted` ADR or FIN-DEC.

Path: `99 - Méta/Templates/Supersede-ADR-template.md`. Three-call MCP sequence (per the template's own header comment, SD-ADR-008 §Workflow MCP canonique):

1. `execute_template{ templatePath:"99 - Méta/Templates/Supersede-ADR-template.md", arguments:{ source, titre, status?, topic? }, createFile:false }` — `source` (wikilink/basename of the fiche to supersede, required), `titre` (new fiche summary, no code, required), `status` (`proposed` | `accepted`, default `proposed`), `topic` (default depends on shape).
2. Read `id:` from the rendered frontmatter.
3. `create_vault_file{ path:"<canonical_folder>/<id>.md", content:<rendered> }`.

**Divergence from the auto-ID class above**: step 1 already patches the *source* fiche in place (`status → superseded`, `superseded-by` set, `modified` bumped, superseded callout inserted) as a side effect of rendering — even with `createFile:false`. It is not a pure/inspect-only render; there is no dry-run. Idempotent: re-running against an already-`superseded` source silently no-ops on the source (a warning callout appears in the new fiche's body instead of an error).

### Per-shape arguments

| Shape | Required | Optional / defaulted |
|---|---|---|
| BL (VLT-BL / SD-BL) | `titre` | `priority` (default `medium`), `origin` (default `misc`), `linked_bug` (conditional) |
| BUG (VLT-BUG) | `titre` | `severity` (default `minor`), `component`, `first_incident`, `last_occurrence` |
| INC (VLT-INC) | `titre`, `surface`, `layer`, `tool`, `operation` | — |

**INC `surface` is controlled-vocab** — allowed: `claude-ai-web`, `claude-ai-mobile`, `cowork`, `desktop-chat`, `dispatch`, `claude-code`, `chatgpt`, `codex`, `gemini` (full list: `organon-frontmatter` `references/VOCABULARIES.md`). Any other value fails-loud server-side (*"value '…' is not in the controlled vocabulary"*). Map the session's surface; don't pass freeform.

**BUG post-create side-effect (manual).** Templater can't mutate sibling notes. After creating a BUG, each linked incident still needs `bug:` set + `status: assigned` applied afterward (one `update_note_properties` per incident note).

## Templater invariants (when authoring or debugging a template)

1. **Every fenced JS block must close correctly, with `-%>` (not `%>`).** Mismatched `<% … %>` brackets corrupt render and can leave file unsaved.
2. **`tp.user.*` helpers live in `99 - Méta/Templates/scripts/`.** Confirm helper exists before referencing.
3. **MCP-mode detection via `tp.mcpTools`.** Use dual-mode prelude (current literal, Claude-only: `if (tp.mcpTools) { creator = "Claude"; tags.push("source/ia") } else { creator = "Pierre-André Folot" }`).
4. **Sequential IDs via `tp.user.next_id(<prefix>, <folder>)`.** Never invent IDs client-side for active-Templater shapes.
5. **No EJS literals inside JS comments inside a Templater block.** EJS parser interprets `<%`, `%>`, `-%>`, `<%*` **even inside `//` or `/* */` comments**. Commented-out example tag still terminates surrounding block. Break across two strings (`"<" + "%"`) or move example outside the Templater block.
6. **Title via arg, not `tp.file.title`.**
7. **Template pre-exists in vault.**
8. **Output is Linter-compliant** (key order, apostrophes, no trailing whitespace).

## YAML quoting rules

- IF frontmatter scalar contains `: # & * ! | > ' " % @ \``: quote with `"…"`.

**Why:** `get_vault_file_partial mode=frontmatter` strict parser rejects unquoted scalars with `:` (returns `"File has no frontmatter"`). Patch-side risk retired in mcp-tools-istefox 0.4.x, but partial-read path and strict-YAML consumers still require quoted scalars. `set_note_property` quotes correctly by construction when `value` is JSON string.

## Frontmatter array vs scalar (atomic and patch)

- `tags:`, `aliases:`, `references:` are arrays. With `set_note_property`, pass JSON array as `value`. With `patch_vault_file`, pass `"content": "[\"a\", \"b\"]"`.
- Scalar field with `patch_vault_file`: pass `"content": "\"some value\""`.
- Type mismatch: fail-loud (no silent coercion since istefox 0.4.0).
- `append`/`prepend` on `patch_vault_file` auto-wraps bare scalar into array element on array fields. With atomic tools: `get_note_property` → mutate → `set_note_property`.

## Tags shape

- `tags:` must be array of strings — never number, `null`, bare date, or empty scalar.
- No tags: omit key, or `tags: []`.
- **Why:** YAML 1.1 silently parses `tags: 4` as `[Number(4)]`; plugins calling `.startsWith()` crash.

## Edge cases — write precondition & heading-patch safety

Doing a heading/block patch or a `replace` operation → `references/EDGE_CASES.md` first: `expectedContent` discipline (when "Require a write precondition" is on), the fenced-code H2 trap (VLT-BUG-0022), duplicate-heading disambiguation, and the recurring write-tool param-name footgun (`path` not `filename`/`filepath`/`folder`).

## Renaming — prefer the link-safe tools

| Intent | Tool | Why |
|---|---|---|
| Rename heading + update all `[[Note#Heading]]` refs | `rename_heading` | Vault-wide sweep by connector. Replaces patch + manual `[[…#…]]` grep. |
| Rename file + preserve all `[[Name]]` | `rename_vault_file` | Incoming links rewritten. Replaces filesystem rename + sweep. |
| Move file across folders | `rename_vault_file` with new path | Same link preservation. |
| Rename tag everywhere | `rename_tag` | Replaces `search_and_replace` on `#tag` + per-note `tags:` edits. |

Do not rename via `create_vault_file` + `delete_vault_file` — breaks all incoming `[[…]]`.

`rename_heading` inactive by default — see §On-demand tools.

## NFC normalisation

- Apply NFC to every path/title with accented characters before any MCP call.
- 404 on path that should exist: try NFC variant → `list_vault_files` parent → byte-compare → log VLT-INC.

## Footguns

- MCP write followed by manual UI save can be overwritten by Obsidian's re-import. Wait for "Re-import" banner to clear before saving in UI.
- Do not pre-create parent dirs; `create_vault_file`, `append_to_vault_file`, `execute_template` auto-mkdirp since 0.4.5.
- No "verify MCP is alive" ping before writes. Let real call surface failures; retry only on abnormal signals.
- `patch_vault_file` `operation` is **required, no default** — omit it and the call is rejected (*"operation must be 'append','prepend' or 'replace' (was missing)"*). Always pass `replace`/`append`/`prepend`.
- **mcp-tools-istefox has NO bash tool.** Run shell through your platform's own shell tool, if it has one.
- `get_vault_file` timeout / *"server unavailable"* is an **abnormal signal** → retry once before escalating to PA.
- Inactive tools aren't in your list at all — follow §On-demand tools, don't guess names.

Frontmatter schema → `organon-frontmatter`. Body prose → `organon-markdown-style`. Read-side → `organon-vault-read`.
