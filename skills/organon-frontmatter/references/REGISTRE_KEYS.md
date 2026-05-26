# Frontmatter Keys Registry

Canonical registry of all frontmatter keys in Organon. Per key: description, scope, required/optional, type, controlled vocabulary, standard/origin, Linter sort position.

**Controlled vocabularies:** authoritative value lists in `99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — <key>.md`. Vault-wide (Templater, Linter, Bases, audits). On disagreement, vocabulary note is canonical.

## Key Legend

- **Scope**: `global` (all notes), `type X` (type X only), `domain Y` (domain Y only).
- **Required**: `yes` (always), `no` (optional), `if X` (conditional rule).
- **Type**: `string`, `list<string>`, `date`, `datetime`, `wikilink`, `list<wikilink>`, `bool`, `number`, `enum`.
- **Standard**: DCMI, schema.org, Pandoc, SSG, Bugzilla, Obsidian, Organon, BCP 47, ISO 8601.

## Global Keys (all notes)

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `title` | Human-readable note title. Coded notes begin with code (e.g. `"FIN-DEC-090 — Title…"`). Not tied to filename (Option C, 2026-04-23). | yes | string | free; code prefix if applicable | Pandoc, SSG |
| `aliases` | Alternative names. Coded notes: first alias is code alone (e.g. `FIN-DEC-090`) for short wikilinks. | no | list<string> | free | Obsidian |
| `description` | Scope line; recommended for notes >500 words. | no | string | free | DCMI, schema.org |
| `type` | Note type; determines filing and structural contract. | yes | enum | see **Vocabulary: type** below | Organon |
| `content-model` | Structural contract orthogonal to type (renamed from `shape`, 2026-04-25). | no | enum | see **Vocabulary: content-model** below | Organon |
| `lang` | Primary language. | no | string | BCP 47 | BCP 47 |
| `creator` | Author of Organon note (not described content). | no | string | free | DCMI |
| `created` | Creation timestamp. | yes | datetime | `YYYY-MM-DD HH:mm` | DCMI, ISO 8601 |
| `modified` | Last modification timestamp. | yes | datetime | `YYYY-MM-DD HH:mm` | DCMI, ISO 8601 |
| `ulid` | Unique stable identifier (ULID, 26 char Crockford base32). Forward-only; notes before 2026-04-23 may lack it. | no | string | ULID (26 chars) | Organon |
| `status` | Lifecycle state; vocabulary depends on domain. | no | enum | see domain sections | Bugzilla / Organon |
| `archived` | Archive flag; orthogonal to status. | no | bool | `true` / `false` | Organon |
| `archived-date` | When archived. | if `archived: true` | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `closed-date` | When closed or completed. | if `status: done \| closed` (recommended) | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `date` | Date of described content/event (distinct from `created`/`modified`). For incidents, snapshots, dated events. Generalized 2026-05-05 beyond VLT-INC only. | if applicable to note type | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `last-reviewed` | Date of last content review/audit (freshness tracking). Adopted 2026-05-05. | no | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `next-review` | Planned next review date. Adopted 2026-05-05. | no | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `cadence` | Review/execution frequency for recurring processes. Adopted 2026-05-05. | no | enum | `on-demand` \| `monthly` \| `quarterly` \| `annually` | Organon |
| `tags` | Functional tags (source, domain, topic). | no | list<string> | defined namespaces | Obsidian, SSG |
| `up` | Parent note(s). | no | list<wikilink> | wikilink(s) | Organon |
| `same` | Notes at same level on same subject. | no | list<wikilink> | wikilink(s) | Organon |
| `next` | Next note in sequence. | no | wikilink | wikilink | Organon |
| `previous` | Previous note in sequence. | no | wikilink | wikilink | Organon |
| `superseded-by` | Replaced by this note. Dual use: (a) replacement (`status: superseded`), (b) versioning (with `version:`, points to next version). Context distinguished by presence of `version:`. | if `status: superseded` or if versioned | wikilink | wikilink | DCMI |
| `review` | Planned review date. | no | date | `YYYY-MM-DD` | Organon |
| `obsidianUIMode` | Preferred UI mode (system). | no | enum | `preview` / `source` | Obsidian |

### Vocabulary: type

`note` | `concept` | `person` | `book` | `quote` | `index` | `organization` | `journal` | `ai` | `hypothesis` | `rule` | `tool` | `template` | `runbook` | `reference` | `plan`

