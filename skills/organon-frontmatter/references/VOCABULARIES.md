# Organon — frontmatter controlled vocabularies

Lazy-loaded reference for closed vocabularies. For frontmatter schema, see `REGISTRE_KEYS.md`. For identifier prefixes, see `PREFIXES.md`.

## `type:` (16 values)

`note | concept | person | book | quote | index | organization | journal | ai | hypothesis | rule | tool | template | runbook | reference | plan`

| Value | Folder | Notes |
|---|---|---|
| `note` | any (by topic) | Default |
| `concept` | `08 - Savoirs et références/Concepts/` | Definition |
| `person` | `08 - Savoirs et références/Personnes/` | Person fields apply |
| `book` | `08 - Savoirs et références/Livres/` | Book fields apply |
| `quote` | `08 - Savoirs et références/Citations/` | |
| `index` | Same folder organized | MOC / routing |
| `organization` | `08 - Savoirs et références/Personnes/` | Co-located with persons |
| `journal` | Varies | Logs, meeting notes |
| `ai` | `99 - Méta/AI/` | AI config & bootstrap |
| `hypothesis` | Domain FIN/HYP | Modeling proposition |
| `rule` | Domain standards | Operational rule |
| `tool` | Domain standards | External tool |
| `template` | `99 - Méta/Templates/` | Templater/skeleton |
| `runbook` | Domain standards/RB | Executable procedure |
| `reference` | Domain standards/REF | Canonical source |
| `plan` | Domain | Planning doc |

Added 2026-05-05: `hypothesis | rule | tool | template | runbook | reference | plan`.

## `content-model:` 

| Value | Meaning |
|---|---|
| `atomic` | Single idea/fact/decision (200–400 words) |
| `reference` | Consultative (500–1500 words) |
| `narrative` | Story/analysis/retrospective |
| `journal` | Dated, append-only |
| `moc` | Map of content / index |

Legacy: `shape:` migrating to `content-model:` (VLT-ADR-007).

## `status:` (unified cross-domain)

| Value | Meaning | Applicable to |
|---|---|---|
| `active` | Canonical, in use | Standards (adopted 2026-05-05 [[FIN-BL-0107]]) |
| `draft` | In progress | General notes, FIN decisions, ADRs |
| `done` | Work completed | Backlog, notes |
| `superseded` | Replaced; requires `superseded-by:` | Canonical notes |
| `open` | Not started | Backlog, bugs |
| `in-progress` | Active | Backlog |
| `planned` | Scheduled | Backlog |
| `verified` | Confirmed post-deployment | Bugs, backlog |
| `closed` | Terminal | Bugs |
| `abandoned` | Dropped with reason | Backlog |
| `proposed` | Awaiting validation | ADRs, FIN-DEC |
| `accepted` | Accepted | FIN-DEC, ADRs |
| `rejected` | Rejected | FIN-DEC, ADRs |
| `deprecated` | No longer in force (rare) | ADRs, FIN-DEC |
| `investigating` | Under investigation | Bugs |
| `root-cause-known` | Root cause found | Bugs |
| `fix-designed` | Fix designed | Bugs |
| `fix-deployed` | Deployed | Bugs |
| `recorded` | Initial INC state | Incidents |
| `assigned` | Promoted to bug | Incidents |

Legacy: `#statut/*` migrating to `status:`.

## `adr-status` / `vlt-adrs:status` / `vlt-dec:status`

| Value | Meaning |
|---|---|
| `proposed` | Drafted, awaiting validation |
| `accepted` | Adopted, in effect |
| `rejected` | Rejected, archived for traceability |
| `superseded` | Replaced by newer; `superseded-by:` filled |
| `deprecated` | No longer in force (avoid; prefer supersession) |

## `vlt-bl-status` / `sd-bl-status`

| Value | Meaning |
|---|---|
| `open` | Not started |
| `planned` | Scheduled |
| `in-progress` | Active |
| `done` | Completed |
| `verified` | Verified post-deployment |
| `abandoned` | Dropped with reason |

## `vlt-bl-priority` / `sd-bl-priority`

| Value | Meaning |
|---|---|
| `low` | Deferrable indefinitely |
| `medium` | Default; normal cycle |
| `high` | Blocks/slows current work |
| `critical` | Total blocker or serious risk |

## `vlt-bl-origin` / `sd-bl-origin`

If `origin: bug`, `linked-bug:` field is mandatory (points to parent `VLT-BUG-NNN`).

| Value | Meaning |
|---|---|
| `bug` | Fix bug; `linked-bug:` required |
| `capability` | New feature/tool/automation |
| `verification` | Test / audit / re-verify |
| `remediation` | Fix/mitigate (broader than bug) |
| `mitigation` | Reduce impact without full resolution |
| `misc` | Catchall (avoid) |

## `vlt-bug-status`

Lifecycle: `open → investigating → root-cause-known → fix-designed → fix-deployed → verified → closed` (jumps allowed if documented).

| Value | Meaning |
|---|---|
| `open` | Not yet investigating |
| `investigating` | Root-cause search |
| `root-cause-known` | Cause found, remediation not designed |
| `fix-designed` | Fix designed, backlog open |
| `fix-deployed` | Deployed, awaiting verification |
| `verified` | Post-deployment verification passed |
| `closed` | Terminal (fixed or N/A) |

