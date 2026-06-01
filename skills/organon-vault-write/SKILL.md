---
name: organon-vault-write
description: Use before any MCP write against the Organon vault (path contains `Organon`) — `set_note_property` / `delete_note_property` for atomic frontmatter, `patch_vault_file` / `create_vault_file` / `append_to_vault_file` for body, `rename_heading` / `rename_vault_file` for link-safe rename, `execute_template` for structured shapes. Mandates atomic-always frontmatter writes, canonical template paths (BL/BUG/INC/ADR + Note/Concept/Person/Book/Quote/Index/Organization), heading-patch safety incl. fenced-code H2 trap, EJS-literal Templater invariants, NFC normalisation.
---

# organon-vault-write

Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`. Read-side → `organon-vault-read`.

## MCP write-tool surface (mcp-tools-istefox ≥ 0.8.0)

| Tool | Use for | Notes |
|---|---|---|
| `set_note_property` | Add/update single frontmatter key | Atomic. Bypasses full-frontmatter revalidation. Preferred over `patch_vault_file targetType:frontmatter`. |
| `delete_note_property` | Remove single frontmatter key | Atomic. |
| `patch_vault_file` | Heading / block / multi-key frontmatter rewrite | `targetType`: `heading` \| `block` \| `frontmatter`. `operation` REQUIRED, **no default** — `replace`/`append`/`prepend`. Prefer atomic tools for frontmatter. |
| `search_and_replace` | Regex find/replace, vault-wide or scoped | `dry_run:"true"` is the **default** safety gate — pass `"false"` to apply. `g` flag always injected. ReDoS-guarded. Scope via `scope`. |
| `create_vault_file` | Create note with full content | Auto-creates missing parent dirs (≥ 0.4.5). |
| `append_to_vault_file` | Append raw content to existing note | Caller responsible for idempotency. |
| `rename_heading` | Rename heading + update all vault refs | Link-safe. Replaces patch + manual sweep. |
| `rename_vault_file` | Rename file + preserve all incoming links | Link-safe. Replaces filesystem rename + sweep. |
| `execute_template` | Render Templater template | `createFile:"false"` (string) → returns rendered string; `createFile:"true"` → creates file at `targetPath`. `arguments` is `{string:string}`. |
| `get_or_create_daily_note` / `get_or_create_periodic_note` | Ensure + return periodic note | Idempotent. |
| `append_to_periodic_note` | Append to periodic note (today or specified) | Combine with periodic-note ensure for journal flows. |
| `create_vault_directory` / `delete_vault_directory` / `delete_vault_file` | Filesystem ops | `delete_vault_file` requires explicit filename — never `delete_active_file`. |

## Atomic-always for frontmatter (canonical)

Use atomic tools (`set_note_property`, `delete_note_property`) over `patch_vault_file targetType:frontmatter`. Two reasons:

1. **Safer.** Single-key in-place update; malformed scalar elsewhere doesn't block the edit.
2. **Cheaper.** Wire payload `{ path, key, value }` vs JSON-encoded full-frontmatter rewrite.

Multi-key edits: loop the atomic call. Safety and token-economy over speed.

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

Preferred for find/replace across one or many notes. `dry_run:"true"` is the **default** safety gate — it returns a match preview without mutating; pass `"false"` to apply. The `g` flag is always injected (all occurrences). ReDoS-guarded. Scope with `scope` (vault-relative paths or folder prefixes) to avoid vault-wide blast radius.

```json
{ "pattern": "old-token", "replacement": "new-token", "scope": ["Folder/Note.md"], "dry_run": "false" }
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

**Never run a second `execute_template` (`createFile:"true"`) to do step 2** — re-rendering regenerates the ULID and re-resolves `next_id`, yielding a *different* id/ulid than you inspected. Persist the captured render via `create_vault_file`. This is the #44 fix: the old static-gabarit path forced a manual ULID one-liner + `list_vault_files` max-id discovery (~5 calls); now it is one render + one create with zero manual ID work.