- `note` — General catch-all.
- `concept` — Atomic definition of term, idea, phenomenon.
- `person` — Person profile.
- `book` — Book reading note.
- `quote` — Collected quotation.
- `index` — Navigation hub (MOC).
- `organization` — Organization profile.
- `journal` — Dated append-only log.
- `ai` — Bootstrap config for AI system in `99 - Méta/AI/`.
- `hypothesis` — Modeling proposition to validate (planning, research). Promoted 2026-05-05.
- `rule` — Operational rule applicable to system/context. Promoted 2026-05-05.
- `tool` — External tool (software, API, service) for internal use. Promoted 2026-05-05.
- `template` — Templater template or reusable skeleton. Promoted 2026-05-05.
- `runbook` — Executable operational procedure (review, audit, backup). Promoted 2026-05-05.
- `reference` — Canonical source of fact(s) or specification. Promoted 2026-05-05.
- `plan` — Planning document (financial, project, strategic). Promoted 2026-05-05.

### Vocabulary: content-model

`atomic` | `reference` | `narrative` | `journal` | `moc`

- `atomic` — Single question, decision, entity. ~200–400 words.
- `reference` — Canonical multi-section source of truth. ~500–1500 words.
- `narrative` — Long prose (plan, essay, argument). No hard ceiling.
- `journal` — Chronological, append-only, dated per entry.
- `moc` — Link-routed navigation, minimal prose.

### Vocabulary: status (global)

See controlled vocabulary note for complete list. Global value **`active`** (adopted 2026-05-05): note in force/operational. Distinct from `accepted` (decisions/ADR only) and `done` (backlog items only).

## Keys for type: person

Aligned with schema.org Person + Organon gendered family extensions.

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `given-name` | Given name. | no | string | free | schema.org |
| `family-name` | Family name. | no | string | free | schema.org |
| `nickname` | Common nickname. | no | string | free | FOAF, vCard |
| `birth-date` | Birth date. | no | date | `YYYY-MM-DD` | schema.org, ISO 8601 |
| `death-date` | Death date. | no | date | `YYYY-MM-DD` | schema.org, ISO 8601 |
| `gender` | Gender identity. | no | string | free (recommended: `male`, `female`, `non-binary`, other) | schema.org |
| `father` | Father (wikilink). | no | wikilink | wikilink | Organon |
| `mother` | Mother (wikilink). | no | wikilink | wikilink | Organon |
| `children` | Children. | no | list<wikilink> | wikilinks | schema.org |
| `sibling` | Siblings. | no | list<wikilink> | wikilinks | schema.org |
| `spouse` | Spouse(s). | no | list<wikilink> | wikilinks | schema.org |

## Keys for type: book

Aligned with schema.org Book.

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `title` | Book title (also note title). | yes | string | free | schema.org, Pandoc |
| `author` | Book author (not note author—see `creator`). | no | string | free | schema.org |
| `date-published` | Publication date. | no | date or year | `YYYY-MM-DD` or `YYYY` | schema.org, ISO 8601 |
| `isbn` | ISBN (preferably ISBN-13). | no | string | ISBN-13 or ISBN-10 | schema.org |
| `in-language` | Language of book. | no | string | BCP 47 | BCP 47 |

## Keys for domain: Finance (01 - Finances et patrimoine/)

### FIN-DEC (Finance Decisions)

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `FIN-DEC-NNNN` | Organon |
| `date-decided` | Date decision made. | yes | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `status` | Decision lifecycle. | yes | enum | `proposed` \| `accepted` \| `rejected` \| `superseded` \| `deprecated` | Organon (Nygard 2011, ADR canon) |
| `references` | Referenced notes. | no | list<wikilink> | wikilinks | Organon |

**ADR status canon harmonized 2026-05-05** (`proposed`, `accepted`, `rejected`, `superseded`, `deprecated`). Prior French legacy values no longer in use.

### Other Finance Subdomains

Subdomains use global frontmatter + `id:` field: `FIN-HYP-*` (hypothesis), `FIN-TOOL-*` (tool), `FIN-RULE-*` (rule), `FIN-REF-*` (reference), `FIN-BL-*` (backlog item), `FIN-ETAT-*` (state snapshot), `FIN-RB-*` (runbook).

