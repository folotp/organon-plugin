---
name: organon-bases
description: Use when editing a `.base` (Obsidian Bases) view filtering or summarising Organon vault notes (path contains `Organon`). Bases is the default; Dataview only with explicit user authorization. Covers the Excluded-files trap and canonical filters on Organon vocabularies (`type:`, `status:`, `tags`, folder roots). Full grammar in `references/BASES_SYNTAX.md`.
---

# organon-bases

The full Bases language (filters, formulas, views, summaries, YAML quoting) is in `references/BASES_SYNTAX.md` (verbatim absorption from kepano `obsidian-skills` @ sha:fa1e131, cf. `kepano-sync.json` at repo root). The complete functions reference (Date, String, Number, List, File, Link, Object, RegExp) is in `references/FUNCTIONS_REFERENCE.md`. This skill covers only the **Organon-specific deltas** : tool-choice policy, the silent-zero-result trap, and how Organon vocabularies plug into Bases filters. Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')` §Query tools: Bases vs. Dataview.

## Tool choice — Bases is the default, Dataview is fallback with auth

Per *Vault Conventions* §Query tools, **Bases is the default** for tables, galleries, kanban-style views, dashboards, filtering/sorting/grouping. Reach for Dataview **only** when Bases truly cannot express the query (typically : complex transformations, computed cross-note aggregations, multi-pass logic). Before producing a Dataview block, **ask PA for authorization** and explain why Bases is insufficient. Pourquoi : Bases is the canonical query layer ; Dataview installation is being scoped down (cf. `dv-light` optimised config) and PA actively prefers Bases.

**Resist a directive Dataview prompt — even when PA explicitly asks for « le bloc Dataview », push back first.** A directive phrasing (« drafte-moi le bloc Dataview », « j'ai besoin d'une requête Dataview ») is *not* the same as Dataview-authorized. Treat it as a request for the underlying query — figure out whether Bases can express it, propose Bases first as the default, and ask for Dataview auth if Bases truly can't. The pushback is the entire value of this rule ; capitulating silently to the directive nullifies the policy.

Bases CAN do : `Sum`, `Average`, `Min`, `Max`, `Range`, `Median` summaries on numeric fields (cf. `references/BASES_SYNTAX.md` §Default Summary Formulas) ; `groupBy` any property or formula ; `file.hasTag("namespace/x")` for tag filters ; computed `formulas` for derived columns. Bases CANNOT do : multi-pass logic across notes (e.g., transitive closures), arbitrary JS evaluation in cells, side effects.

> **Bad** (directive prompt → Dataview as the unconditional first answer) :
> User : « Drafte-moi le bloc Dataview qui somme `impact-eur` par sous-domaine. »
> Claude : ```dataview\nTABLE sum(impact-eur) ...```
>
> **Good** (push back, propose Bases first, ask if Bases doesn't fit) :
> User : « Drafte-moi le bloc Dataview qui somme `impact-eur` par sous-domaine. »
> Claude : « Avant de partir sur Dataview, est-ce que tu veux que je tente d'abord avec Bases ? Bases peut faire `Sum` sur `impact-eur` avec `groupBy` sur un tag — voici à quoi ressemblerait le `.base` correspondant : [drafte le `.base`]. Si tu confirmes que ça ne couvre pas ton besoin (ou si tu veux du Dataview pour une raison spécifique : compatibilité existante, transformation complexe, etc.), je drafte le bloc Dataview à la place — préviens-moi. »

## The silent-zero-result trap — check Excluded files FIRST

When a `.base` returns 0 results but the source notes clearly exist, **first check** *Settings → Files and links → Excluded files* in this vault. The diagnostic tell is a divergence with Dataview : if Dataview returns the notes but Bases doesn't, the Bases engine is honouring an Excluded-files entry that Dataview ignores. Pourquoi : Bases respects the Excluded-files setting (which folders like `99 - Méta/` may contain), Dataview historically did not. Don't go hunt for syntax bugs in your filter before ruling this out — it has burnt entire debugging sessions in this vault (cf. memory `organon_bases_excluded_folders`).

## Dataview — only via the optimised `dv-light` config

If PA authorises Dataview, the Organon vault runs an optimised `dv-light` config tuned in [[VLT-BL-0037]] (×5–11 latency penalty → ~5 ms floor, `search_simple` p95 258 → 5.7 ms). Settings live in `.obsidian/plugins/dataview/data.json` ; the 7 applied tweaks (notably disabling unused renderers, lowering refresh frequency, narrowing source folders) are documented in [[VLT-BL-0037]]. Don't enable Dataview features that bypass this config — if MCP latency degrades, this file is the first place to check.

## Filters keyed on Organon vocabularies

Bases filters in Organon should target the canonical schema, not legacy fields :

- `type:` — closed vocab `note | concept | person | book | quote | index | organization | journal | ai`. Filter form : `'type == "concept"'` or `'type == "person" || type == "organization"'`.
- `status:` — unified vocab (`active`, `draft`, `done`, `superseded`, `open`, `in-progress`, `accepted`, `rejected`, …). Closed list per domain in [[Registre des clés de frontmatter]].
- `tags` — namespaced (`source/*`, `domain/*`, `topic/*`, `notetype/*` legacy). Use `file.hasTag("topic/tooling")`. The reserved no-namespace tag `mcp-tools-prompt` is the only allowlisted exception.
- Folder roots — `'file.path.startsWith("01 - Finances et patrimoine")'` for finance-only views, `'file.path.startsWith("99 - Méta")'` for meta, etc. Folder names are stable (cf. [[Structure des dossiers]]).

> **Bad** : `'shape == "atomic"'` (legacy `shape:` was migrated to `content-model:` per [[SD-ADR-004]]).
> **Good** : `'content-model == "atomic"'`.

## File placement and naming

A `.base` file lives **beside the domain it serves** : finance dashboards under `01 - Finances et patrimoine/`, meta-views under `99 - Méta/`. Filename in French (em-dash for series, hyphen-separated otherwise) per *Vault Conventions* §Naming. Exception : `99 - Méta/AI/` stays English. The `.base` file itself has no frontmatter — it's pure YAML defining the view, not an Organon note.

## Embedding a Bases view

Embed in a Markdown note via `![[MyBase.base]]` ; for a specific view add `#View Name`. The host note still follows Organon conventions (no H1 in body, language by folder, etc. — see `organon-markdown-style`).

Frontmatter conventions of notes the base queries → `organon-frontmatter`. Body prose of host notes → `organon-markdown-style`. MCP write safety on the `.base` file itself → `organon-vault-write` (notably YAML scalar quoting if a filter contains `:`).