### Title-named shapes — one-step (`createFile:"true"`)

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
  createFile: "true",          // STRING, not boolean
  arguments: { /* {string:string}, forwarded via tp.user.mcpTools.prompt(argName) */ }
})
```

Templater writes Linter-ordered frontmatter, `creator: Claude` + `source/ia` (dual-mode via `tp.mcpTools`), `modified:`, and the full body skeleton. Do not `create_vault_file` ad-hoc from a hand-built skeleton — bypassing the template re-implements upstream work and risks subtle divergence.

### Per-shape arguments

| Shape | Required | Optional / defaulted |
|---|---|---|
| BL (VLT-BL / SD-BL) | `titre` | `priority` (default `medium`), `origin` (default `misc`), `linked_bug` (conditional) |
| BUG (VLT-BUG) | `titre` | `severity` (default `minor`), `component`, `first_incident`, `last_occurrence` |
| INC (VLT-INC) | `titre`, `surface`, `layer`, `tool`, `operation` | — |

**INC `surface` is controlled-vocab** — allowed: `claude-ai-web`, `claude-ai-mobile`, `cowork`, `desktop-chat`, `dispatch`, `claude-code`. Any other value fails-loud server-side (*"value '…' is not in the controlled vocabulary"*). Map the session's surface; don't pass freeform.

**BUG post-create side-effect (manual).** Templater can't mutate sibling notes. After creating a BUG, each linked incident still needs `bug:` set + `status: assigned` applied afterward (loop `set_note_property` per incident note).

## Templater invariants (when authoring or debugging a template)

1. **Every fenced JS block must close correctly.** Mismatched `<% … %>` brackets corrupt render and can leave file unsaved.
2. **`tp.user.*` helpers live in `99 - Méta/Templates/scripts/`.** Confirm helper exists before referencing.
3. **MCP-mode detection via `tp.mcpTools`.** Use dual-mode prelude (`if (tp.mcpTools) { creator = "Claude"; tags.push("source/ia") } else { creator = "Pierre-André Folot" }`).
4. **Sequential IDs via `tp.user.next_id(<prefix>, <folder>)`.** Never invent IDs client-side for active-Templater shapes.
5. **No EJS literals inside JS comments inside a Templater block.** EJS parser interprets `<%`, `%>`, `-%>`, `<%*` **even inside `//` or `/* */` comments**. Commented-out example tag still terminates surrounding block. Break across two strings (`"<" + "%"`) or move example outside the Templater block.

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

## Heading-patch safety

1. Before `patch_vault_file targetType: heading`: read via `get_vault_file_partial mode=outline` (cheap) — abort if heading absent.
2. `createTargetIfMissing: true` (default ≥ 0.4.5) silently appends to EOF when heading missing — do not rely on it as safety net.
3. **H2-rooted (H1-free) notes require `allowRootHeadings:true` passed EXPLICITLY.** Title in frontmatter, body starts at H2 → the patch is rejected unless the flag is set (error: *"Heading is level-4 with no H1 parent — allowRootHeadings:true required"*). It is **not** accepted automatically. Wire:
   ```json
   { "targetType": "heading", "target": "Objet", "operation": "replace", "allowRootHeadings": true, "content": "…" }
   ```
4. `targetType: block` rejected fail-loud if block ref inside table cell or fenced-code boundary.
5. **`targetType: heading` with `operation: replace` traverses H2 boundaries inside fenced code blocks** (VLT-BUG-0022, still active). Target section with fenced block containing `## ` lines: heading walker treats internal `## ` as real boundaries — replace stops at first one, orphaning rest of code block and promoting internal `## ` to real H2. Silent corruption.
   - **Discipline:** before heading replace, read target section via `get_vault_file_partial mode=heading`, scan for fenced blocks with `## ` lines. If present, route to `create_vault_file` (full-file rewrite).
- Post-write: on first heading patch of session, verify mtime + diff before proceeding.

## Renaming — prefer the link-safe tools

| Intent | Tool | Why |
|---|---|---|
| Rename heading + update all `[[Note#Heading]]` refs | `rename_heading` | Vault-wide sweep by connector. Replaces patch + manual `[[…#…]]` grep. |
| Rename file + preserve all `[[Name]]` | `rename_vault_file` | Incoming links rewritten. Replaces filesystem rename + sweep. |
| Move file across folders | `rename_vault_file` with new path | Same link preservation. |

Do not rename via `create_vault_file` + `delete_vault_file` — breaks all incoming `[[…]]`.

## NFC normalisation

- Apply NFC to every path/title with accented characters before any MCP call.
- 404 on path that should exist: try NFC variant → `list_vault_files` parent → byte-compare → log VLT-INC.

## Footguns

- `delete_active_file` takes no arguments — deletes whatever is focused in Obsidian. Always use `delete_vault_file` with explicit filename.
- MCP write followed by manual UI save can be overwritten by Obsidian's re-import. Wait for "Re-import" banner to clear before saving in UI.
- Do not pre-create parent dirs; `create_vault_file`, `append_to_vault_file`, `execute_template` auto-mkdirp since 0.4.5.
- No "verify MCP is alive" ping before writes. Let real call surface failures; retry only on abnormal signals.
- `patch_vault_file` `operation` is **required, no default** — omit it and the call is rejected (*"operation must be 'append','prepend' or 'replace' (was missing)"*). Always pass `replace`/`append`/`prepend`.
- **mcp-tools-istefox has NO bash tool.** `mcp__mcp-tools-istefox__bash` → *"No such tool available"*. Run shell via Code `Bash` or Cowork `mcp__workspace__bash`.
- `get_vault_file` timeout / *"server unavailable"* is an **abnormal signal** → retry once before escalating to PA.

Frontmatter schema → `organon-frontmatter`. Body prose → `organon-markdown-style`. Read-side → `organon-vault-read`.
