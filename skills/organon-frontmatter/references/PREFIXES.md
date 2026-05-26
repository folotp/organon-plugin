# Préfixes d'identifiants

Registry of Organon identifier prefixes. Form: `DOMAIN-TYPE[-SUBTYPE]-NNN`, 3–4 digits per domain volumetry. IDs immutable; block-refs (`^<ID>`) declared in note headers.

## Core principles

1. **Domain, not tool.** Prefixes reflect domain (`VLT`, `FIN`, `SD`), not tool (`OBS`, `YNAB`). Domains survive tool migration.
2. **Stability.** IDs never change. Reclassify via new ID + redirection; never reuse.
3. **Atomicity.** One ID = one `.md` file. Registers/journals link only; content in fiche.
4. **Block-ref anchor.** Each fiche declares `^<ID>` under title for stable links.

## Prefix registry

| Prefix | Type | Folder | ID format | Naming convention | Notes |
|--------|------|--------|-----------|-------------------|-------|
| `FIN-DEC` | Decision | `01 - Finances et patrimoine/Décisions/` | `NNN` (3 digits) | `FIN-DEC-NNN.md` | Structural financial decisions |
| `FIN-RULE` | Rule | `01 - Finances et patrimoine/Standards/Règles/` | `<DOMAIN>-NNN` | `FIN-RULE-<DOMAIN>-NNN.md` | Testable rules. Subdomains observed: GOV, BEH, BUD, CAT, CREDIT, DATA, DOC, EMG, EST, GLS, GOALS, IMM, INGEST, IPC, LONG, REEE, RET, RISK, SENS, TAX, TOOL, WD, XL, YNAB, BAL |
| `FIN-HYP` | Hypothesis | `01 - Finances et patrimoine/Standards/Hypothèses/` | `NNN` (3 digits) | `FIN-HYP-NNN.md` | Active values |
| `FIN-REF` | Reference | `01 - Finances et patrimoine/Standards/Références/` | `NNN` (3 digits) | `FIN-REF-NNN.md` | Sources & references |
| `FIN-TOOL` | Tool spec | `01 - Finances et patrimoine/Standards/Outils/` | `<OUTIL>-NNN` | `FIN-TOOL-<OUTIL>-NNN.md` | Tool-specific notes. Observed: PL, YNAB, TPAW, DSN, XL, SPEC |
| `FIN-RB` | Runbook | `01 - Finances et patrimoine/Standards/Outils/Runbooks/` | `NNN` (3 digits) | `FIN-RB-NNN.md` | Procedures |
| `FIN-TPL` | Template | `01 - Finances et patrimoine/Standards/Outils/Gabarits/` | `NNN` (3 digits) | `FIN-TPL-NNN.md` | Skeleton files |
| `FIN-BL` | Backlog | `01 - Finances et patrimoine/Backlog/Items/` | `NNNN` (4 digits) | `FIN-BL-NNNN.md` | Action items |
| `FIN-ETAT` | Statement | `01 - Finances et patrimoine/États/` | `YYYY-MM-DD` | `FIN-ETAT-YYYY-MM-DD.md` | Dated snapshots |
| `FIN-STD-INDEX` | Index pivot | `01 - Finances et patrimoine/Standards/` | (singleton) | `FIN-STD-INDEX.md` | Master index |
| `FIN-REF-REDIR-001` | Redirection pivot | `01 - Finances et patrimoine/Standards/Références/` | (singleton) | `FIN-REF-REDIR-001.md` | Refactoring registry |
| `VLT-INC` | Incident | `99 - Méta/Outils/Accès à Obsidian par Claude/Incidents/` | `NNNN` (4 digits) | `VLT-INC-NNNN.md` | Immutable observed occurrence |
| `VLT-BUG` | Bug | `99 - Méta/Outils/Accès à Obsidian par Claude/Bugs/` | `NNN` (3 digits) | `VLT-BUG-NNN.md` | Root cause; N:1 with incidents |
| `VLT-BL` | Backlog | `99 - Méta/Outils/Accès à Obsidian par Claude/Backlog/` | `NNNN` (4 digits) | `VLT-BL-NNNN.md` | Implementation work |
| `SD-ADR` | ADR | `99 - Méta/Système documentaire/ADR/` | `NNN` (3 digits) | `SD-ADR-NNN.md` | Architectural decision on vault system |
| `SD-BL` | Backlog | `99 - Méta/Système documentaire/Backlog/` | `NNNN` (4 digits) | `SD-BL-NNNN.md` | System doc work items |
| `SPA` | (Domain reserved) | `—` | — | — | Not yet allocated |

## Creation protocol

**New domain prefix:**
1. Check registry & reserved names (`ORG`, `OBS`, `CLD`, `DEBT`).
2. Must name a domain, not a tool.
3. Add as `Réservé` with scope & index note.
4. Activate (`Actif`) when first fiche created.
5. Sync `Vocabulaire — domain` frontmatter value.

**New type within existing domain:**
1. Verify no existing type covers it.
2. Add row; specify 3 or 4 digits per expected volume.
3. Create folder if volumetry justifies.
4. Document observed subtypes (e.g., `FIN-RULE-GOV`, `FIN-TOOL-YNAB`) as they appear.

## Anti-patterns

- Invent ID mid-session without registry entry → silent collision.
- Tool name as prefix (`YNAB-001`) → breaks on tool change.
- Renumber after creation → breaks all backlinks; new ID + redirect instead.
- Delete fiche → use `status: archived` or `status: superseded-by: [[<new>]]`; never remove (traceability).
- 2-letter prefix (`OB`, `FI`) → ambiguous; use 3+.
- "Technical debt" type → resolve with backlog; debt is action, action is backlog.

## Reserved prefixes (not allocated)

- `ORG` — too close to "Organon"; avoids confusion with `VLT`.
- `OBS` — too tightly bound to Obsidian.
- `CLD` — scopes to agent, not domain.
- `DEBT` — (rejected 2026-04-19) distinction from backlog was cosmetic; items are backlog.

## Related notes

- Parent: Conventions de nommage
- Cross-domain: Vocabulaire — domain
- Methodology: Méthodologie — Incidents, bugs et backlog; Méthodologie — ADR
- Index: Index des standards financiers (FIN); Index — Accès à Obsidian par Claude (VLT)