**No FIN-specific keys since 2026-05-05** — thematic classification via `tags:` (namespaces `topic/finance/<area>`, `topic/system/<name>`, `topic/item-type/<value>`). Retired keys: `domain`, `item-type`, `tool-type`, `target-type`, `scope`, `category`, `related-decisions`, `snapshot-date`. See **Retired Keys** section.

## Keys for domain: VLT (99 - Méta/Outils/Accès à Obsidian par Claude/)

### VLT-INC (Incidents)

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `VLT-INC-NNNN` | Organon |
| `type` | Record type. | yes | enum | `incident` | Organon |
| `date` | Incident date. | yes | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `surface` | Claude surface where incident occurred. | yes | enum | `claude-ai-web` \| `claude-ai-mobile` \| `cowork` \| `desktop-chat` \| `dispatch` \| `claude-code` | Organon |
| `layer` | Technical layer. | yes | enum | `mcp` \| `cli` \| `skill` \| `filesystem` \| `uri` \| `github` \| `framework` | Organon |
| `tool` | Exact tool or command name. | yes | string | free | Organon |
| `operation` | Operation type. | yes | enum | `read` \| `write` \| `patch` \| `delete` \| `search` \| `list` \| `rename` \| `config` \| `tool-discovery` | Organon |
| `status` | Record status. | yes | enum | `recorded` \| `assigned` \| `superseded` | Organon |
| `bug` | Associated bug. | no | wikilink | `[[VLT-BUG-NNN]]` | Organon |

### VLT-BUG (Bugs)

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `VLT-BUG-NNN` | Organon |
| `type` | Record type. | yes | enum | `bug` | Organon |
| `status` | Lifecycle status. | yes | enum | `open` \| `investigating` \| `root-cause-known` \| `fix-designed` \| `fix-deployed` \| `verified` \| `closed` | Bugzilla |
| `severity` | Severity level. | yes | enum | `trivial` \| `minor` \| `major` \| `critical` | Bugzilla |
| `component` | Affected component. | no | string | `COMP-NNN` | Organon |
| `first-incident` | First observed incident. | no | wikilink | `[[VLT-INC-NNNN]]` | Organon |
| `last-occurrence` | Last observed incident. | no | wikilink | `[[VLT-INC-NNNN]]` | Organon |

### VLT-BL (Backlog)

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `VLT-BL-NNNN` | Organon |
| `type` | Record type. | yes | enum | `backlog` | Organon |
| `status` | Item status. | yes | enum | `open` \| `planned` \| `in-progress` \| `done` \| `verified` \| `abandoned` | JIRA / Organon |
| `priority` | Priority level. | yes | enum | `low` \| `medium` \| `high` \| `critical` | JIRA |
| `effort` | Effort estimate. | no | string | free (e.g. `15 min`, `1 h`, `1 day`) | Organon |
| `origin` | Item origin. | yes | enum | `bug` \| `capability` \| `verification` \| `remediation` \| `mitigation` \| `misc` | Organon |
| `linked-bug` | Associated bug if `origin: bug`. | if `origin: bug` | wikilink | `[[VLT-BUG-NNN]]` | Organon |

## Keys for domain: SD (99 - Méta/Système documentaire/)

### SD-BL (Backlog)

Mirror of VLT-BL. Same schema, different ID prefix and folder. See **Methodology — Incidents, Bugs & Backlog**.

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `SD-BL-NNNN` | Organon |
| `type` | Record type. | yes | enum | `backlog` | Organon |
| `status` | Item status. | yes | enum | `open` \| `planned` \| `in-progress` \| `done` \| `verified` \| `abandoned` | JIRA / Organon |
| `priority` | Priority level. | yes | enum | `low` \| `medium` \| `high` \| `critical` | JIRA |
| `effort` | Effort estimate. | no | string | free (e.g. `15 min`, `1 h`, `1 day`) | Organon |
| `origin` | Item origin. | yes | enum | `bug` \| `capability` \| `verification` \| `remediation` \| `mitigation` \| `misc` | Organon |
| `linked-bug` | Associated bug if `origin: bug`. | if `origin: bug` | wikilink | `[[VLT-BUG-NNN]]` | Organon |

**Note:** SD-INC and SD-BUG flows not yet created — no observed need.

