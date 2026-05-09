# Organon — frontmatter controlled vocabularies

**Snapshot** of vault registre at `synced_at_date 2026-05-08`. The vault file `[[Registre des clés de frontmatter]]` (`99 - Méta/Système documentaire/`) is **authoritative on disagreement**. Per-vocab tables (sections with `<!-- VAULT-BEGIN -->` markers below) are absorbed verbatim from `99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — <key>.md` files. Run `./scripts/sync-vault.sh` to detect drift.

Référence chargée à la demande par la skill `organon-frontmatter` quand la tâche en cours nécessite la liste exhaustive d'un vocabulaire fermé. Pour les valeurs courantes utilisables sans lookup, voir directement le SKILL.md. Pour le **schéma frontmatter complet** (clés globales, clés par-domaine, ordre Linter), voir `REGISTRE_KEYS.md`. Pour le **registre des préfixes d'identifiants** (`<DOMAIN>-<TYPE>-NNNN`), voir `PREFIXES.md`.

## `type:` — note shape (16 valeurs)

Liste canonique : `note | concept | person | book | quote | index | organization | journal | ai | hypothesis | rule | tool | template | runbook | reference | plan`. Pour les descriptions par valeur et les promotions historiques, voir `REGISTRE_KEYS.md` §Vocabulaire `type`.

| Valeur | Folder canonique | Notes |
|---|---|---|
| `note` | Any (select by topic) | Default ; folder choisi par sujet |
| `concept` | `08 - Savoirs et références/Concepts/` | Définition de concept |
| `person` | `08 - Savoirs et références/Personnes/` | Person fields applicables (cf. §Person fields ci-dessous) |
| `book` | `08 - Savoirs et références/Livres/` | Book fields applicables (`author:` = auteur du livre, pas de la note) |
| `quote` | `08 - Savoirs et références/Citations/` | |
| `index` | Same folder it organizes | MOC / routing note |
| `organization` | `08 - Savoirs et références/Personnes/` | Co-located avec persons |
| `journal` | Varies | Daily notes, meeting notes, incident logs |
| `ai` | `99 - Méta/AI/` | AI-related config et bootstrap |
| `hypothesis` | `01 - Finances et patrimoine/Standards/Hypothèses/` (FIN-HYP) ou domaine équivalent | Proposition de modélisation à valider |
| `rule` | `01 - Finances et patrimoine/Standards/Règles/` (FIN-RULE) ou équivalent | Règle opérationnelle dérivée d'une décision |
| `tool` | `01 - Finances et patrimoine/Standards/Outils/` (FIN-TOOL) ou équivalent | Outil externe référencé |
| `template` | `99 - Méta/Templates/` ou domaine | Gabarit Templater ou squelette |
| `runbook` | `01 - Finances et patrimoine/Standards/Outils/Runbooks/` (FIN-RB) ou équivalent | Procédure opérationnelle exécutable |
| `reference` | `01 - Finances et patrimoine/Standards/Références/` (FIN-REF) ou équivalent | Source canonique de fait(s) |
| `plan` | Selon domaine (FIN, projet, stratégique) | Document de planification |

Promotion 2026-05-05 ([[FIN-BL-0107]]) : ajout des 7 dernières valeurs (`hypothesis | rule | tool | template | runbook | reference | plan`). Plugin alignement post-promotion.

## `content-model:` — modèle de contenu

| Valeur | Description |
|---|---|
| `atomic` | Une idée, un fact, une décision (200-400 mots) |
| `reference` | Note de référence consultative (500-1500 mots) |
| `narrative` | Récit, journal d'analyse, retrospective (pas de plafond strict) |
| `journal` | Journal entry (daté, append-only) |
| `moc` | Map of content (index thématique, prose minimale) |

Note : `shape:` est legacy en migration vers `content-model:` (touch-on-edit, VLT-ADR-007).

## `status:` — vocabulaire unifié cross-domaines

