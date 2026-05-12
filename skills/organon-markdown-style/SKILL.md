---
name: organon-markdown-style
description: Use when writing prose body for an Organon vault note (path contains `Organon`). Body conventions: no H1 (title = frontmatter `title:`), language-by-folder (`99 - Méta/AI/` EN, other folders FR), typographic apostrophes, no trailing whitespace, no systematic anchors, table+block-ref pitfall. Generic Obsidian markdown in `references/MARKDOWN_SYNTAX.md`.
---

# organon-markdown-style

## Headings

- **No H1 in body.** H2 (`##`) is the first body level, then H3, H4. `title:` frontmatter is the title; Obsidian renders it above the body automatically.
- If removing a legacy `# Title`: delete the line — do not downgrade it to `## Title`.
- No empty headings. No skipped levels (e.g. H2 → H4).

## Language by folder — canonical rule (all other skills reference here, do not duplicate)

| Folder | Language |
|---|---|
| `99 - Méta/AI/` (incl. `Claude/`, `ChatGPT/`) | English |
| All other folders | French |

- **Prompt language ≠ artifact language.** If PA prompts in English about a note in a French folder, write the note in French.
- **Frontmatter prose fields** (`description:`, etc.) must match body language and `lang:`.
- Preserve source-language quotations; translate alongside if needed.

## Typographic style

- Apostrophes: `'` (typographic), not `'` (ASCII). Keeps the note Linter-compliant on first write.
- Em-dash `—` in titles and series filenames (`NN — Title`). Hyphen `-` in codes (`FIN-DEC-001`) and frontmatter keys.
- No trailing whitespace. No tab indentation.

## Anchors

- **No systematic anchors.** Do not inject `^<id>` after frontmatter on new notes.
- Anchor `^token` allowed as last resort when even a nested heading is insufficient. Use a descriptive token (`^cas-1`, `^def-canonical`), never the note's ID.

## Pitfall — tables + block refs + fenced code

`patch_vault_file targetType: block` is rejected (istefox ≥ 0.4.2, VLT-BUG-015) if the target `^id` is inside a table cell or on a fenced-code fence. The block ref remains valid for Obsidian reads and embeds — only the targeted patch operation is blocked.

Workaround: use `targetType: heading` on the parent section, or `create_vault_file` as last resort.

## Wikilinks

Use `[[Note]]` for intra-vault references (renames propagate). Reserve `[text](url)` for external URLs only.

---

Load `references/MARKDOWN_SYNTAX.md` for full Obsidian syntax (wikilinks, callouts, tables, embeds, block refs, footnotes, math, Mermaid).
Load `references/CALLOUTS.md` for callout types.
Load `references/EMBEDS.md` for embed types.

MCP write safety → `organon-vault-write`. Frontmatter schema → `organon-frontmatter`.
