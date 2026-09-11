# Shape-specific frontmatter quickref

| Shape | Required fields | Optional fields | ID format | Folder | Notes |
|---|---|---|---|---|---|
| ADR (VLT-ADR, SD-ADR) | `date-decided`, `references`, `up` | — | `<DOMAIN>-ADR-NNN(N)` | VLT-ADR / SD-ADR | `METHODOLOGY_ADR.md` for lifecycle, supersession, immutability. Read `PREFIXES.md` before proposing a new ID. `FIN-DEC` shares this shape/methodology under its own prefix — see next row. |
| FIN-DEC (finance proto-ADR) | `date-decided`, `references`, `up` | — | `FIN-DEC-NNN` | `01 - Finances et patrimoine/Décisions/` | Same shape/lifecycle as ADR (`METHODOLOGY_ADR.md`), distinct prefix — never renamed `FIN-ADR` (see anti-patterns). Since VLT-BL-0072 (2026-09), created via `ADR-template.md` with `domain:"FIN"` (`adr_id_infix: "DEC"` in `domain.js`) — no longer hand-written. |
| Backlog (VLT-BL, SD-BL) | `priority`, `origin`, `up` | `effort`, `linked-bug` (if origin=bug) | `<DOMAIN>-BL-NNN(N)` | VLT-BL / SD-BL | `METHODOLOGY_INC_BUG_BL.md` for Phase A/B/C lifecycle and status transitions. |
| Bug (VLT-BUG) | `severity`, `first-incident`, `last-occurrence`, `up` | `component` | `VLT-BUG-NNN(N)` | VLT-BUG | `METHODOLOGY_INC_BUG_BL.md` for promotion criteria (incident → bug) and lesson-learned conversion. |
| Incident (VLT-INC) | `date`, `surface`, `layer`, `tool`, `operation`, `status: recorded`, `up` | `bug` (wikilink) | `VLT-INC-NNN(N)` | VLT-INC | `METHODOLOGY_INC_BUG_BL.md`; Phase A: append-only, no causal hypothesis in fiche. |
| Person | — | — | — | — | Fields in `VOCABULARIES.md` §Person; schema in `REGISTRE_KEYS.md`. |
| Book | — | — | — | — | Fields in `VOCABULARIES.md` §Book; schema in `REGISTRE_KEYS.md`. |
| Quote | — | — | — | — | Fields in `VOCABULARIES.md` §Quote; schema in `REGISTRE_KEYS.md`. |

All notes: `up:` (parent Index) recommended for routability.
