---
name: organon-frontmatter
description: Use when composing or editing frontmatter on an Organon vault note (path contains `Organon`). Schema, key ordering (Linter `yaml-key-priority-sort-order`), controlled vocabularies, ULID forward-only, creator dual-mode, archive/supersession, alias-only versioning, navigation fields for typed shapes (ADR/BL/BUG/INC).
---

# organon-frontmatter

**Canonical source:** `references/REGISTRE_KEYS.md` (Organon-owned since v1.0.0 — `[[Registre des clés de frontmatter]]` is PA's reading copy, not authoritative).

**Language coherence** (folder default, prose-fields ↔ `lang:` ↔ body) — governed by `organon-markdown-style` §Langue par dossier. Not duplicated here.

## References

| File | Load when |
|---|---|
| `references/VOCABULARIES.md` | Any closed-enum value is needed (12 absorbed enums + `type`, `status`, `content-model` lookups). |
| `references/REGISTRE_KEYS.md` | Composing a structured note or needing an unfamiliar key. |
| `references/SHAPES_QUICKREF.md` | Creating a typed note (ADR, BL, BUG, INC, Person/Book/Quote, new ID). |
| `references/PREFIXES.md` | Generating a new ID. |
| `references/METHODOLOGY_ADR.md` | Creating an ADR (VLT-ADR / SD-ADR / FIN-DEC) or changing its `status:`. |
| `references/METHODOLOGY_INC_BUG_BL.md` | Creating an INC, BUG, or BL, or changing its `status:`. |
| `references/PROPERTIES.md` | Generic YAML syntax / property types (adapted from kepano; see `kepano-version.txt`). |

## Key rules

**Linter order** — `yaml-key-priority-sort-order` in `.obsidian/plugins/obsidian-linter/data.json`. `ulid:` sits between `id:` and `creator:`, not after `modified:`. Adding a key to the Registre requires updating `yaml-key-priority-sort-order` too — otherwise Linter falls back to alphabetical on next save.

**`title:` Option C** — descriptive, human-readable. Notes with a code: `"CODE — Titre descriptif"` (quote if contains `:` or `—`). `aliases:` carries the code alone. Filename stays technical. Linter `yaml-title` disabled.

**`ulid:`** — Crockford base32, 26 chars (`0–9 A–Z` minus `I L O U`), forward-only at creation. Always emit a real value — never an empty key or placeholder. Lost ULIDs are unrecoverable.

**`creator:` dual-mode** — UI → `Pierre-André Folot`, no `source/ia` tag. MCP → `Claude`, add `source/ia` tag. Detection via `tp.mcpTools` in template prelude.

**`creator` vs `author`** — `creator` = Organon note author. `author` = author of the described external work (`type: book` and similar only).

**Archive** — `archived: true` + `archived-date: YYYY-MM-DD` (pair required; orthogonal to `status:`).

**Supersession** — on the superseded note: `status: superseded` + `superseded-by: "[[…]]"` + `> [!warning] Superseded` callout at top of body. On the new note: `supersedes: "[[…]]"` conditional for ADR/FIN-DEC; canonical general notes migrate to typed body link (see `references/REGISTRE_KEYS.md`). `amends:` / `amended-by:` are **deprecated** (2026-05-05, [[SD-ADR-011]]).

**Alias-only versioning** (VLT-ADR-008) — stable short alias transferred between versions; no pointer note.

**Tag namespaces** — prefixes inside the `tags:` array, not top-level keys:
```yaml
tags:
  - source/ia
  - domain/tooling
  - topic/methodology
```
Using `source: [ia]` / `domain: [tooling]` as root keys is wrong — not recognised by Linter, Smart Connections, or Bases.

**Legacy namespaces** — `source/*`, `domain/*`, `topic/*`, `notetype/*` (legacy → `type:`), `statut/*` (legacy → `status:`). Allowlisted bare tag: `mcp-tools-prompt`.

## Touch-on-edit (legacy migration, VLT-ADR-007)

Editing a legacy note triggers normalisation of detected legacy keys: `shape:` → `content-model:`, `notetype/*` tag → `type:`, `#statut/*` → `status:`, `date created` → `created`, `author` → `creator`, `first-name` → `given-name`.

- Normalise at most ~3 legacy keys per edit. Beyond that, flag to PA.
- If the edit is already large (>10 lines touched) or PA says "minimal edit", skip touch-on-edit and mention legacy keys as debt.
- Log each migration: `Frontmatter normalisé : <legacy-key> → <canonical-key>` (one line per key).

## Governance

No new key without an entry in `[[Registre des clés de frontmatter]]`. Also update `yaml-key-priority-sort-order` for Linter ordering.
