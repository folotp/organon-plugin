# Shape-specific frontmatter quickref

| Shape | Required fields | Optional fields | ID format | Folder | Notes |
|---|---|---|---|---|---|
| ADR (VLT-ADR, SD-ADR, FIN-DEC) | `date-decided`, `references`, `up` | — | `<DOMAIN>-ADR-NNN(N)` | VLT-ADR / SD-ADR | See `METHODOLOGY_ADR.md` for lifecycle, supersession, immutability. Read `PREFIXES.md` before proposing new ID. |
| Backlog (VLT-BL, SD-BL) | `priority`, `origin`, `up` | `effort`, `linked-bug` (if origin=bug) | `<DOMAIN>-BL-NNN(N)` | VLT-BL / SD-BL | See `METHODOLOGY_INC_BUG_BL.md` for Phase A/B/C lifecycle and status transitions. |
| Bug (VLT-BUG) | `severity`, `first-incident`, `last-occurrence`, `up` | `component` | `VLT-BUG-NNN(N)` | VLT-BUG | See `METHODOLOGY_INC_BUG_BL.md` for promotion criteria (incident → bug) and lesson-learned conversion. |
| Incident (VLT-INC) | `date`, `surface`, `layer`, `tool`, `operation`, `status: recorded`, `up` | `bug` (wikilink) | `VLT-INC-NNN(N)` | VLT-INC | See `METHODOLOGY_INC_BUG_BL.md`; Phase A: append-only, no causal hypothesis in fiche. |
| Person | — | — | — | — | Fields in `VOCABULARIES.md` §Person; full schema in `REGISTRE_KEYS.md`. |
| Book | — | — | — | — | Fields in `VOCABULARIES.md` §Book; full schema in `REGISTRE_KEYS.md`. |
| Quote | — | — | — | — | Fields in `VOCABULARIES.md` §Quote; full schema in `REGISTRE_KEYS.md`. |

All notes: `up:` (parent Index) strongly recommended for routability.
