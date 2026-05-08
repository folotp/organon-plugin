# Audit keywords — in-scope filter for organon-memory-audit

A memory or instruction line is **in scope** for the audit if it matches (case-insensitive substring or exact-token, depending on the group) any keyword below. Non-matching entries are listed once at the end of the report under "Out of scope (not audited)" and not classified.

Read by `SKILL.md` when filtering pole-3 inputs. The canonical-snippets vault note and plugin manifests are always read in full — filtering applies only to memory/instruction *entries*.

## Plugin / skills / commands (exact tokens)

- `organon`
- `organon-plugin`
- `organon-vault-write`
- `organon-frontmatter`
- `organon-markdown-style`
- `organon-session-discipline`
- `organon-bases`
- `organon-canvas`
- `organon-diagramming`
- `kepano-resync`
- `plugin-release`
- `organon-memory-audit`
- `/kepano-resync`
- `/plugin-release`
- `/organon-memory-audit`

## Vault (substring, case-insensitive)

- `Organon`
- `iCloud~md~obsidian/Documents/Organon`
- `99 - Méta`
- `AI Bootstrap`
- `Linter`
- `Templater`
- `wikilink`
- `frontmatter`

## MCP / tooling (substring)

- `mcp-tools-istefox`
- `obsidian-mcp-tools`
- `MCP`
- `patch_vault_file`
- `create_vault_file`
- `append_to_vault_file`
- `execute_template`
- `get_vault_file`
- `search_vault`

## Diagramming (substring)

- `Excalidraw`
- `Mermaid`
- `JSON Canvas`
- `.canvas`
- `.base`

## Kepano absorption (substring)

- `kepano`
- `kepano-sync`
- `vault-sync`
- `KEPANO-BEGIN`
- `KEPANO-END`
- `body_sha256`
- `Option D`

## Methodologies / vocabularies (substring — added in v0.5.0)

- `REGISTRE_KEYS`
- `PREFIXES`
- `VOCABULARIES`
- `METHODOLOGY_ADR`
- `METHODOLOGY_INC_BUG_BL`
- `ADR`
- `FIN-DEC`
- `INC-`
- `BUG-`
- `BL-`
- `SD-`
- `SPA-`
- `VLT-`

## Surfaces / instruction layers (substring)

- `CLAUDE.md`
- `CLAUDE.local.md`
- `Cowork`
- `Settings → General`
- `Instructions for Claude`
- `Canonical snippets`
- `instruction inheritance`
- `Profile preferences`
- `claude.ai project`
- `Custom connector`
- `Desktop Chat`

## Match rules

- Exact-token groups: surrounded by word boundaries (no partial matches inside identifiers).
- Substring groups: case-insensitive `contains` on the line text.
- A memory entry's frontmatter `description:` field is concatenated with the body for filter purposes — a description-only mention counts.
- A `MEMORY.md` index line counts if either the title or the one-line hook contains a keyword; the linked file is then read in full and re-tested at finding-classification time.