## Keys for type: ADR (VLT-ADR-NNN and SD-ADR-NNN)

Architecture Decision Records. VLT-ADR: Claude × Organon interface (`99 - Méta/Outils/Accès à Obsidian par Claude/ADR/`). SD-ADR: documentary system (`99 - Méta/Système documentaire/ADR/`).

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `id` | Stable identifier. | yes | string | `VLT-ADR-NNN` or `SD-ADR-NNN` (3 digits) | Organon |
| `date-decided` | Date decision made (or backfilled if retroactive). | yes | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `status` | ADR lifecycle status. | yes | enum | `proposed` \| `accepted` \| `rejected` \| `superseded` \| `deprecated` | Organon (Nygard 2011) |
| `references` | Referenced notes. | no | list<wikilink> | wikilinks | Organon |
| `supersedes` | ADR replaced by this one (if part of supersession chain). | if supersession chain | wikilink | `[[<PREFIX>-ADR-NNN]]` | Organon |

**Deprecated fields (2026-05-05):** `amends:` and `amended-by:` retired in favor of complete supersession pattern (`supersedes:` / `superseded-by:`). See **Retired Keys**.

## Keys for Versioned Notes

For notes with formal versioned lifecycle (e.g. **Modèle opérationnel — Claude × Organon**). Orthogonal to global lifecycle keys (`status`, `archived`).

| Key | Description | Required | Type | Vocabulary | Standard |
|---|---|---|---|---|---|
| `version` | Semantic version `MAJOR.MINOR`. **Must be quoted in YAML** to prevent float coercion (e.g. `"1.0"`). MAJOR = breaking change; MINOR = backward-compatible addition. | if note is versioned | string | `"MAJOR.MINOR"` quoted | Organon (semver) |
| `issued` | Publication date of current version. Distinct from `created` (note creation) and `modified` (last file touch). | if note is versioned | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `supersedes` | Version/note replaced by this one (inverse of `superseded-by`). `null` if v1.0 initial. | if versioned ≠ v1.0 initial | wikilink or null | wikilink | Organon |

**Versioning governance** (documented on stable pointer note for each versioned family, e.g. **Modèle opérationnel — Claude × Organon**):
1. New version created as `(vYYYY-MM-DD).md` with `status: draft`.
2. Iterate on draft without version bump.
3. Activate: old → `status: superseded` + `superseded-by:` filled; new → `status: active`; pointer note updated.
4. Superseded versions remain in place; history preserved.

**Scope:** architecture pivot notes only. Not a general-purpose vault pattern.

## Linter Sort Order (yaml-key-sort)

Canonical key order for Linter `yaml-key-sort` configuration:

```
title
aliases
description
type
content-model
lang
author
given-name
family-name
nickname
gender
birth-date
death-date
father
mother
children
sibling
spouse
id
ulid
version
date
date-decided
date-published
isbn
in-language
last-reviewed
next-review
cadence
surface
layer
tool
operation
severity
priority
effort
origin
component
first-incident
last-occurrence
linked-bug
bug
references
obsidianUIMode
creator
created
modified
issued
status
archived
archived-date
closed-date
review
supersedes
superseded-by
up
previous
next
same
tags
```

**Key placement principles:** Most-consulted first (`title`, `aliases`, `description`, `type`, `content-model`, `lang`). `ulid` follows `id`. Authorship + system timestamps grouped (`creator`, `created`, `modified`). Lifecycle grouped (`status`, `archived`, `archived-date`, `closed-date`). Navigation relations last. Tags always last.

**Action (2026-04-25):** Update `.obsidian/plugins/obsidian-linter/data.json` rule `yaml-key-sort.yaml-key-priority-sort-order` array: replace `shape` with `content-model` at same position (between `type` and `lang`). Linter reverts to alphabetic sort without this fix.

## Retired Keys (Migration Completed)

