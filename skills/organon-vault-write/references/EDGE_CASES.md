# Vault-write edge cases — write precondition & heading-patch safety

Load when doing a `patch_vault_file`/`patch_active_file` heading or block patch, or any `operation:"replace"`. Not needed for straightforward frontmatter writes or Templater-first note creation.

## Write precondition (`expectedContent`)

If PA has "Require a write precondition" enabled (Settings → MCP Connector), `patch_vault_file`/`patch_active_file` refuse an `operation:"replace"` unless `expectedContent` is set to the text currently occupying the target — this catches replacing a section PA edited after the last read. Whitespace-insensitive; ignored for `append`/`prepend`.

**Discipline:** immediately before a `replace`, read the target (`get_vault_file_partial mode=heading|block|frontmatter`, or `get_vault_file`) and pass that text as `expectedContent`. Don't reuse content read earlier in a long session — re-read right before the write. A refusal here (*"expected content does not match current content"*) is not a retry-as-is situation: re-read the target, decide whether your edit still applies, and resubmit.

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
6. **Duplicate heading name in the same note → "Ambiguous heading target" (recurring).** A bare `target` (e.g. `"Catalogue"`) matches every heading with that text, at any level, anywhere in the file — patch refuses to guess which one. Check the outline (`get_vault_file_partial mode=outline`) for repeats before patching. Disambiguate by ancestor path, joined with `targetDelimiter` (default `::`): `target: "Parent Heading::Catalogue"`. If the outline shows the duplicate itself is unintentional (e.g. an earlier bug left two `## Catalogue`), fix the duplication first — don't just target around it.
- Post-write: on first heading patch of session, verify mtime + diff before proceeding.

## Param-name footgun

**Recurring param-name mistake**: every write tool here takes `path` for the file — not `filename` or `filepath`. Directory-taking tools (`create_vault_directory`, `delete_vault_directory`) take `path` too, not `folder`. Guessing the wrong key fails loud (*"Key '…' does not exist on schema"*) — check the tool's actual schema, don't pattern-match from a different tool.
