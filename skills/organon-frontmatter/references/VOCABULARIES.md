# Organon — frontmatter controlled vocabularies

Référence chargée à la demande par la skill `organon-frontmatter` quand la tâche en cours nécessite la liste exhaustive d'un vocabulaire fermé. Pour les valeurs courantes utilisables sans lookup, voir directement le SKILL.md.

Autorité ultime : `[[Registre des clés de frontmatter]]` dans le vault Organon (`get_vault_file('99 - Méta/Système documentaire/Registre des clés de frontmatter.md')`). Ce fichier est le résumé exécutable.

## `type:` — note shape

| Valeur | Folder canonique | Notes |
|---|---|---|
| `note` | Any (select by topic) | Default ; folder choisi par sujet |
| `concept` | `08 - Savoirs et références/Concepts/` | Définition de concept |
| `person` | `08 - Savoirs et références/Personnes/` | Person fields applicables (cf. SKILL.md §Person fields ou Vault Conventions) |
| `book` | `08 - Savoirs et références/Livres/` | Book fields applicables (`author:` = auteur du livre, pas de la note) |
| `quote` | `08 - Savoirs et références/Citations/` | |
| `index` | Same folder it organizes | MOC / routing note |
| `organization` | `08 - Savoirs et références/Personnes/` | Co-located avec persons |
| `journal` | Varies | Daily notes, meeting notes, incident logs |
| `ai` | `99 - Méta/AI/` | AI-related config et bootstrap |

## `status:` — état de la note

Vocabulaire unifié cross-domaines. Sous-ensembles applicables par type de note :

| Valeur | Sémantique | Domaines applicables |
|---|---|---|
| `active` | Canonical, in use | General notes |
| `draft` | In progress, not canonical | General notes, FIN decisions, ADRs |
| `done` | Work completed | VLT backlog, general notes |
| `superseded` | Replaced by a newer note | Any canonical note (FIN decisions, ADRs, …) — exige `superseded-by:` |
| `open` | Not started | VLT bugs, VLT backlog |
| `in-progress` | Active | VLT backlog |
| `planned` | Scheduled, not started | VLT backlog |
| `verified` | Confirmed after deployment | VLT bugs, VLT backlog |
| `closed` | Terminal (rejected/dropped/won't fix) | VLT bugs |
| `abandoned` | Dropped with documented reason | VLT backlog |
| `proposed` | Drafted, awaiting validation | ADRs (VLT-ADR, SD-ADR) |
| `accepted` | Decision accepted | FIN decisions, ADRs |
| `rejected` | Decision rejected | FIN decisions, ADRs |
| `deprecated` | No longer in force, no replacement (rare) | ADRs |
| `investigating` | Under investigation | VLT bugs |
| `root-cause-known` | Root cause identified | VLT bugs |
| `fix-designed` | Remediation designed | VLT bugs |
| `fix-deployed` | Remediation deployed | VLT bugs |

Le namespace tag `#statut/*` est legacy en migration vers le champ `status:`.

## Tag namespaces fonctionnels

| Namespace | Usage | Exemples |
|---|---|---|
| `source/*` | Origine du contenu | `source/web`, `source/livre`, `source/conversation`, `source/thérapie`, `source/ia` |
| `domain/*` | Domaine fonctionnel | `domain/finance`, `domain/finance/backlog`, `domain/health` |
| `topic/*` | Cross-cutting topic | `topic/tooling`, `topic/methodology`, `topic/architecture` |
| `notetype/*` | **Legacy** — en migration vers `type:` | (ne pas en ajouter de nouveaux) |
| `statut/*` | **Legacy** — en migration vers `status:` | (ne pas en ajouter de nouveaux) |

### Tags réservés sans namespace (allowlist explicite)

Liste des tags qui bypassent la règle de namespace parce qu'un plugin tiers matche le literal exact. Case-sensitive.

- `mcp-tools-prompt` — required sur les `.md` dans `Prompts/` (vault root, capital P, no nested) pour exposition comme prompts MCP via `mcp-tools-istefox`. Out-of-folder usage casse le filtre du plugin.

Pas de nouveau tag réservé sans entrée au registre.

## `content-model:` — modèle de contenu

| Valeur | Description |
|---|---|
| `atomic` | Une idée, un fact, une décision |
| `reference` | Note de référence consultative |
| `narrative` | Récit, journal d'analyse, retrospective |
| `journal` | Journal entry (daté) |
| `moc` | Map of content (index thematique) |

Note : `shape:` est legacy en migration vers `content-model:` (touch-on-edit).

## `lang:` — langue de la note

BCP 47. Valeurs courantes : `fr`, `en`, `fr-CA`. Inférable par dossier (cf. `organon-markdown-style` §Langue par dossier).

## Person fields (`type: person` only)

Aligné avec schema.org Person, avec extensions Organon pour relations parentales genrées.

| Champ | Notes |
|---|---|
| `given-name`, `family-name`, `nickname` | (`first-name` legacy → `given-name`) |
| `birth-date`, `death-date` | YYYY-MM-DD |
| `gender` | Optionnel |
| `father`, `mother` | Extension Organon (vs schema.org `parent` neutre) |
| `children`, `sibling`, `spouse` | Standard schema.org |

## Book fields (`type: book` only)

Aligné avec schema.org Book.

- `title` : titre du livre (peut différer du `title:` Organon — voir §Règle title Option C dans SKILL.md).
- `author` : auteur du livre (≠ `creator:` qui est l'auteur de la note Organon).
- `date-published`, `isbn`, `in-language` : tous optionnels.

## Validation

Toute nouvelle clé doit avoir une entrée dans `[[Registre des clés de frontmatter]]` avant utilisation. Toute extension d'un vocabulaire fermé existant doit être soumise au registre.
