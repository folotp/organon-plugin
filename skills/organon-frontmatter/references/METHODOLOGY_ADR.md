# Méthodologie — ADR (distilled, Claude-actionable)

**Distilled** from `[[Méthodologie — ADR]]` (vault) at 2026-05-08. The vault file is the canonical methodology and explains the *why* (Nygard rationale, vault history); this file is the Claude-actionable subset for composing/editing ADRs. Re-derive manually after material methodology changes — there are no drift markers (this is Organon-owned, vault-inspired). Read this when drafting an ADR or transitioning its status.

## Scope

Two ADR flows share this methodology:

- **`VLT-ADR-NNN`** — Claude × Organon interface decisions. Folder: `99 - Méta/Outils/Accès à Obsidian par Claude/ADR/`. Index: [[Index — VLT-ADR]].
- **`SD-ADR-NNN`** — Documentary system decisions. Folder: `99 - Méta/Système documentaire/ADR/`. Index: [[Index — SD-ADR]].

Same shape, same lifecycle, same governance. The only differences are the prefix and the folder.

## When to write an ADR

Write an ADR for any decision that:

- **Changes a policy** (convention, rule, taxonomy, status, vocabulary).
- **Modifies architecture** (folders, note types, content-models, frontmatter schema, inter-fiche flows).
- **Adopts or abandons** a practice, tool, plugin, or access protocol.
- **Arbitrates a conflict** between two principles or approaches.
- **Would be contestable** without explicit context.

**Do NOT write an ADR for:**

- Execution work for a decision already made → that's backlog (`<DOMAIN>-BL-NNNN`).
- An empirical observation without decisional content → goes in observations/incidents.
- A bug fix → see `METHODOLOGY_INC_BUG_BL.md`.
- A minor update to an already-ADR'd convention → reflect in the canonical note itself, no new ADR (unless it reverses an earlier decision, then write a supersession).

## Anatomy

### Required sections

- **Contexte** — forces and constraints that made the decision necessary now. What triggered it (incident, observation, request, planned refactor). Viable options identified.
- **Décision** — what is decided, in clear declarative terms. **One decision per ADR.**
- **Conséquences** — what becomes easier, what becomes harder, accepted trade-offs. Include impacts on other notes/conventions.

### Recommended sections

- **Alternatives considérées** — what was examined and why rejected. Prevents future re-litigation.
- **Mise en œuvre** — steps or backlog references that execute the decision.
- **Journal** — append-only events about the fiche itself (creation, status transitions, supersession). No retroactive rewrites.

## Lifecycle (`status:` enum)

See `VOCABULARIES.md` §`adr-status` for the canonical enum. Permitted transitions:

- `proposed` → `accepted` (validation)
- `proposed` → `rejected` (rejection — fiche stays for traceability)
- `accepted` → `superseded` (a new ADR replaces it; new one points back via `supersedes:`)
- `accepted` → `deprecated` (no longer in force, no replacement — rare, prefer supersession)

## Immutability and supersession (CRITICAL)

**Golden rule**: an `accepted` ADR is never rewritten. If the decision changes, **write a new ADR** that:

- Points to the prior ADR via `supersedes: "[[<PRÉFIXE>-ADR-NNN>]]"` in its frontmatter.
- Explains in its Contexte what changed since the superseded ADR.
- Expresses in its body the **complete current state** of the decision, no matter the delta size. The new fiche is autonomous — no required reading dependency on the superseded one.

The old ADR:

- Moves to `status: superseded`.
- Receives `superseded-by: "[[<PRÉFIXE>-ADR-MMM>]]"` in its frontmatter.
- **Stays in place** (no archiving). Its value is precisely historical.
- Receives the standardized superseded callout (see §Marking superseded fiches below).

**Single pattern: complete supersession** ([[SD-ADR-011]], 2026-05-05). Complete supersession is the only valid modification pattern for ADRs (`VLT-ADR`, `SD-ADR`) and `accepted` `FIN-DEC`. The keys `amends:` / `amended-by:` are **deprecated** — do not use them in any new fiche. Even purely additive changes (e.g., adding a value to an enum, extending a covered case list) follow the same complete-supersession rule. Single-pattern coherence beats write-economy on these cases.

## Marking superseded fiches

Every `status: superseded` fiche (ADR or FIN-DEC) **must** carry, on the first body line after the frontmatter, the following callout:

