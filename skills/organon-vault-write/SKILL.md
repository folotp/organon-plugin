---
name: organon-vault-write
description: Use before any `patch_vault_file`, `create_vault_file`, `append_to_vault_file`, or `execute_template` call on the Organon vault (path contains `Organon`). MCP write discipline (mcp-tools-istefox ≥ 0.4.5): YAML quoting, frontmatter array semantics, tags shape, heading-patch safety, NFC normalisation, Templater-first routing for structured shapes.
---

# organon-vault-write

Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`.

## MCP write-tool surface

| Tool | Use for | Notes |
|---|---|---|
| `patch_vault_file` | Targeted field/heading/block edits on an existing note | `targetType`: `frontmatter` \| `heading` \| `block`; `operation`: `replace`/`append`/`prepend` |
| `create_vault_file` | Create a new note with full content | Auto-creates missing parent directories (≥ 0.4.5) |
| `append_to_vault_file` | Append raw content to an existing note | Idempotency is caller's responsibility |
| `execute_template` | Render a Templater template | `createFile: false` → returns rendered string; `createFile: true` → creates file at `targetPath` |

## Templater-first routing (structured shapes)

- IF the shape is BL / BUG / INC / ADR (sequential ID): use **two-step** — `execute_template … createFile:false` → read `frontmatter.id` from rendered output → `create_vault_file content=<render> filename=<folder>/<id>.md`. Never invent the ID before rendering; Templater generates it via `tp.user.next_id`.
- IF the shape is Note / Concept / Person / Book / Quote / Index / Organization: use **one-step** — `execute_template … createFile:true targetPath:<path>`.
- NEVER `create_vault_file` ad-hoc for these shapes — Templater injects ULID, sequential ID, creator, and Linter-conformant key order.

## YAML quoting rules

- IF a frontmatter scalar contains `: # & * ! | > ' " % @ \``: quote it with `"…"`.
- **Wire format for `patch_vault_file targetType: frontmatter`**: `content` must be a JSON-encoded string, not a JSON object. Internal double-quotes escaped as `\"`.
  ```json
  { "content": "\"Value with : colon\"", "contentType": "application/json" }
  ```
  **Why:** Local REST API revalidates full frontmatter on every patch — a malformed scalar blocks all subsequent edits (HTTP 500).

## Frontmatter array vs scalar

- Fields `tags:`, `aliases:`, `references:` are arrays. Pass a JSON array string: `"content": "[\"a\", \"b\"]"`.
- On a scalar field, pass a JSON string: `"content": "\"some value\""`.
- IF types mismatch: fail-loud (no silent coercion since istefox 0.4.0).
- `append`/`prepend` auto-wrap a bare scalar into an array element on array fields.

## Tags shape

- `tags:` must be an array of strings — never a number, `null`, bare date, or empty scalar.
- IF no tags: omit the key entirely, or use `tags: []`.
- **Why:** YAML 1.1 silently parses `tags: 4` as `[Number(4)]`; plugins calling `.startsWith()` crash.

## Heading-patch safety

1. Before any `patch_vault_file targetType: heading`: `get_vault_file` + grep `^## <target>$`. Abort if absent.
2. `createTargetIfMissing: true` (the default on ≥ 0.4.5) silently appends to EOF when the heading is missing — do not rely on it as a safety net.
3. `createTargetIfMissing: false` is **incompatible with Organon** — istefox rejects H2-root notes as "root-orphan" (all Organon notes are H2-root by convention).
4. `targetType: block` is rejected fail-loud if the block ref is inside a table cell or on a fenced-code boundary.
- Post-write: on the first heading patch of a session, verify mtime + diff before proceeding.

## NFC normalisation

- Apply NFC to every path and title containing accented characters before any MCP call.
- IF 404 on a path that should exist: try NFC variant → `list_vault_files` parent → byte-compare → log VLT-INC.

## Footguns

- `delete_active_file` takes no arguments — deletes whatever is focused in Obsidian. Always use `delete_vault_file` with an explicit filename.
- MCP write followed by a manual UI save can be overwritten by Obsidian's re-import. Wait for the "Re-import" banner to clear before saving in the UI.
- Do not pre-create parent directories; `create_vault_file`, `append_to_vault_file`, and `execute_template` auto-mkdirp since 0.4.5.
- Do not add a "verify MCP is alive" ping step before writes. Let the real call surface failures; retry only on abnormal signals.

Schema frontmatter → `organon-frontmatter`. Body prose → `organon-markdown-style`.