| Old Key | Replaced By | Notes |
|---|---|---|
| `shape` | `content-model` | Renamed 2026-04-25. 19 notes migrated. |
| `first-name` (kebab) | `given-name` | Linter `remove-yaml-keys` migrated. |
| `last-name` (kebab) | `family-name` | Linter `remove-yaml-keys` migrated. |
| `date updated` (spaced) | `modified` | Never in production; in Linter removal list. |
| Tag `notetype/archive` | `archived: true` + `archived-date:` | Migrated. |
| Tag `notetype/personne` | `type: person` | Migrated. |
| `section-source` | — | Dropped Phase 4B. 178 occurrences removed. |
| `legacy-q-id` | — | Dropped Phase 4B. |
| `legacy-id` | — | Dropped Phase 4B. |
| `down` | — | Deprecated; backlinks via Bases suffice. Removed from 2 notes 2026-05-03. Remove from Linter sort order. |
| `amends` | `supersedes` (full supersession) | Deprecated 2026-05-05. 2 FIN-DEC chains converted to full supersession or `references:`. |
| `amended-by` | `superseded-by` (full supersession) | Deprecated 2026-05-05. Co-migrated with `amends`. |
| `domain` | `tags:` namespace `topic/finance/<area>` | Deprecated 2026-05-05. 115 occurrences migrated (108 FIN-BL + 7 FIN-REF). Drop (not rename); thematic classification via `topic/*` namespace. Avoids collision with template arg `tp.user.domain`. |
| `item-type` | `tags:` namespace `topic/item-type/<value>` | Deprecated 2026-05-05. 108 FIN-BL migrated; values (`maintenance`, `recurring`, `decision-pending`, `parking`) become tags. Value `backlog` (68 notes) dropped—redundant with folder `Backlog/Items/`. French `décision à prendre` → `decision-pending`. |
| `tool-type` | (drop—redundant with ID prefix) | Deprecated 2026-05-05. 19 FIN-TOOL occurrences removed; prefix encodes tool class. |
| `target-type` | (drop—redundant with filename) | Deprecated 2026-05-05. 6 FIN-TOOL-GAB occurrences removed; filename encodes target. |
| `scope` | (drop—redundant with ID prefix) | Deprecated 2026-05-05. 10 FIN-RULE occurrences removed (all `ynab`, encoded in ID). |
| `category` | `tags:` namespace `topic/finance/hypothesis/<category>` | Deprecated 2026-05-05. 13 FIN-HYP migrated. French values → English canonical (`marché → market`, `frais → fees`, `fiscalité → taxation`, `longévité → longevity`). |
| `related-decisions` | `references` | Deprecated 2026-05-05. 10 FIN-RULE occurrences migrated (identical semantics). |
| `snapshot-date` | `date` (semantics broadened) | Deprecated 2026-05-05. 5 FIN-ETAT migrated; `date:` now covers "date of described content/event". |

## Keys In Migration (Vault-wide Incomplete)

| Old Key | Replaced By | Scope | Status |
|---|---|---|---|
| `date created` (spaced) | `created` | Global | To migrate vault-wide |
| `date modified` (spaced) | `modified` | Global | To migrate vault-wide |
| `author` (note author) | `creator` | Global | To migrate vault-wide |
| `first name` (spaced) | `given-name` | Person | To migrate |
| `last name` (spaced) | `family-name` | Person | To migrate |
| `date-of-birth` | `birth-date` | Person | To migrate |
| `date-of-death` | `death-date` | Person | To migrate |
| `child` (singular) | `children` | Person | To migrate |
| `book-title` | `title` | Book | To migrate |
| `book-author` | `author` | Book | To migrate |
| `book-publishing-date` | `date-published` | Book | To migrate |
| `couche` | `layer` | VLT | To migrate |
| `outil` | `tool` | VLT | To migrate |
| `composant` | `component` | VLT | To migrate |
| `premier-incident` | `first-incident` | VLT | To migrate |
| `dernière-occurrence` | `last-occurrence` | VLT | To migrate |
| `priorité` | `priority` | VLT | To migrate |
| `origine` | `origin` | VLT | To migrate |
| `bug-lié` | `linked-bug` | VLT | To migrate |
| `supersedes` (frontmatter) | Typed link in body | Global (canonical notes) | To migrate |
| `prev` | `previous` | Global | To migrate if present |
| Tag namespace `#statut/*` | Frontmatter `status:` | Global | To migrate vault-wide |

## Open Questions

- Backfill strategy for `archived-date` on notes in `_Archives/` with unknown date: use `modified` as proxy, or sentinel `1970-01-01`.

## Related

- Parent: **Conventions Obsidian**
- Sister notes: **Vocabulaire — domain**, **Préfixes d'identifiants**
- Reference: **SD-ADR-009** (externalizing controlled vocabularies)