```markdown
> [!warning] Superseded
> Cette fiche est remplacée par [[<nouvelle>]]. Pour la décision en vigueur, consulter cette dernière.
```

The marking is **mandatory but not Linter-enforced**. Presence is verified during Organon's monthly maintenance (the audit list flags any `status: superseded` fiche missing the callout).

**Why both `status:` and the callout.** Double-rideau protection. The `status: superseded` filters Bases/Dataview queries and drives the AI-skill default-recovery filter. The callout protects the agent or human who loads the fiche despite the filter — they hit the warning before reading the body and can short-circuit to the in-force version via the wikilink.

## Mandatory frontmatter (ADR shape)

```yaml
---
title: "<PRÉFIXE>-NNN — <Titre humain descriptif>"
aliases:
  - <PRÉFIXE>-NNN
type: note
content-model: atomic
lang: fr
id: <PRÉFIXE>-NNN
ulid: <generated at creation>
date-decided: YYYY-MM-DD
references:
  - "[[Note référencée]]"
creator: <Pierre-André Folot | Claude>
created: YYYY-MM-DD HH:mm
modified: YYYY-MM-DD HH:mm
status: proposed | accepted | rejected | superseded | deprecated
supersedes: "[[<PRÉFIXE>-ADR-NNN ancien>]]"          # conditional
superseded-by: "[[<PRÉFIXE>-ADR-MMM nouveau>]]"      # conditional
up:
  - "[[Index — VLT-ADR]]"   # or [[Index — SD-ADR]]
tags:
  - source/ia
  - topic/architecture
---
```

`supersedes:` and `superseded-by:` are **conditional** — present only if the fiche participates in a supersession chain.

## Workflow — creating an ADR

1. Pick the prefix (`VLT-ADR` or `SD-ADR`) by domain.
2. Read the corresponding index to find the next available number.
3. Create `<PRÉFIXE>-NNN.md` in the ADR folder of the domain, with frontmatter conforming to `REGISTRE_KEYS.md` §Clés pour les ADR.
4. Set `status: proposed` initially, unless the decision is already ratified at writing time (then `status: accepted`, with mention in the journal).
5. Update the index's modifications journal if the decision impacts the in-force convention.

## Workflow — supersession

1. Create the new ADR with `supersedes: "[[<old>]]"` in its frontmatter.
2. Update the old ADR: `status: superseded` + `superseded-by: "[[<new>]]"` + insert the superseded callout on the first body line.
3. Verify that notes referencing the old ADR (by wikilink) remain valid — wikilinks resolve by filename so nothing breaks, but the pointed content may now be obsolete. Audit case by case.

## MCP write discipline

Applies to any MCP write touching frontmatter or wikilinks (ADR or otherwise). Full procedure in `METHODOLOGY_INC_BUG_BL.md` §MCP write discipline. Summary:

1. Emit the write (`create_vault_file` for full fiche, `patch_vault_file` for targeted amendment).
2. Re-read the file (`get_vault_file`).
3. Compare the persisted value to intent on critical fields (`id:`, `status:`, `supersedes:`, `superseded-by:`, body wikilinks).
4. On mismatch: do NOT retry the same write — switch to `create_vault_file` (full rewrite).

## Anti-patterns

- **Rewriting an `accepted` ADR after the fact.** Destroys historical value. Always supersede.
- **Multiple decisions in one ADR.** Atomicity = one decision = one ADR. Otherwise partial supersession becomes unmanageable.
- **Writing an ADR for execution work.** Execution is backlog, not decision. Test: "does it change policy?" If no, not an ADR.
- **Inventing a new Obsidian type (`type: adr`).** The `type:` vocabulary is closed (see `VOCABULARIES.md` §`type`). ADRs are `type: note` + `content-model: atomic`, like FIN-DEC. The semantics come from the `id:` and folder.
- **Confusing ADR with `FIN-DEC`.** `FIN-DEC` is the proto-ADR of the finance domain; format conventions are aligned but scope differs (financial decisions vs. architectural decisions). Do not migrate `FIN-DEC` to `FIN-ADR` — keep the prefix to preserve traceability.
- **Using `amends:` / `amended-by:`.** Deprecated 2026-05-05 ([[SD-ADR-011]]). Always use complete supersession.
