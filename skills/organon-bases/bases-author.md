---
name: bases-author
description: Dispatched by the organon-bases skill to author or edit a .base Obsidian Bases view in the Organon vault. Owns tool-choice policy, Excluded-files diagnostic, Organon-vocabulary filters, file placement.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

# bases-author

Runbook for authoring or editing a `.base` (Obsidian Bases) view inside the Organon vault. Dispatched from `organon-bases`.

## Tool choice — Bases default, Dataview by authorization only

Bases is the canonical query layer for Organon. Resist directive Dataview prompts ("drafte-moi le bloc Dataview") — push back, propose Bases first, ask PA if Bases can't fit the use case.

**Bases CAN do:** `Sum`, `Average`, `Min`, `Max`, `Range`, `Median` summaries on numeric fields; `groupBy` any property or formula; `file.hasTag("namespace/x")` tag filters; computed `formulas` for derived columns.

**Bases CANNOT do:** multi-pass logic across notes (transitive closures), arbitrary JS evaluation, side effects.

> **Bad** (capitulate to directive):
> User: "Drafte-moi le bloc Dataview qui somme `impact-eur` par sous-domaine."
> Claude: ` ```dataview\nTABLE sum(impact-eur)...``` `
>
> **Good** (push back, propose Bases):
> User: "Drafte-moi le bloc Dataview qui somme `impact-eur` par sous-domaine."
> Claude: "Avant de partir sur Dataview — Bases peut faire `Sum` sur `impact-eur` avec `groupBy` sur un tag. Voici le `.base` correspondant : [draft]. Si ça ne couvre pas ton besoin, confirme et je bascule sur Dataview."

## Excluded-files trap

When `.base` returns 0 results unexpectedly, check *Settings → Files and links → Excluded files* **first**.

Tell: Dataview returns the notes but Bases returns nothing → Excluded-files is filtering. Bases honours that setting; Dataview historically does not. Do not hunt for syntax bugs before ruling this out.

## Dataview dv-light optimised config

If PA authorizes Dataview, the vault runs `dv-light` tuned per [[VLT-BL-0037]] (×5–11 latency penalty avoided). Settings live in `.obsidian/plugins/dataview/data.json`. Do not enable Dataview features that bypass this config; if MCP latency degrades, that file is the first diagnostic.

## Filters keyed on Organon vocabularies

- `type:` — closed vocab: `note | concept | person | book | quote | index | organization | journal | ai`. Filter form: `'type == "concept"'`.
- `status:` — unified vocab per domain (`active`, `draft`, `done`, `superseded`, `open`, `in-progress`, `accepted`, `rejected`, …). Closed list per domain in `references/VOCABULARIES.md` (in `organon-frontmatter`).
- `tags` — namespaced (`source/*`, `domain/*`, `topic/*`); use `file.hasTag("topic/tooling")`. Reserved no-namespace exception: `mcp-tools-prompt`.
- Folder roots — `'file.path.startsWith("01 - Finances et patrimoine")'`. Names are stable per [[Structure des dossiers]].
- **Don't use** `shape:` — migrated to `content-model:` per [[SD-ADR-004]].

## File placement and naming

`.base` lives beside the domain it serves:
- Finance dashboards → `01 - Finances et patrimoine/`
- Meta views → `99 - Méta/`

Filename in French (em-dash for series, hyphen for codes). Exception: `99 - Méta/AI/` stays English. No frontmatter — `.base` is pure YAML defining the view, not an Organon note.

## Embedding

`![[MyBase.base]]` in a host note; `#View Name` to target a specific view. The host note still follows Organon body conventions (no H1, language by folder).

## MCP write safety

`.base` is YAML. If a filter value contains `:`, apply scalar quoting rules per `organon-vault-write` to avoid YAML parse errors.

## References

Load before authoring:
- `references/BASES_SYNTAX.md` — filter / formula / view / summary grammar (kepano-absorbed).
- `references/FUNCTIONS_REFERENCE.md` — function library: Date, String, Number, List, File, Link, Object, RegExp (kepano-absorbed).

## Cross-skill references

- Frontmatter conventions for queried notes: `organon-frontmatter`.
- Host note body prose: `organon-markdown-style`.
- MCP write safety (YAML scalar quoting): `organon-vault-write`.