Pour les sous-ensembles applicables par domaine (FIN-DEC, VLT-INC, VLT-BUG, VLT-BL, SD-BL, ADR), voir `REGISTRE_KEYS.md` §Clés pour le domaine `<X>` — chaque table par-domaine liste l'enum applicable. Vue cross-cutting :

| Valeur | Sémantique | Domaines applicables |
|---|---|---|
| `active` | Canonical, in use | Notes-standards (hypotheses, rules, tools, runbooks, references) — adoptée 2026-05-05 ([[FIN-BL-0107]]) |
| `draft` | In progress, not canonical | General notes, FIN decisions, ADRs |
| `done` | Work completed | VLT/SD backlog, general notes |
| `superseded` | Replaced by a newer note | Any canonical note (FIN decisions, ADRs, …) — exige `superseded-by:` |
| `open` | Not started | VLT/SD backlog, VLT bugs |
| `in-progress` | Active | VLT/SD backlog |
| `planned` | Scheduled, not started | VLT/SD backlog |
| `verified` | Confirmed after deployment | VLT bugs, VLT/SD backlog |
| `closed` | Terminal (rejected/dropped/won't fix) | VLT bugs |
| `abandoned` | Dropped with documented reason | VLT/SD backlog |
| `proposed` | Drafted, awaiting validation | ADRs (VLT-ADR, SD-ADR), FIN-DEC |
| `accepted` | Decision accepted | FIN decisions, ADRs |
| `rejected` | Decision rejected | FIN decisions, ADRs |
| `deprecated` | No longer in force, no replacement (rare) | ADRs, FIN-DEC |
| `investigating` | Under investigation | VLT bugs |
| `root-cause-known` | Root cause identified | VLT bugs |
| `fix-designed` | Remediation designed | VLT bugs |
| `fix-deployed` | Remediation deployed | VLT bugs |
| `recorded` | Initial state of an INC fiche | VLT incidents |
| `assigned` | INC promoted to BUG (`bug:` filled) | VLT incidents |

Le namespace tag `#statut/*` est legacy en migration vers le champ `status:`.

---

## Vocabulaires absorbés (verbatim, drift-tracked)

Les 12 sections suivantes mirrorent verbatim le `## Valeurs` table de chaque `Vocabulaire — <key>.md` du vault. Marqueurs `<!-- VAULT-BEGIN/END -->` délimitent la zone absorbée ; modifier en re-exécutant `scripts/sync-vault.sh` (ne pas éditer à la main — la modif sera réécrasée à la prochaine re-sync).

### `adr-status` — `VLT-ADR.status`, `SD-ADR.status`, `FIN-DEC.status`

Vocabulaire status des ADR (Nygard 2011) et des FIN-DEC (canon ADR adopté 2026-05-05 par [[FIN-BL-0108]]).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — adr-status.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `proposed` | Rédigé, en attente de validation par PA |
| `accepted` | Décision adoptée, en vigueur — état canonique d’un ADR appliqué |
| `rejected` | Décision examinée puis refusée — la fiche reste pour traçabilité |
| `superseded` | Remplacée par un ADR ultérieur — `superseded-by:` rempli, fiche reste en place |
| `deprecated` | Plus en vigueur sans remplacement explicite — cas rare, à éviter (préférer la supersession) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — adr-status.md §Valeurs -->

### `vlt-bl-status` / `sd-bl-status` — Backlog item lifecycle

Vocabulaire `status:` des items backlog VLT-BL / SD-BL. Convention identique entre domaines.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-status.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `open` | Non commencé, en attente — état initial à la création |
| `planned` | Prévu, planifié dans une session ou un sprint |
| `in-progress` | Activement en cours — la session qui le porte est démarrée |
| `done` | Travail complété — critères d’acceptation cochés |
| `verified` | Vérifié après déploiement — confirmation post-mortem que le travail tient |
| `abandoned` | Abandonné avec raison documentée dans le journal |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-status.md §Valeurs -->

### `vlt-bl-priority` / `sd-bl-priority` — Backlog item priority

Aligné JIRA. Convention identique VLT/SD.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-priority.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `low` | Faible — utile mais sans urgence; peut être différé indéfiniment sans conséquence |
| `medium` | Moyenne — par défaut; à traiter dans le cycle normal |
| `high` | Haute — bloque ou ralentit du travail en cours; à traiter rapidement |
| `critical` | Critique — bloquant total ou risque sérieux; interrompre pour traiter |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-priority.md §Valeurs -->

### `vlt-bl-origin` / `sd-bl-origin` — Backlog item provenance

Si `origin: bug`, `linked-bug: "[[VLT-BUG-NNN]]"` est obligatoire dans le frontmatter de l'item (validation par convention humaine).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-origin.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `bug` | Corriger un bug connu — `linked-bug` obligatoire pointe le `[[VLT-BUG-NNN]]` parent |
| `capability` | Ajouter une capability nouvelle (feature, outil, automatisation) |
| `verification` | Tester / auditer / re-vérifier — observation à confirmer ou hypothèse à valider |
| `remediation` | Corriger ou atténuer un problème connu — plus large que `bug` (couvre conventions dérivées, anti-patterns, goulots) |
| `mitigation` | Réduire l’impact d’un risque ou d’un problème sans le résoudre complètement |
| `misc` | Fourre-tout — à éviter mais utile en transition |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bl-origin.md §Valeurs -->

### `vlt-bug-status` — Bug lifecycle (Bugzilla aligné)

Lifecycle: `open → investigating → root-cause-known → fix-designed → fix-deployed → verified → closed`. Sauts permis si critère documenté dans le journal d'investigation.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bug-status.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `open` | Bug créé, pas encore en investigation active |
| `investigating` | Investigation en cours — recherche de cause racine |
| `root-cause-known` | Cause racine identifiée, remédiation pas encore conçue |
| `fix-designed` | Remédiation conçue — backlog item(s) ouvert pour l’implémenter |
| `fix-deployed` | Remédiation déployée — en attente de vérification |
| `verified` | Vérification post-déploiement réussie — N observations sans récurrence |
| `closed` | État terminal — bug fermé pour bonne raison (corrigé ou non-applicable) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bug-status.md §Valeurs -->

### `vlt-bug-severity` — Bug severity (Bugzilla aligné)

`severity` = gravité technique intrinsèque. À distinguer de `priority` (sur VLT-BL) qui est l'urgence de traitement (politique humaine).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bug-severity.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `trivial` | Cosmétique ou pinaillage — aucun impact fonctionnel observable |
| `minor` | Impact mineur — contournable trivialement, faible fréquence |
| `major` | Impact significatif — bloque un cas d’usage, contournable au prix d’effort notable |
| `critical` | Impact critique — bloque un cas d’usage central, pas de contournement viable |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-bug-severity.md §Valeurs -->

### `vlt-inc-status` — Incident lifecycle

Cas particulier : non consommé par INC-template (qui hardcode `status: recorded` à la création, cf. [[SD-ADR-008]]). La fiche existe pour cohérence d'audit et discipline éditoriale (transitions manuelles vers `assigned` ou `superseded`).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-status.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `recorded` | Incident consigné — état initial à la création par INC-template, factuel, sans hypothèse |
| `assigned` | Promu en bug — un VLT-BUG a été ouvert; la fiche INC pointe le bug via `bug:` et reste en lecture seule |
| `superseded` | Remplacé — incident reformulé ou consolidé dans une autre fiche INC ou un bug; `superseded-by:` rempli |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-status.md §Valeurs -->

### `vlt-inc-surface` — Incident surface (Claude interface)

Où l'utilisateur interagit avec Claude au moment de l'incident. La matrice `surface × layer × tool` est la grille de diagnostic primaire.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-surface.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `claude-ai-web` | Interface web claude.ai |
| `claude-ai-mobile` | Interface mobile claude.ai (iOS, Android) |
| `cowork` | Mode Cowork de Claude Desktop (sandbox bash + connecteurs MCP) |
| `desktop-chat` | Conversation Claude Desktop hors mode Cowork |
| `dispatch` | Claude Dispatch (orchestrateur multi-agents) |
| `claude-code` | Claude Code (CLI agentique de codage) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-surface.md §Valeurs -->

### `vlt-inc-layer` — Incident technical layer

Quelle couche technique a manifesté le symptôme. Différent de `surface` (où l'utilisateur interagit).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-layer.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `mcp` | Model Context Protocol — serveurs MCP, outils MCP, transport HTTP/JSON |
| `cli` | Outils en ligne de commande (Claude Code, scripts bash) |
| `skill` | Skills (Cowork ou Claude Code), invocation et runtime |
| `filesystem` | Système de fichiers, montages, chemins, NFC/NFD |
| `uri` | URI / URL / liens profonds (Advanced URI, deeplinks Obsidian) |
| `github` | GitHub, dépôts, issues, PR (lecture/écriture via API ou CLI) |
| `framework` | Framework agent (Claude Agent SDK, runtime conversation, hooks) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-layer.md §Valeurs -->

### `vlt-inc-operation` — Incident operation type

Type fonctionnel de l'opération technique au moment de l'incident. L'outil exact vit dans le champ `tool:` (sœur).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-operation.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `read` | Lecture d’un fichier ou d’une note (get_vault_file, cat, etc.) |
| `write` | Écriture complète (create_vault_file overwrite, fs write) |
| `patch` | Édition ciblée (patch_vault_file, partial update) |
| `delete` | Suppression (delete_vault_file, rm) |
| `search` | Recherche (search_vault_simple, grep, fuzzy search) |
| `list` | Listage de répertoire ou de notes (list_vault_files, ls) |
| `rename` | Renommage / déplacement (move, rename) |
| `config` | Configuration (édition de data.json plugin, settings) |
| `tool-discovery` | Découverte ou invocation d’outils MCP (ToolSearch, list_obsidian_commands) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — vlt-inc-operation.md §Valeurs -->

### `domain` — Functional domain

Co-source de vérité avec `PREFIXES.md` §Registre des domaines (niveau 1). Toute valeur ici doit avoir un préfixe d'identifiants correspondant et inversement.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — domain.md §Valeurs @synced:2026-05-09 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `VLT` | Interface Claude × Organon — gouvernance opérationnelle de l’accès agent au vault. Folder racine: `99 - Méta/Outils/Accès à Obsidian par Claude/`. |
| `SD` | Système documentaire — structure du vault comme artefact de connaissance. Folder racine: `99 - Méta/Système documentaire/`. |
| `FIN` | Finances et patrimoine. Folder racine: `01 - Finances et patrimoine/`. Préfixe d’identifiants actif (cf. [[Préfixes d'identifiants]]); flux Templater dual-mode actif depuis 2026-05-08, **BL uniquement** (pas de FIN-BUG, FIN-INC, FIN-ADR à date — ces shapes n’existent pas dans le domaine finance). |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — domain.md §Valeurs -->

### `topic` — Cross-cutting topic tags (`#topic/*`)

Sujets techniques ou méthodologiques transverses (orthogonal à `#domain/*`). Format : minuscules, ASCII, traits d'union, plat (pas de hiérarchie par `/`). Règle de croissance : ≥2 notes distinctes (ou imminence certaine) + transverse à ≥2 domaines (ou suffisamment spécifique pour mériter filtrage).

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — topic.md §Valeurs @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

| Valeur | Description |
|---|---|
| `api` | Interface programmatique, appels REST ou autres protocoles |
| `architecture` | Conception de systèmes, structure d’un vault ou d’une app |
| `claude` | Fonctionnement, configuration ou comportement de Claude |
| `cli` | Outils en ligne de commande |
| `conventions` | Règles, standards, normes adoptés dans le vault |
| `cowork` | Mode Cowork de Claude Desktop |
| `documentation` | Pratiques et outils de documentation |
| `filesystem` | Système de fichiers, chemins, montages |
| `github` | GitHub, dépôts, PR, issues |
| `identifiers` | Systèmes d’identifiants (VLT-BUG, FIN-DEC, etc.) |
| `mcp` | Model Context Protocol, serveurs MCP |
| `methodology` | Méthodes de travail, approches systématiques |
| `mobile` | Accès mobile, synchronisation iOS/iPadOS |
| `observability` | Logs, monitoring, traçabilité |
| `obsidian` | Obsidian lui-même: plugins, interface, comportement |
| `performance` | Latence, optimisation, benchmarks |
| `plugin` | Plugins Obsidian (développement, configuration, bugs) |
| `runbook` | Procédures opérationnelles, playbooks |
| `serveur` | Infrastructure serveur, déploiement |
| `skills` | Skills Claude Code / Cowork |
| `sync` | Synchronisation iCloud, conflits de fichiers |
| `template` | Gabarits Templater, templates de notes |
| `tooling` | Outillage en général (outils, scripts, automatisation) |
| `upstream` | Contributions amont (OSS, issues GitHub publiques) |
| `uri` | URI, URL, liens profonds (Advanced URI, etc.) |

<!-- VAULT-END: 99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — topic.md §Valeurs -->

---

## Tag namespaces fonctionnels (Organon-curated)

| Namespace | Usage | Exemples |
|---|---|---|
| `source/*` | Origine du contenu | `source/web`, `source/livre`, `source/conversation`, `source/thérapie`, `source/ia` |
| `domain/*` | Domaine fonctionnel | `domain/finance`, `domain/finance/backlog`, `domain/health` |
| `topic/*` | Cross-cutting topic | Voir §`topic` ci-dessus pour les valeurs autorisées |
| `notetype/*` | **Legacy** — en migration vers `type:` | (ne pas en ajouter de nouveaux) |
| `statut/*` | **Legacy** — en migration vers `status:` | (ne pas en ajouter de nouveaux) |

### Tags réservés sans namespace (allowlist explicite)

Liste des tags qui bypassent la règle de namespace parce qu'un plugin tiers matche le literal exact. Case-sensitive.

- `mcp-tools-prompt` — required sur les `.md` dans `Prompts/` (vault root, capital P, no nested) pour exposition comme prompts MCP via `mcp-tools-istefox`. Out-of-folder usage casse le filtre du plugin.

Pas de nouveau tag réservé sans entrée au registre.

## `lang:` — langue de la note

BCP 47. Valeurs courantes : `fr`, `en`, `fr-CA`. Inférable par dossier (cf. `organon-markdown-style` §Langue par dossier — `99 - Méta/AI/` → `en`, autres dossiers → `fr`).

## Person fields (`type: person` only)

Aligné avec schema.org Person, avec extensions Organon pour relations parentales genrées. Pour la table complète : voir `REGISTRE_KEYS.md` §Clés pour `type: person`.

| Champ | Notes |
|---|---|
| `given-name`, `family-name`, `nickname` | (`first-name` legacy → `given-name`) |
| `birth-date`, `death-date` | YYYY-MM-DD |
| `gender` | Optionnel (recommandé : `male`, `female`, `non-binary`, autre) |
| `father`, `mother` | Extension Organon (vs schema.org `parent` neutre) |
| `children`, `sibling`, `spouse` | Standard schema.org |

## Book fields (`type: book` only)

Aligné avec schema.org Book. Pour la table complète : voir `REGISTRE_KEYS.md` §Clés pour `type: book`.

- `title` : titre du livre (peut différer du `title:` Organon — voir §Règle title Option C dans SKILL.md).
- `author` : auteur du livre (≠ `creator:` qui est l'auteur de la note Organon).
- `date-published`, `isbn`, `in-language` : tous optionnels.

## Validation

Toute nouvelle clé doit avoir une entrée dans `[[Registre des clés de frontmatter]]` (vault) avant utilisation — voir `REGISTRE_KEYS.md` pour le snapshot. Toute extension d'un vocabulaire fermé existant doit être soumise au registre vault et propagée par re-sync (`scripts/sync-vault.sh`).