## `vlt-bug-severity`

Intrinsic technical gravity; distinct from `priority` (backlog urgency).

| Value | Meaning |
|---|---|
| `trivial` | Cosmetic, no functional impact |
| `minor` | Easily worked around, low frequency |
| `major` | Blocks use case, significant effort to work around |
| `critical` | Blocks core use case, no viable workaround |

## `vlt-inc-status`

Special case: not consumed by INC template (hardcodes `status: recorded` at creation, [[SD-ADR-008]]); exists for audit and manual transitions.

| Value | Meaning |
|---|---|
| `recorded` | Incident logged (initial state, factual) |
| `assigned` | Promoted to bug (VLT-BUG opened, INC readonly) |
| `superseded` | Reformulated; `superseded-by:` filled |

## `vlt-inc-surface` (Claude interface)

User interaction point at incident time.

| Value | Meaning |
|---|---|
| `claude-ai-web` | claude.ai web |
| `claude-ai-mobile` | claude.ai mobile (iOS/Android) |
| `cowork` | Claude Desktop Cowork mode |
| `desktop-chat` | Claude Desktop non-Cowork |
| `dispatch` | Claude Dispatch |
| `claude-code` | Claude Code CLI |

## `vlt-inc-layer` (technical layer)

Symptom origin; distinct from `surface`.

| Value | Meaning |
|---|---|
| `mcp` | Model Context Protocol |
| `cli` | Command-line tools |
| `skill` | Skill invocation/runtime |
| `filesystem` | Filesystem, mounts, paths |
| `uri` | URI/URL/deeplinks |
| `github` | GitHub API/CLI |
| `framework` | Agent framework, hooks, runtime |

## `vlt-inc-operation` (operation type)

Functional operation type; exact tool in `tool:` field.

| Value | Meaning |
|---|---|
| `read` | File/note read |
| `write` | Full write |
| `patch` | Targeted edit |
| `delete` | Delete |
| `search` | Search |
| `list` | Directory/note listing |
| `rename` | Move/rename |
| `config` | Settings edit |
| `tool-discovery` | Tool lookup/invocation |

## `domain` (functional domain)

Co-sourced with `PREFIXES.md` §Domaines. Each must have corresponding identifier prefix.

| Value | Meaning |
|---|---|
| `VLT` | Claude ↔ Organon; agent vault access governance. Root: `99 - Méta/Outils/Accès à Obsidian par Claude/` |
| `SD` | Documentary system; vault structure. Root: `99 - Méta/Système documentaire/` |
| `FIN` | Finance & assets. Root: `01 - Finances et patrimoine/`. Active prefix; BL-only (no FIN-BUG/INC/ADR). |

## `topic` (cross-cutting, `#topic/*`)

Transverse technical/methodological tags (orthogonal to `#domain/*`). Format: lowercase, ASCII, hyphens, flat (no `/` hierarchy). Growth rule: ≥2 distinct notes + transverse to ≥2 domains.

| Value |
|---|
| `api` |
| `architecture` |
| `claude` |
| `cli` |
| `conventions` |
| `cowork` |
| `documentation` |
| `filesystem` |
| `github` |
| `identifiers` |
| `mcp` |
| `methodology` |
| `mobile` |
| `observability` |
| `obsidian` |
| `performance` |
| `plugin` |
| `runbook` |
| `serveur` |
| `skills` |
| `sync` |
| `template` |
| `tooling` |
| `upstream` |
| `uri` |

## Tag namespaces (Organon-curated)

| Namespace | Usage | Examples |
|---|---|---|
| `source/*` | Content origin | `source/web`, `source/ia`, `source/conversation` |
| `domain/*` | Functional domain | `domain/finance`, `domain/health` |
| `topic/*` | Cross-cutting | See `topic` vocabulary |
| `notetype/*` | **Legacy** → `type:` | Do not add |
| `statut/*` | **Legacy** → `status:` | Do not add |

### Reserved tags without namespace

- `mcp-tools-prompt` — required on `.md` in `Prompts/` (vault root) for MCP prompt exposure via `mcp-tools-istefox`.

## `lang:` (BCP 47)

Common: `fr`, `en`, `fr-CA`. Inferrable by folder: `99 - Méta/AI/` → `en`; others → `fr`.

## Person fields (`type: person` only)

Aligned with schema.org Person. Full table: see `REGISTRE_KEYS.md` §Person.

| Field | Notes |
|---|---|
| `given-name`, `family-name`, `nickname` | (`first-name` legacy → `given-name`) |
| `birth-date`, `death-date` | YYYY-MM-DD |
| `gender` | Optional; recommend `male`, `female`, `non-binary` |
| `father`, `mother` | Organon extension (gendered vs schema.org `parent`) |
| `children`, `sibling`, `spouse` | schema.org standard |

## Book fields (`type: book` only)

Aligned with schema.org Book. Full table: see `REGISTRE_KEYS.md` §Book.

- `title` — book title (may differ from Organon note `title:`)
- `author` — book author (≠ `creator:`)
- `date-published`, `isbn`, `in-language` — optional

## Validation

New keys require `REGISTRE_KEYS.md` entry before use. Vocabulary extensions require vault registre and re-sync via `scripts/sync-vault.sh`.
