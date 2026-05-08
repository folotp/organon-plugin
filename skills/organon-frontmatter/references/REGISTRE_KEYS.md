# Registre des clés de frontmatter — Absorbed from vault

Verbatim copy of the body of vault note `99 - Méta/Système documentaire/Registre des clés de frontmatter.md`. The vault file is **authoritative on disagreement**: if this absorbed copy and the vault diverge, trust the vault.

See `vault-sync.json` for sync metadata (`body_sha256`, `synced_at_date`) and `scripts/sync-vault.sh` for the re-sync workflow. To re-derive after the vault file evolves: re-run the sync script, replace the bytes between markers below, update the JSON entry.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Registre des clés de frontmatter.md (full body) @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

## Registre des clés de frontmatter

**Portée.** Registre autoritaire de toutes les clés de frontmatter en usage dans Organon. Pour chaque clé: description, portée (notes concernées), obligatoire ou non, type de valeur, vocabulaire contrôlé s’il y a lieu, standard adopté, position de tri Linter. Ne couvre pas la politique (règles de nommage, de casse, de langue) — voir [[Conventions Obsidian#Politique de frontmatter]].

**Gouvernance.** Aucune clé nouvelle n’est introduite sans ligne correspondante dans ce registre. Les clés non documentées sont signalées comme dérive lors des audits (voir [[Plan — LLM-friendly conventions rollout]] Phase 5).

**Vocabulaires contrôlés.** Pour chaque clé de type `enum` listée ci-dessous, la **liste autoritaire de valeurs** vit dans une note vocabulaire dédiée sous `99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — <key>.md`. Ces vocabulaires s’appliquent **partout dans le vault**, peu importe le consommateur (Templater à la création, Linter à la validation, Bases au filtrage, audits de cohérence). La colonne « Vocabulaire » des tableaux ci-dessous est une vue lisible des valeurs en usage à la date de modification; en cas de divergence, la note vocabulaire fait foi. Discipline d’édition: ajouter une valeur à un enum = éditer la note vocabulaire + ajuster cette ligne du Registre dans la même unité de travail.


### Légende

- **Portée**: `global` = toute note; `type X` = notes de type X uniquement; `domaine Y` = notes du domaine Y.
- **Obligatoire**: `oui` (toujours), `non` (optionnel), `conditionnel` (règle dépendant d’une autre valeur).
- **Type**: `string`, `list<string>`, `date`, `datetime`, `wikilink`, `list<wikilink>`, `bool`, `number`, `enum`.
- **Standard**: DCMI, schema.org, Pandoc, SSG (convention générateur de site statique), Bugzilla, Obsidian (convention du plugin Obsidian), Organon (extension propre), BCP 47, ISO 8601.


### Clés globales (toute note)

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `title` | Titre humain descriptif de la note. Pour les notes avec code de référence, doit débuter par le code (`"FIN-DEC-090 — Titre…"`). Ne correspond plus nécessairement au filename (Option C, 2026-04-23). | oui | string | libre; préfixe code si applicable | Pandoc, SSG |
| `aliases` | Noms alternatifs. Pour les notes codées, le premier alias est le code seul (ex. `FIN-DEC-090`) pour les wikilinks courts. | non | list\<string\> | libre | Obsidian |
| `description` | Phrase résumant la portée (scope line); recommandé au-delà de ~500 mots | non | string | libre | DCMI, schema.org |
| `type` | Type de note; détermine filing et contrat structurel | oui | enum | voir ci-dessous | Organon (ex-tag `notetype/*`) |
| `content-model` | Contrat structurel orthogonal au type (ex-`shape`, renommé 2026-04-25) | non | enum | voir ci-dessous | Organon (terme aligné IA — Karen McGrane / Cleve Gibbon) |
| `lang` | Langue principale de la note | non | string | BCP 47 | BCP 47 |
| `creator` | Auteur de la note Organon elle-même | non | string | libre | DCMI (`dc:creator`) |
| `created` | Date de création | oui | datetime | `YYYY-MM-DD HH:mm` | DCMI, ISO 8601 |
| `modified` | Date de dernière modification | oui | datetime | `YYYY-MM-DD HH:mm` | DCMI, ISO 8601 |
| `ulid` | Identifiant unique stable (ULID — Universally Unique Lexicographically Sortable Identifier). Généré automatiquement à la création. 26 caractères Crockford base32, trié par timestamp. Forward-only: les notes créées avant 2026-04-23 n’en ont pas. | non | string | ULID (26 chars) | Organon (décidé 2026-04-23, [[SD-BL-0028]]) |
| `status` | État dans le cycle de vie; vocabulaire selon domaine | non | enum | voir sections domaines | Bugzilla / Organon |
| `archived` | Flag d’archivage; orthogonal au statut | non | bool | `true` / `false` | Organon |
| `archived-date` | Date de mise en archive | conditionnel (requis si `archived: true`) | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `closed-date` | Date à laquelle un item a été fermé ou complété | conditionnel (recommandé si `status: done \| closed`) | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `last-reviewed` | Date de la dernière révision/audit du contenu (utile pour outils, runbooks, références où la « fraîcheur » importe). Adopté 2026-05-05 ([[FIN-BL-0107]]). | non | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `next-review` | Date prévue de la prochaine révision. Complément de `last-reviewed`. Adopté 2026-05-05 ([[FIN-BL-0107]]). | non | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `cadence` | Fréquence de révision/exécution d’un processus récurrent (runbooks, audits, revues). Adopté 2026-05-05 ([[FIN-BL-0107]]). | non | enum | `on-demand` \| `monthly` \| `quarterly` \| `annually` | Organon |
| `date` | Date du contenu/événement décrit par la note (distincte de `created` et `modified`). Utilisée pour incidents (date d’occurrence), états (date du snapshot), événements datés. Élargie 2026-05-05 ([[FIN-BL-0107]]) au-delà du seul VLT-INC. | conditionnel (selon le type de note) | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `tags` | Tags fonctionnels (source, domaine, topic) | non | list\<string\> | namespaces définis | Obsidian, SSG |
| `up` | Note(s) parent(s) | non | list\<wikilink\> | wikilink(s) | Organon |
| ~~`down`~~ | ~~Note(s) enfant(s)~~ | — | — | — | **Déprécié 2026-05-03** ([[SD-BL-0027]]); voir §Clés retirées |
| `same` | Note(s) de même niveau sur le même sujet | non | list\<wikilink\> | wikilink(s) | Organon |
| `next` | Note suivante dans une séquence | non | wikilink | wikilink | Organon |
| `previous` | Note précédente dans une séquence | non | wikilink | wikilink | Organon |
| `superseded-by` | Remplacée par la note référencée. **Dual usage**: (a) remplacement catégoriel (une note en remplace une autre, `status: superseded`); (b) versioning (avec `version:`, pointe la version suivante). Contexte distingué par présence de `version:`. | conditionnel (si `status: superseded` ou si note versionnée) | wikilink | wikilink | DCMI (`dc:isReplacedBy`) |
| `review` | Date prévue de revue | non | date | `YYYY-MM-DD` | Organon |
| `obsidianUIMode` | Mode UI préféré pour cette note (système) | non | enum | `preview` / `source` | Obsidian (interne) |

#### Vocabulaire `type`

```
note | concept | person | book | quote | index | organization | journal | ai
| hypothesis | rule | tool | template | runbook | reference | plan
```

- `note` — catch-all pour notes générales qui ne rentrent pas dans une catégorie plus spécifique.
- `concept` — définition atomique d’un terme, idée, phénomène.
- `person` — profil d’une personne physique.
- `book` — note de lecture d’un livre.
- `quote` — citation collectée.
- `index` — hub de navigation (MOC).
- `organization` — profil d’une organisation.
- `journal` — journal daté append-only (daily note, réunion, log d’incidents).
- `ai` — note de configuration/bootstrap du système IA dans `99 - Méta/AI/`.
- `hypothesis` — proposition de modélisation à valider (planification, recherche, calibration). Promue 2026-05-05 ([[FIN-BL-0107]]).
- `rule` — règle opérationnelle dérivée de décisions, applicable à un système ou un contexte. Promue 2026-05-05 ([[FIN-BL-0107]]).
- `tool` — outil externe (logiciel, API, service) référencé pour usage interne. Promue 2026-05-05 ([[FIN-BL-0107]]).
- `template` — gabarit Templater ou squelette réutilisable. Promue 2026-05-05 ([[FIN-BL-0107]]).
- `runbook` — procédure opérationnelle exécutable (révision, audit, sauvegarde). Promue 2026-05-05 ([[FIN-BL-0107]]).
- `reference` — source canonique de fait(s) ou de spécification. Distincte de `note` générale par sa fonction de source de vérité. Promue 2026-05-05 ([[FIN-BL-0107]]).
- `plan` — document de planification (financière, projet, stratégique). Promue 2026-05-05 ([[FIN-BL-0107]]).

#### Vocabulaire `content-model`

```
atomic | reference | narrative | journal | moc
```

- `atomic` — une question, une décision, une entité. Budget ~200–400 mots.
- `reference` — source de vérité canonique multi-sections. Budget ~500–1500 mots.
- `narrative` — prose longue (plan, essai, argument). Pas de plafond strict; les faits vivent ailleurs.
- `journal` — chronologique, append-only, daté par entrée.
- `moc` — routage par liens, prose minimale.

Détails et contrats de forme par valeur (size budget, shape contract): voir [[LLM-Friendly Note Principles#Per-note structure]]. Le livrable autonome `Types de notes et contrats.md` planifié en Phase 3 a été annulé 2026-05-04 — vocabulaire ici, contrats là.

Note historique: la clé s’appelait `shape:` jusqu’au 2026-04-25; renommée en `content-model:` (alignement IA — Karen McGrane / Cleve Gibbon). Sémantique inchangée. Migration des notes en production: actée.

#### Vocabulaire `status`

Voir [[Conventions Obsidian#Vocabulaire unifié de status]] pour la liste complète et la sémantique. Les listes fermées par domaine apparaissent dans les sections correspondantes ci-dessous.

**Valeur `active`** — adoptée 2026-05-05 ([[FIN-BL-0107]]) au vocabulaire global pour les notes-standards (hypothèses, règles, outils, runbooks, références) qui sont « en vigueur / opérationnelles ». Distincte de `accepted` (réservée aux décisions et ADR) et `done` (réservée aux items de backlog complétés).


### Clés pour `type: person`

Alignement schema.org Person avec les extensions Organon pour le genre des relations familiales.

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `given-name` | Prénom | non | string | libre | schema.org (`givenName`) |
| `family-name` | Nom de famille | non | string | libre | schema.org (`familyName`) |
| `nickname` | Surnom courant | non | string | libre | FOAF, vCard |
| `birth-date` | Date de naissance | non | date | `YYYY-MM-DD` | schema.org (`birthDate`), ISO 8601 |
| `death-date` | Date de décès | non | date | `YYYY-MM-DD` | schema.org (`deathDate`), ISO 8601 |
| `gender` | Identité de genre | non | string | libre (recommandé: `male`, `female`, `non-binary`, autre) | schema.org |
| `father` | Père (wikilink) | non | wikilink | wikilink | Organon (extension genrée de schema.org `parent`) |
| `mother` | Mère (wikilink) | non | wikilink | wikilink | Organon |
| `children` | Enfants | non | list\<wikilink\> | wikilinks | schema.org |
| `sibling` | Frères / sœurs | non | list\<wikilink\> | wikilinks | schema.org |
| `spouse` | Conjoint(e) | non | list\<wikilink\> | wikilinks | schema.org |


### Clés pour `type: book`

Alignement schema.org Book.

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `title` | Titre du livre (aussi le titre de la note) | oui | string | libre | schema.org (`name`), Pandoc |
| `author` | Auteur du livre (non l’auteur de la note — voir `creator`) | non | string | libre | schema.org (`author`) |
| `date-published` | Date de publication | non | date ou année | `YYYY-MM-DD` ou `YYYY` | schema.org (`datePublished`), ISO 8601 |
| `isbn` | Numéro ISBN (de préférence ISBN-13) | non | string | ISBN-13 ou ISBN-10 | schema.org |
| `in-language` | Langue du livre | non | string | BCP 47 | BCP 47 |


### Clés pour le domaine finance (`01 - Finances et patrimoine/`)

#### Notes de décision (`FIN-DEC-NNNN`)

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable (match du nom de fichier) | oui | string | `FIN-DEC-NNNN` | Organon |
| `date-decided` | Date à laquelle la décision a été prise | oui | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `status` | État de la décision | oui | enum | `proposed` \| `accepted` \| `rejected` \| `superseded` \| `deprecated` (canon ADR aligné [[FIN-BL-0108]] et [[SD-ADR-011]]) | Organon (Nygard 2011) |
| `references` | Notes référencées par cette décision | non | list\<wikilink\> | wikilinks | Organon |

**Note.** Vocabulaire harmonisé sur le canon ADR (5 valeurs) le 2026-05-05 par [[FIN-BL-0108]]. Audit 2026-05-05: 81 fiches `accepted`, 1 drift `active` (FIN-DEC-014 — résolu indirectement par [[SD-ADR-011]] qui a basculé 014 à `superseded`). Aucune valeur française legacy (`Proposée` / `Acceptée` / `Remplacée` / `Retirée`) observée en pratique — sweep batch initialement prévu rendu sans objet.

#### Autres sous-domaines finance

Les sous-domaines `Standards/Hypothèses/` (`FIN-HYP-NNN`, `type: hypothesis`), `Standards/Outils/` (`FIN-TOOL-*`, `type: tool`), `Standards/Règles/` (`FIN-RULE-*`, `type: rule`), `Standards/Références/` (`FIN-REF-*`, `type: reference`), `Backlog/Items/` (`FIN-BL-NNNN`, `type: note`), `États/` (`FIN-ETAT-YYYY-MM-DD`, `type: state-snapshot` à promouvoir au global ultérieurement), et `Runbooks/` (`FIN-RB-NNN`, `type: runbook`) utilisent le frontmatter global avec un champ `id:` conforme au préfixe du sous-domaine.

**Aucun champ frontmatter FIN-spécifique** depuis 2026-05-05 ([[FIN-BL-0107]]) — toute classification thématique passe par les `tags:` (namespaces `topic/finance/<area>`, `topic/system/<name>`, `topic/item-type/<value>`). Les anciens champs FIN-locaux (`domain`, `item-type`, `tool-type`, `target-type`, `scope`, `category`, `related-decisions`, `snapshot-date`) sont migrés vers tags / clés globales / drops — voir §Clés retirées.


### Clés pour le domaine VLT (`99 - Méta/Outils/Accès à Obsidian par Claude/`)

#### Incidents (`VLT-INC-NNNN`)

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable | oui | string | `VLT-INC-NNNN` | Organon |
| `type` | Type de fiche | oui | enum | `incident` | Organon (domaine) |
| `date` | Date de l’incident | oui | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `surface` | Surface Claude où l’incident est survenu | oui | enum | `claude-ai-web` \| `claude-ai-mobile` \| `cowork` \| `desktop-chat` \| `dispatch` \| `claude-code` | Organon |
| `layer` | Couche technique concernée (ex-`couche`) | oui | enum | `mcp` \| `cli` \| `skill` \| `filesystem` \| `uri` \| `github` \| `framework` | Organon |
| `tool` | Nom exact de l’outil ou commande (ex-`outil`) | oui | string | libre | Organon |
| `operation` | Type d’opération | oui | enum | `read` \| `write` \| `patch` \| `delete` \| `search` \| `list` \| `rename` \| `config` \| `tool-discovery` | Organon |
| `status` | État de la fiche | oui | enum | `recorded` \| `assigned` \| `superseded` | Organon |
| `bug` | Bug associé (wikilink) | non | wikilink | `"[[VLT-BUG-NNN]]"` | Organon |

#### Bugs (`VLT-BUG-NNN`)

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable | oui | string | `VLT-BUG-NNN` | Organon |
| `type` | Type de fiche | oui | enum | `bug` | Organon |
| `status` | État dans le cycle de vie | oui | enum | `open` \| `investigating` \| `root-cause-known` \| `fix-designed` \| `fix-deployed` \| `verified` \| `closed` | Bugzilla |
| `severity` | Sévérité | oui | enum | `trivial` \| `minor` \| `major` \| `critical` | Bugzilla |
| `component` | Composant affecté (ex-`composant`) | non | string | `COMP-NNN` | Organon |
| `first-incident` | Premier incident observé (ex-`premier-incident`) | non | wikilink | `"[[VLT-INC-NNNN]]"` | Organon |
| `last-occurrence` | Dernière occurrence (ex-`dernière-occurrence`) | non | wikilink | `"[[VLT-INC-NNNN]]"` | Organon |

#### Backlog (`VLT-BL-NNNN`)

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable | oui | string | `VLT-BL-NNNN` | Organon |
| `type` | Type de fiche | oui | enum | `backlog` | Organon |
| `status` | État | oui | enum | `open` \| `planned` \| `in-progress` \| `done` \| `verified` \| `abandoned` | JIRA / Organon |
| `priority` | Priorité (ex-`priorité`) | oui | enum | `low` \| `medium` \| `high` \| `critical` | JIRA |
| `effort` | Estimation d’effort | non | string | libre (ex. `15 min`, `1 h`, `1 journée`) | Organon |
| `origin` | Origine de l’item (ex-`origine`) | oui | enum | `bug` \| `capability` \| `verification` \| `remediation` \| `mitigation` \| `misc` | Organon |
| `linked-bug` | Bug associé si `origin: bug` (ex-`bug-lié`) | conditionnel (si `origin: bug`) | wikilink | `"[[VLT-BUG-NNN]]"` | Organon |

### Clés pour le domaine SD (`99 - Méta/Système documentaire/`)

#### Backlog (`SD-BL-NNNN`)

Backlog du système documentaire d’Organon. Créé par [[SD-ADR-006]] en miroir de VLT-BL. Convention identique à VLT-BL, seul le préfixe d’ID et le folder diffèrent. Méthodologie partagée: voir [[Méthodologie — Incidents, bugs et backlog]].

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable | oui | string | `SD-BL-NNNN` | Organon |
| `type` | Type de fiche | oui | enum | `backlog` | Organon (domaine) |
| `status` | État | oui | enum | `open` \| `planned` \| `in-progress` \| `done` \| `verified` \| `abandoned` | JIRA / Organon |
| `priority` | Priorité | oui | enum | `low` \| `medium` \| `high` \| `critical` | JIRA |
| `effort` | Estimation d’effort | non | string | libre (ex. `15 min`, `1 h`, `1 journée`) | Organon |
| `origin` | Origine de l’item | oui | enum | `bug` \| `capability` \| `verification` \| `remediation` \| `mitigation` \| `misc` | Organon |
| `linked-bug` | Bug associé si `origin: bug` | conditionnel (si `origin: bug`) | wikilink | `"[[VLT-BUG-NNN]]"` | Organon |

**Note de cohabitation.** Les flux d’incidents (`SD-INC`) et de bugs (`SD-BUG`) ne sont pas créés à ce stade — le système documentaire n’a pas démontré de besoin observé. Si un besoin émerge, créer les sections correspondantes et signaler dans [[SD-ADR-006#Mise en œuvre]].

### Clés pour les ADR (`VLT-ADR-NNN` et `SD-ADR-NNN`)

ADR (*Architecture Decision Records*). Domaines: interface Claude × Organon (`VLT-ADR`, sous `99 - Méta/Outils/Accès à Obsidian par Claude/ADR/`) et système documentaire (`SD-ADR`, sous `99 - Méta/Système documentaire/ADR/`). Méthodologie partagée: voir [[Méthodologie — ADR]].

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `id` | Identifiant stable (match du nom de fichier) | oui | string | `VLT-ADR-NNN` ou `SD-ADR-NNN` (3 chiffres) | Organon |
| `date-decided` | Date à laquelle la décision a été prise (ou backfillée si rétroactive) | oui | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `status` | État du cycle de vie ADR | oui | enum | `proposed` \| `accepted` \| `rejected` \| `superseded` \| `deprecated` | Organon (Nygard 2011) |
| `references` | Notes référencées par cette décision | non | list\<wikilink\> | wikilinks | Organon |
| `supersedes` | ADR remplacé par celui-ci | conditionnel (si chaîne de supersession) | wikilink | `"[[<PRÉFIXE>-ADR-NNN]]"` | Organon |

`superseded-by:` est déjà documentée dans les clés globales. La paire `supersedes:` / `superseded-by:` opère ici comme dans le domaine finance.

**Note sur les statuts.** Les valeurs `proposed` et `deprecated` sont introduites par les ADR; les valeurs `accepted`, `rejected`, et `superseded` sont partagées avec d’autres domaines (FIN-DEC notamment). Voir le tableau global des statuts dans [[Vault Conventions#Status vocabulary]].

**Champs `amends:` / `amended-by:` dépréciés** (2026-05-05, [[SD-ADR-011]]). Anciennement observés en pratique sur `FIN-DEC` (amendement partiel sans supersession complète). Le pattern unique adopté pour les ADR et FIN-DEC est désormais la **supersession complète**: tout changement à une décision `accepted` produit un nouvel ADR / FIN-DEC autonome qui supersede l’ancien (`supersedes:` / `superseded-by:`). Voir §Clés retirées et [[Méthodologie — ADR#Immutabilité et supersession]].


### Clés pour notes versionnées

Ensemble de clés spécifiques aux notes gérant un **cycle de vie versionné formel** (ex. [[Modèle opérationnel — Claude × Organon]]). Ces clés sont **orthogonales** aux clés globales de cycle de vie (`status`, `archived`). La distinction est: une note versionnée évolue via des versions successives datées (v1.0 → v1.1 → v2.0); l’ancienne version passe en `status: superseded` et pointe la nouvelle via `superseded-by:`.

| Clé | Description | Obligatoire | Type | Vocabulaire | Standard |
|---|---|---|---|---|---|
| `version` | Numéro de version sémantique `MAJOR.MINOR`. **Obligatoirement quoté** en YAML pour éviter coerce en Float (`"1.0"`). MAJOR = changement incompatible; MINOR = ajout rétro-compatible. | conditionnel (si note versionnée) | string | `"MAJOR.MINOR"` quoté | Organon (semver adapté) |
| `issued` | Date de publication de la version courante. Distinct de `created` (création de la note) et `modified` (dernier touch du fichier). | conditionnel (si note versionnée) | date | `YYYY-MM-DD` | Organon, ISO 8601 |
| `supersedes` | Note / version remplacée par celle-ci (pointeur inverse de `superseded-by`). Sur la nouvelle version v1.1, `supersedes: "[[Modèle opérationnel — Claude × Organon (v2026-04-24)]]"`. `null` si c’est la première version. | conditionnel (si note versionnée ≠ v1.0 initiale) | wikilink \| null | wikilink | Organon |

La clé `superseded-by` (déjà dans les clés globales) complète ce triplet: sur l’ancienne version, elle pointe la nouvelle.

**Gouvernance de cycle versionné** (convention documentée sur la note pointeur stable de chaque famille versionnée, ex. [[Modèle opérationnel — Claude × Organon]]):

1. Nouvelle version créée comme `(vYYYY-MM-DD).md` avec `status: draft`.
2. Vérification, itérations draft-rev possibles sans bump de version.
3. Bascule active: ancienne → `status: superseded` + `superseded-by:` rempli; nouvelle → `status: active`; note pointeur mise à jour pour pointer la nouvelle.
4. Versions superseded **restent en place** (pas d’archivage hors dossier); historique conservé.

**Scope actuel**: conventions utilisées exclusivement sur les notes pivots d’architecture (Modèle opérationnel et siblings hypothétiques). **Pas de vocation** à s’étendre à l’ensemble du vault — les notes non-versionnées (majorité) n’ont pas besoin de ces clés.


### Tri Linter canonique

L’ordre de tri dans la configuration `yaml-key-sort` du plugin Linter est (dans cet ordre):

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
down
previous
next
same
tags
```

Les clés en tête (`title`, `aliases`, `description`, `type`, `content-model`, `lang`) sont les plus consultées et apparaissent en premier. `ulid` suit `id` (identité stable de la note). L’authorship et les timestamps système sont regroupés (`creator`, `created`, `modified`), puis le cycle de vie (`status`, `archived`, `archived-date`, `closed-date`), puis les relations navigationnelles. Les tags sont toujours en dernier.

**Note sur `yaml-title`.** La règle Linter `yaml-title` (mode `filename`) est **désactivée** depuis 2026-04-23 (décision [[SD-BL-0029]], Option C). Le champ `title:` est désormais le titre humain descriptif, non contraint à égaler le filename. Voir [[Vault Conventions#Règle title]] pour la convention en vigueur. **Action manuelle requise**: dans Obsidian → Settings → Linter → Rules → YAML → YAML Title → désactiver la règle.

**Action manuelle requise (2026-04-25)**: dans `.obsidian/plugins/obsidian-linter/data.json`, dans le tableau `ruleConfigs["yaml-key-sort"]["yaml-key-priority-sort-order"]`, remplacer l’entrée `shape` par `content-model` (même position: entre `type` et `lang`). Sans cette mise à jour, le Linter retombera sur le tri alphabétique pour cette clé et placera `content-model` au mauvais endroit lors de la prochaine sauvegarde, écrasant le tri canonique. Cf. mémoire `organon_linter_config_path.md`.


### Clés retirées (migration actée)

Clés définitivement retirées ou dont la migration en production est actée.

| Clé | Remplacée par | Note |
|---|---|---|
| `shape` | `content-model` | Renommée 2026-04-25. 19 notes migrées. 4 mentions prose de basse priorité résiduelles (VLT-BL-0017, VLT-BL-0032, deux Prompt Desktop Chat test H10*). |
| `first-name` (kebab) | `given-name` | Migré (Linter `remove-yaml-keys`). |
| `last-name` (kebab) | `family-name` | Migré (même raison). |
| `date updated` (espace) | `modified` | Jamais observée en production; conservée dans Linter `remove-yaml-keys`. |
| Tag `notetype/archive` | `archived: true` + `archived-date:` | Migré. |
| Tag `notetype/personne` | `type: person` | Migré. |
| `section-source` | — | Supprimée Phase 4B. 178 occurrences supprimées. |
| `legacy-q-id` | — | Supprimée Phase 4B. |
| `legacy-id` | — | Supprimée Phase 4B. |
| `down` | — | Déprécié (backlinks Bases suffisent). Retiré des 2 notes portantes 2026-05-03 ([[SD-BL-0027]]). À retirer du tri Linter. |
| `amends` | `supersedes` (via supersession complète) | Déprécié 2026-05-05 ([[SD-ADR-011]]). Anciennement utilisé sur 2 chaînes FIN-DEC (014↔072, 024↔078). Migration rétroactive: chaîne 1 convertie en supersession; chaîne 2 (sémantiquement complémentaire, pas amendement) convertie en `references:`. |
| `amended-by` | `superseded-by` (via supersession complète) | Déprécié 2026-05-05 ([[SD-ADR-011]]). Migration co-traitée avec `amends`. |
| `domain` | `tags:` namespace `topic/finance/<area>` | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 115 occurrences (108 FIN-BL + 7 FIN-REF) migrées vers tags multi-value. Drop pur, pas de rename — la classification thématique passe désormais par le namespace `topic/*` existant. Évite la collision sémantique avec runtime template arg `tp.user.domain`. |
| `item-type` | `tags:` namespace `topic/item-type/<value>` (drop valeur `backlog`) | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 108 occurrences FIN-BL migrées; valeurs utiles `maintenance`, `recurring`, `decision-pending`, `parking` deviennent tags. Valeur `backlog` (68 fiches) droppée — redondante avec folder `Backlog/Items/`. Valeur FR `décision à prendre` harmonisée vers `decision-pending`. |
| `tool-type` | (suppression — redondant avec ID prefix) | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 19 occurrences FIN-TOOL droppées. L’info est déjà dans le préfixe ID (`FIN-TOOL-PL-*` = projectionlab, `FIN-TOOL-XL-*` = excel, etc.). |
| `target-type` | (suppression — redondant avec filename) | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 6 occurrences FIN-TOOL-GAB droppées. L’info est dans le filename des templates (`Gabarit — Règle.md`, etc.). |
| `scope` | (suppression — redondant avec ID prefix) | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 10 occurrences FIN-RULE droppées (toutes valeur `ynab`, déjà encodée dans ID `FIN-RULE-YNAB-*`). |
| `category` | `tags:` namespace `topic/finance/hypothesis/<category>` | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 13 occurrences FIN-HYP migrées vers tags. Valeurs FR migrées vers EN canonique (`marché → market`, `frais → fees`, `fiscalité → taxation`, `longévité → longevity`, etc.). |
| `related-decisions` | `references` | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 10 occurrences FIN-RULE migrées vers `references:` (clé globale existante avec sémantique identique). Rename pur. |
| `snapshot-date` | `date` (sémantique élargie) | Déprécié 2026-05-05 ([[FIN-BL-0107]]). 5 occurrences FIN-ETAT migrées vers `date:` (clé globale élargie pour couvrir « date du contenu/événement décrit »). |

### Clés en migration (vault-wide non terminé)

| Clé | Remplacée par | Périmètre | Statut |
|---|---|---|---|
| `date created` (espace) | `created` | Global | À migrer vault-wide |
| `date modified` (espace) | `modified` | Global | À migrer vault-wide |
| `author` (auteur de note) | `creator` | Global | À migrer vault-wide |
| `first name` (espace) | `given-name` | Personnes | À migrer |
| `last name` (espace) | `family-name` | Personnes | À migrer |
| `date-of-birth` | `birth-date` | Personnes | À migrer |
| `date-of-death` | `death-date` | Personnes | À migrer |
| `child` (singulier) | `children` | Personnes | À migrer |
| `book-title` | `title` | Livres | À migrer |
| `book-author` | `author` | Livres | À migrer |
| `book-publishing-date` | `date-published` | Livres | À migrer |
| `couche` | `layer` | VLT | À migrer |
| `outil` | `tool` | VLT | À migrer |
| `composant` | `component` | VLT | À migrer |
| `premier-incident` | `first-incident` | VLT | À migrer |
| `dernière-occurrence` | `last-occurrence` | VLT | À migrer |
| `priorité` | `priority` | VLT | À migrer |
| `origine` | `origin` | VLT | À migrer |
| `bug-lié` | `linked-bug` | VLT | À migrer |
| `supersedes` (frontmatter) | Lien typé dans le corps | Global (notes canoniques) | À migrer |
| `prev` | `previous` | Global | À migrer si présent |
| Namespace tag `#statut/*` | Champ `status:` | Global | À migrer vault-wide |


### Questions ouvertes

- ~~Liste complète des valeurs `status` en usage dans FIN decisions~~ — résolu 2026-05-05 par [[FIN-BL-0108]] (canon ADR adopté: `proposed | accepted | rejected | superseded | deprecated`).
- Stratégie de backfill pour `archived-date` sur les notes actuellement en `_Archives/` sans date connue: date système (`modified`) comme proxy, ou sentinelle (`1970-01-01`) explicite.

### Décisions historiques

- **Migration Dataview inline** (`Up::`, `Same::`, `Cross::`) → YAML. Résolu 2026-05-03: 154 notes migrées, syntaxe inline formellement bannie ([[SD-BL-0027]]).
- **UUID auto-généré**. Résolu 2026-04-23: ULID forward-only adopté ([[SD-BL-0028]]).
- **Règle `title == filename`**. Résolu 2026-04-23: Option C (dual découplé) adoptée ([[SD-BL-0029]]).


### Liens

- Parent: [[Conventions Obsidian]]
- Voisines: [[Vocabulaire — domain]], [[Préfixes d'identifiants]]
- Référence: [[SD-ADR-009]] (externalisation vocabulaires contrôlés)

### Journal

| Date | Changement |
|---|---|
| 2026-05-04 | Drop narrative de migration `shape` → `content-model` (condensée en 1 ligne). Décomposition §Clés retirées / §Clés en migration. Déplacement des questions résolues vers §Décisions historiques. Remplacement §Vocabulaires contrôlés (drop framing Templater comme propriétaire). Ajout §Liens. Wave B doc cleanup. |
| 2026-05-05 | [[SD-ADR-011]]: `amends:` / `amended-by:` ajoutés à §Clés retirées; note §FIN-DEC `amends:` reportée remplacée par pointeur de dépréciation. [[FIN-BL-0108]]: enum `status:` FIN-DEC étendu au canon ADR (`proposed | accepted | rejected | superseded | deprecated`); §Questions ouvertes mise à jour (résolution). |
| 2026-05-05 | [[FIN-BL-0107]] exécution intégrale (D1-D5). Promotions globales: `last-reviewed`, `next-review`, `cadence`, `date` ajoutées; vocab `type:` étendu à 16 valeurs (+ 7 hypothesis/rule/tool/template/runbook/reference/plan); valeur `active` ajoutée au vocab `status:` global. Retraits FIN: `domain`, `item-type`, `tool-type`, `target-type`, `scope`, `category`, `related-decisions`, `snapshot-date` documentés à §Clés retirées avec leurs cibles de migration (tags / clés globales / drops). Tri Linter étendu (`last-reviewed`, `next-review`, `cadence`). |
<!-- VAULT-END: 99 - Méta/Système documentaire/Registre des clés de frontmatter.md (full body) -->
