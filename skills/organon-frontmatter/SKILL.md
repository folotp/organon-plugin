---
name: organon-frontmatter
description: Use when composing or editing frontmatter on an Organon vault note (path contains `Organon`). Schema, key ordering (Linter `yaml-key-priority-sort-order`), controlled vocabularies, ULID forward-only, creator dual-mode, archive/supersession, alias-only versioning, navigation fields for typed shapes (ADR/BL/BUG/INC).
---

# organon-frontmatter

**Canonical source:** `references/REGISTRE_KEYS.md` (Organon-owned since v1.0.0 — `[[Registre des clés de frontmatter]]` is PA's reading copy, not authoritative).

**Language coherence** — governed by `organon-markdown-style` §Langue par dossier. Not duplicated here.

## References

| File | Load when |
|---|---|
| `references/VOCABULARIES.md` | Closed-enum value needed (12 absorbed enums + `type`, `status`, `content-model` lookups). |
| `references/REGISTRE_KEYS.md` | Composing a structured note or unfamiliar key. |
| `references/SHAPES_QUICKREF.md` | Creating a typed note (ADR, BL, BUG, INC, Person/Book/Quote, new ID). |
| `references/PREFIXES.md` | Generating a new ID. |
| `references/METHODOLOGY_ADR.md` | Creating/changing `status:` on ADR (VLT-ADR / SD-ADR / FIN-DEC). |
| `references/METHODOLOGY_INC_BUG_BL.md` | Creating/changing `status:` on INC, BUG, or BL. |
| `references/PROPERTIES.md` | Generic YAML syntax / property types (adapted from kepano; see `kepano-version.txt`). |

## Key rules

**Linter order** — `yaml-key-priority-sort-order` in `.obsidian/plugins/obsidian-linter/data.json`. `ulid:` sits between `id:` and `creator:`, not after `modified:`. New key in Registre → also update `yaml-key-priority-sort-order`; else Linter falls back to alphabetical on next save.

**Hand-ordering stays canonical — Linter delegation isn't viable via MCP today.** `execute_obsidian_command{ commandId: "obsidian-linter:lint-file" }` was considered as a way to let the real plugin sort keys instead of replicating `yaml-key-priority-sort-order` by hand (a real drift source — see the 2026-04-25 `shape`→`content-model` fix in `references/REGISTRE_KEYS.md`), but two things rule it out as currently authorized (2026-08): `lint-file` isn't on PA's command allowlist (only `ignore-file`, `ignore-folder`, `lint-all-files` are), **and** it operates on Obsidian's currently-*focused* file — it takes no path parameter — so an MCP write with nothing open in the Obsidian UI has no file for it to act on regardless of authorization. `lint-all-files` (vault-wide) *is* authorized but is too blunt to invoke per single-note write — don't reach for it as a substitute. Keep hand-ordering the Registre's `yaml-key-priority-sort-order` as the only currently-viable method. If PA later authorizes `lint-file` and the write flow reliably makes the target the active file first (e.g. via `show_file_in_obsidian`), this is worth revisiting — until then, don't invoke it.

**Write canonical** — atomic per-key via `set_note_property` / `delete_note_property` (see `organon-vault-write` § Atomic-always). `patch_vault_file targetType:frontmatter` reserved for bulk reshape.

**Read canonical** — atomic per-key via `get_note_property`; full-frontmatter via `get_vault_file_partial mode=frontmatter` (see `organon-vault-read`).

**`title:` Option C** — descriptive, human-readable. Notes with code: `"CODE — Titre descriptif"` (quote if contains `:` or `—`). `aliases:` carries code alone. Filename stays technical. Linter `yaml-title` disabled.

**`ulid:`** — Crockford base32, 26 chars (`0–9 A–Z` minus `I L O U`), forward-only at creation. Always real value — never empty or placeholder. Lost ULIDs unrecoverable.

**`creator:` dual-mode** — UI → `Pierre-André Folot`, no `source/ia` tag. MCP → `Claude`, add `source/ia`. Detection via `tp.mcpTools` in template prelude.

**`creator` vs `author`** — `creator` = Organon note author. `author` = external work's author (`type: book` and similar only).

**Archive** — `archived: true` + `archived-date: YYYY-MM-DD` (pair required; orthogonal to `status:`).

**Supersession** — superseded note: `status: superseded` + `superseded-by: "[[…]]"` + `> [!warning] Superseded` callout at body top. New note: `supersedes: "[[…]]"` for ADR/FIN-DEC; general notes use typed body link (see `references/REGISTRE_KEYS.md`). `amends:` / `amended-by:` **deprecated** (2026-05-05, [[SD-ADR-011]]).

**Alias-only versioning** (VLT-ADR-008) — stable short alias transferred between versions; no pointer note.

**Tag namespaces** — prefixes inside `tags:` array, not top-level keys:
```yaml
tags:
  - source/ia
  - domain/tooling
  - topic/methodology
```
`source: [ia]` / `domain: [tooling]` as root keys is wrong — not recognised by Linter, Smart Connections, or Bases.

**Legacy namespaces** — `source/*`, `domain/*`, `topic/*`, `notetype/*` (legacy → `type:`), `statut/*` (legacy → `status:`). Allowlisted bare tag: `mcp-tools-prompt`.

## Touch-on-edit (legacy migration, VLT-ADR-007)

Editing a legacy note triggers normalisation: `shape:` → `content-model:`, `notetype/*` → `type:`, `#statut/*` → `status:`, `date created` → `created`, `author` → `creator`, `first-name` → `given-name`.

- Max ~3 legacy keys per edit; beyond that, flag to PA.
- Large edit (>10 lines) or PA says "minimal edit" → skip touch-on-edit, note debt.
- Log: `Frontmatter normalisé : <legacy-key> → <canonical-key>` (one line per key).
- Use atomic tools: `delete_note_property{ key: <legacy> }` + `set_note_property{ key: <canonical>, value: <migrated> }`.

## Governance

No new key without `[[Registre des clés de frontmatter]]` entry. Also update `yaml-key-priority-sort-order`.
