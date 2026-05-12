# ADR Methodology (AI-slim)

Distilled from `[[Méthodologie — ADR]]` (vault, canonical). Re-derive after material methodology changes. Read when drafting or transitioning an ADR.

Cross-refs: `REGISTRE_KEYS.md` §Clés pour les ADR · `VOCABULARIES.md` §`adr-status`, §`type` · `SHAPES_QUICKREF.md`.

---

## Scope

| Prefix | Domain | Folder |
|---|---|---|
| `VLT-ADR-NNN` | Claude × Organon interface | `99 - Méta/Outils/Accès à Obsidian par Claude/ADR/` |
| `SD-ADR-NNN` | Documentary system | `99 - Méta/Système documentaire/ADR/` |

Same shape, same lifecycle, same governance. Prefix and folder are the only differences.

---

## Write-or-not rules

**Write an ADR IF:** decision changes a policy, modifies architecture (folders, note types, frontmatter schema, inter-fiche flows), adopts/abandons a tool or protocol, arbitrates conflicting principles, or would be contestable without context.

**Do NOT write an ADR IF:** execution work for a decided decision → backlog (`<DOMAIN>-BL-NNNN`). Empirical observation with no decisional content. Bug fix → `METHODOLOGY_INC_BUG_BL.md`. Minor update to an already-ADR'd convention that does not reverse an earlier decision.

---

## Required sections

- **Contexte** — forces, constraints, trigger, viable options.
- **Décision** — one decision, declarative. One per ADR.
- **Conséquences** — what gets easier/harder; accepted trade-offs.

Recommended: **Alternatives considérées** · **Mise en œuvre** · **Journal** (append-only events on the fiche itself).

---

## Frontmatter template

```yaml
---
title: "<PRÉFIXE>-NNN — <Titre>"
aliases:
  - <PRÉFIXE>-NNN
type: note
content-model: atomic
lang: fr
id: <PRÉFIXE>-NNN
ulid: <generated>
date-decided: YYYY-MM-DD
references:
  - "[[Note référencée]]"
creator: <Pierre-André Folot | Claude>
created: YYYY-MM-DD HH:mm
modified: YYYY-MM-DD HH:mm
status: proposed | accepted | rejected | superseded | deprecated
supersedes: "[[<PRÉFIXE>-ADR-NNN]]"      # conditional
superseded-by: "[[<PRÉFIXE>-ADR-MMM]]"   # conditional
up:
  - "[[Index — VLT-ADR]]"  # or [[Index — SD-ADR]]
tags:
  - source/ia
  - topic/architecture
---
```

`supersedes:` / `superseded-by:` — present only when the fiche is in a supersession chain.

---

## Status transitions

```
proposed → accepted       (ratified)
proposed → rejected       (rejected — keep fiche for traceability)
accepted → superseded     (new ADR replaces it; new one carries supersedes:)
accepted → deprecated     (no longer in force, no replacement — rare; prefer supersession)
```

No other transitions are valid. `rejected` and `deprecated` are terminal.

---

## Immutability rule (CRITICAL)

An `accepted` ADR is never rewritten. IF the decision changes, THEN write a new ADR that:
- carries `supersedes: "[[old]]"` in frontmatter,
- restates the **complete** current decision (no read-dependency on the old fiche),
- explains in Contexte what changed.

The old ADR:
- gets `status: superseded` + `superseded-by: "[[new]]"`,
- stays in place (no archiving),
- receives the superseded callout (see below).

**Why complete supersession only:** single-pattern coherence. `amends:` / `amended-by:` are deprecated — never use them. Even purely additive changes (adding an enum value, extending a case list) follow complete supersession.

---

## Superseded callout (mandatory)

Insert on the **first body line** after frontmatter for any `status: superseded` fiche:

```markdown
> [!warning] Superseded
> Cette fiche est remplacée par [[<nouvelle>]]. Pour la décision en vigueur, consulter cette dernière.
```

**Why both `status:` and callout:** `status: superseded` drives Bases/Dataview filters and AI skill recovery. The callout protects any agent or human who loads the fiche despite the filter — they see the warning before reading the body.

Not Linter-enforced; verified during monthly Organon maintenance.

---

## Workflows

### Creating an ADR
1. Pick prefix (`VLT-ADR` / `SD-ADR`) by domain.
2. Read the index to find the next available number.
3. Create `<PRÉFIXE>-NNN.md` in the ADR folder; frontmatter per `REGISTRE_KEYS.md`.
4. Set `status: proposed` unless already ratified at write time (then `status: accepted`, noted in journal).
5. Update the index's modifications journal if the decision impacts the in-force convention.

### Supersession
1. Create new ADR with `supersedes: "[[old]]"`.
2. Update old ADR: `status: superseded` + `superseded-by: "[[new]]"` + insert superseded callout on first body line.
3. Audit notes referencing the old ADR — wikilinks still resolve, but pointed content may be obsolete.

### MCP write discipline
1. Emit write (`create_vault_file` for full fiche, `patch_vault_file` for targeted amendment).
2. Re-read (`get_vault_file`).
3. Compare persisted values to intent on critical fields: `id:`, `status:`, `supersedes:`, `superseded-by:`, body wikilinks.
4. IF mismatch THEN do NOT retry same write — switch to `create_vault_file` (full rewrite).

---

## Anti-patterns

- Rewriting an `accepted` ADR → always supersede.
- Multiple decisions in one ADR → one decision = one ADR.
- ADR for execution work → that's backlog; test: "does it change policy?"
- `type: adr` → vocabulary is closed; ADRs are `type: note` + `content-model: atomic`.
- Confusing ADR with `FIN-DEC` → `FIN-DEC` covers financial decisions; do not rename to `FIN-ADR`.
- Using `amends:` / `amended-by:` → deprecated; always use complete supersession.
