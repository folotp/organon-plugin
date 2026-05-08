# Préfixes d'identifiants — Absorbed from vault

Verbatim copy of the body of vault note `99 - Méta/Système documentaire/Préfixes d'identifiants.md`. The vault file is **authoritative on disagreement**.

See `vault-sync.json` for sync metadata and `scripts/sync-vault.sh` for the re-sync workflow. To re-derive after the vault file evolves: re-run the sync script, replace the bytes between markers below, update the JSON entry.

<!-- VAULT-BEGIN: 99 - Méta/Système documentaire/Préfixes d'identifiants.md (full body) @synced:2026-05-08 -->
<!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

## Objet

Registre **central** des préfixes d’identifiants utilisés dans Organon pour nommer les items atomiques (décisions, règles, incidents, bugs, backlog, etc.) et prévenir les collisions lorsqu’un nouveau domaine adopte le modèle.

Cette note est la source de vérité **des préfixes d’identifiants** (`<DOMAIN>-<TYPE>-NNNN`):

- Quels préfixes de domaine sont alloués.
- Quelles sous-familles de type existent dans chaque domaine.
- Le protocole pour en créer de nouveaux.

Pour les **valeurs autorisées de la clé frontmatter `domain:`**, voir [[Vocabulaire — domain]] (note vocabulaire dédiée). Les deux notes doivent rester cohérentes — chaque préfixe actif ici doit avoir sa valeur dans le vocabulaire, et inversement.

Tout ajout de préfixe doit passer par ici pour éviter les collisions silencieuses (exemple hypothétique à éviter: deux domaines qui inventent `OBS-001` pour des items incompatibles).

## Principes

1. **Préfixe = domaine, pas outil.** `VLT` (Vault) vaut mieux que `OBS` (Obsidian): si Organon migre un jour hors Obsidian, l’ID reste valide. `FIN` (Finance) vaut mieux que `YNAB` ou `EXCEL`: les outils changent, le domaine persiste.
2. **Stabilité.** Un ID ne change jamais. Si un item change de catégorie, on crée un nouvel ID et on note la redirection dans le journal de la note.
3. **Atomicité.** Chaque ID correspond à **une fiche dédiée** (un fichier `.md`). L’ID est le `file.name` (sans extension). Les registres/journaux ne contiennent pas le contenu, seulement des liens — typiquement via un `.base` dynamique.
4. **Structure à 2 ou 3 niveaux**: `DOMAIN-TYPE-NNN` pour le cas simple, `DOMAIN-TYPE-SUBTYPE-NNN` quand un type est assez dense pour mériter une subdivision.
5. **Largeur de numéro** calibrée sur le volume attendu: 3 chiffres (jusqu’à 999) par défaut; 4 chiffres (jusqu’à 9999) pour les familles à haute volumétrie (backlog, incidents).
6. **Bloc-référence Obsidian** stable: chaque fiche déclare `^<ID>` juste sous le titre, pour permettre `[[Note#^ID]]` même si le titre change.

## Registre des domaines (niveau 1)

| Préfixe | Domaine | Portée | Note d’index | Statut |
|---|---|---|---|---|
| `FIN` | Finances et patrimoine | Toutes les fiches atomiques du dossier `01 - Finances et patrimoine/` | [[Index des standards financiers]] | Actif |
| `VLT` | Vault (Organon comme système) | Incidents, bugs, backlog liés au vault et à ses outils. Inclut l’accès par Claude et les problèmes d’infrastructure du vault lui-même. | [[Index — Accès à Obsidian par Claude]] | Actif |
| `SD` | Système documentaire (Organon comme système d’organisation des notes) | Décisions architecturales (`SD-ADR`) et items de backlog (`SD-BL`) liés à la structure du vault, aux conventions, aux méthodologies. Folder racine: `99 - Méta/Système documentaire/`. | [[Mon système documentaire]] | Actif |
| `SPA` | Spa (piscine / spa extérieur) | À définir lors du premier usage | — | Réservé |

Pour le tableau canonique des valeurs `domain:` et leurs consommateurs: [[Vocabulaire — domain]].

**Préfixes réservés (non alloués, pour éviter la confusion)**:

- `ORG` — trop proche d‘« Organon » mais non utilisé; à éviter pour ne pas créer d’ambiguïté avec `VLT`.
- `OBS` — trop lié à l’outil Obsidian; voir principe 1.
- `CLD` — scope sur l’agent (Claude), pas un domaine.
- `DEBT` — envisagé puis rejeté 2026-04-19: la distinction avec « backlog » était cosmétique. Les items qui étaient de la « dette technique » sont en fait des entrées de backlog (travaux à faire). Voir [[Méthodologie — Incidents, bugs et backlog]].

## Registre des types (niveau 2)

### Domaine `FIN` — Finance

Documenté en détail dans [[Index des standards financiers]] (section 0.4.4 « Convention d’identifiants »). Résumé ici pour référence croisée:

| Type | Forme | Objet | Dossier |
|---|---|---|---|
| `FIN-DEC` | `FIN-DEC-NNN` (3 chiffres) | Décisions structurantes | `01 - Finances et patrimoine/Décisions/` |
| `FIN-RULE` | `FIN-RULE-<DOMAINE>-NNN` | Règles transversales (testables) | `01 - Finances et patrimoine/Standards/Règles/` |
| `FIN-HYP` | `FIN-HYP-NNN` | Hypothèses (valeurs actives) | `01 - Finances et patrimoine/Standards/Hypothèses/` |
| `FIN-REF` | `FIN-REF-NNN` | Sources et références | `01 - Finances et patrimoine/Standards/Références/` |
| `FIN-TOOL` | `FIN-TOOL-<OUTIL>-NNN` | Fiches spécifiques à un outil | `01 - Finances et patrimoine/Standards/Outils/` |
| `FIN-RB` | `FIN-RB-NNN` | Runbooks (procédures) | `01 - Finances et patrimoine/Standards/Outils/Runbooks/` |
| `FIN-TPL` | `FIN-TPL-NNN` | Gabarits (squelettes) | `01 - Finances et patrimoine/Standards/Outils/Gabarits/` |
| `FIN-BL` | `FIN-BL-NNNN` (4 chiffres) | Items de backlog | `01 - Finances et patrimoine/Backlog/Items/` |
| `FIN-ETAT` | `FIN-ETAT-YYYY-MM-DD` | États de situation datés | `01 - Finances et patrimoine/États/` |
| `FIN-STD` | `FIN-STD-INDEX` et variantes | Identifiants d’index ou de notes-pivots | Racine de `Standards/` |

**Sous-types `FIN-RULE-<DOMAINE>`** (niveau 3) observés: `GOV`, `BEH`, `BUD`, `CAT`, `CREDIT`, `DATA`, `DOC`, `EMG`, `EST`, `GLS`, `GOALS`, `IMM`, `INGEST`, `IPC`, `LONG`, `REEE`, `RET`, `RISK`, `SENS`, `TAX`, `TOOL`, `WD`, `XL`, `YNAB`, `BAL`.

**Sous-types `FIN-TOOL-<OUTIL>`** (niveau 3) observés: `PL` (ProjectionLab), `YNAB`, `TPAW`, `DSN` (Disnat), `XL` (Excel), `SPEC`.

### Domaine `VLT` — Vault

| Type | Forme | Objet | Dossier |
|---|---|---|---|
| `VLT-INC` | `VLT-INC-NNNN` (4 chiffres) | Incidents bruts — une occurrence observée, immutable | `99 - Méta/Outils/Accès à Obsidian par Claude/Incidents/` |
| `VLT-BUG` | `VLT-BUG-NNN` (3 chiffres) | Bugs — un problème sous-jacent, N:1 avec incidents, lifecycle géré | `99 - Méta/Outils/Accès à Obsidian par Claude/Bugs/` |
| `VLT-BL` | `VLT-BL-NNNN` (4 chiffres) | Items de backlog — travaux à exécuter (capacités à ajouter, vérifications, remédiations issues de bugs, etc.) | `99 - Méta/Outils/Accès à Obsidian par Claude/Backlog/` |

Méthodologie détaillée: [[Méthodologie — Incidents, bugs et backlog]].

### Domaine `SD` — Système documentaire

| Type | Forme | Objet | Dossier |
|---|---|---|---|
| `SD-ADR` | `SD-ADR-NNN` (3 chiffres) | Décisions architecturales — choix structurants relatifs au système documentaire (conventions, vocabulaires, architecture du vault) | `99 - Méta/Système documentaire/ADR/` |
| `SD-BL` | `SD-BL-NNNN` (4 chiffres) | Items de backlog — travaux à exécuter sur le système documentaire (refactors, migrations, nouvelles conventions à propager, etc.) | `99 - Méta/Système documentaire/Backlog/` |

Méthodologie: [[Méthodologie — ADR]] (pour `SD-ADR`), [[Méthodologie — Incidents, bugs et backlog]] (pour `SD-BL`).

### Domaine `SPA` — Spa extérieur

À définir au premier usage. Placeholder.

## Registre des fiches-pivots (IDs singuliers)

Certains IDs ne sont pas des instances d’une série, mais des noms stables de notes-pivots (index, README). Ils suivent quand même la discipline du préfixe pour éviter les collisions.

| ID | Note | Rôle |
|---|---|---|
| `FIN-STD-INDEX` | [[Index des standards financiers]] | Index maître des standards FIN |
| `FIN-REF-REDIR-001` | [[FIN-REF-REDIR-001]] | Registre des redirections après refonte FIN |

À compléter au fur et à mesure.

## Protocole pour créer un nouveau préfixe

Avant d’inventer un préfixe sur le vif:

1. **Vérifier la collision.** Consulter ce registre. Si le préfixe proposé existe déjà (actif ou réservé), en choisir un autre.
2. **Vérifier le principe 1** (préfixe = domaine, pas outil). Si le préfixe proposé vient du nom d’un outil ou d’une plateforme, reformuler au niveau du domaine.
3. **Proposer**: ajouter une ligne au [[#Registre des domaines (niveau 1)]] en statut `Réservé` avec la portée et la note d’index prévue.
4. **Valider** avec Pierre-André si la portée n’est pas évidente (risque de recouvrement avec un domaine existant).
5. **Activer**: passer en statut `Actif` quand la première fiche est créée; documenter les sous-types au [[#Registre des types (niveau 2)]].
6. **Mettre à jour** `date modified` et ajouter une ligne au [[#Journal]] ci-dessous.
7. **Synchroniser** [[Vocabulaire — domain]]: ajouter la valeur correspondante.

## Protocole pour créer un nouveau sous-type dans un domaine existant

1. Vérifier qu’aucun sous-type existant ne couvre déjà le besoin (éviter `RULE` + `STANDARD` qui seraient synonymes).
2. Ajouter la ligne au registre des types de ce domaine (niveau 2).
3. Préciser la largeur de numéro (3 ou 4 chiffres selon la volumétrie attendue).
4. Créer le dossier dédié si la volumétrie justifie une atomisation, sinon documenter où vivent les fiches.
5. Si le type mérite une subdivision par sous-sous-domaine (`FIN-RULE-GOV`, `FIN-TOOL-PL`…), documenter la liste des subdivisions autorisées dans le registre du domaine.

## Anti-patterns

- **Inventer un préfixe en session sans passer par ce registre.** Crée des collisions silencieuses. Même urgente, toute création d’ID doit mentionner le préfixe dans une fiche, qui sera ajoutée au registre au passage suivant.
- **Utiliser un préfixe d’outil.** `YNAB-001` ou `EXCEL-042` attache l’ID à un outil qui peut disparaître. Toujours relever au niveau du domaine (`FIN`), puis ajouter l’outil en sous-type (`FIN-TOOL-YNAB-001`).
- **Renuméroter après coup.** Les IDs sont stables. Si un item change de catégorie ou de domaine, créer un nouvel ID, rediriger l’ancien (redirection documentée), ne pas recycler l’ID libéré.
- **Supprimer une fiche.** Déprécier avec `status: archived` ou `status: superseded-by: [[<nouveau>]]`. Ne jamais supprimer (traçabilité, intégrité des liens).
- **Préfixes à 2 lettres trop ambigus.** Éviter `OB`, `VA`, `FI` — préférer 3 lettres pour réduire les collisions avec des abréviations futures.
- **Inventer un tiers de catégorie là où backlog suffit.** « Dette technique » a été envisagée comme 3ᵉ type VLT; les items candidats (GitHub à déployer, CLI à vérifier, conventions à propager) étaient tous des **actions à exécuter** = backlog. La tentation revient régulièrement: toujours tester avec « est-ce qu’une entrée de backlog ferait l’affaire? ».

## Veille / à surveiller

- Apparition de nouveaux domaines à atomiser (santé, voyages, projets immobiliers hors riverain, généalogie, etc.).
- Évolution du périmètre de [[Vocabulaire — domain]] (consommateurs additionnels, nouveaux domaines).
- Éventuel outil d’audit: script qui vérifie que chaque fichier dont le nom matche un pattern d’ID a un `id:` frontmatter cohérent et un `^<ID>` en tête.

## Journal

| Date | Auteur | Changement |
|---|---|---|
| 2026-04-19 | Claude | Création initiale. Consolidation des préfixes `FIN` (existant) et `VLT` (nouveau). Réservation de `SPA`. Marquage de `ORG`, `OBS`, `CLD` comme réservés non alloués. Protocoles de création documentés. |
| 2026-04-19 | Claude | Révision: retrait du type `VLT-DEBT` (envisagé puis rejeté — les items étaient des entrées de backlog). Ajout du type `VLT-BL`. Ajout d’un anti-pattern explicite. Passage à 4 chiffres pour `VLT-INC` (cohérence avec la volumétrie attendue). |
| 2026-05-04 | Claude | Clarification du scope vis-à-vis de [[Vocabulaire — domain]]: préfixes ID ici, valeurs frontmatter `domain:` là-bas. Synchronisation croisée documentée dans §Objet et §Protocole. Wave B doc cleanup. |
| 2026-05-04 | Claude | Ajout du domaine `SD` (Système documentaire) au registre — préfixes `SD-ADR` (3 chiffres) et `SD-BL` (4 chiffres) actifs depuis fin avril 2026 mais pas formellement listés. Ajout de la section §Registre des types — Domaine SD. Wave C doc cleanup. |

## Liens

- Parent: [[Conventions de nommage]]
- Voisines: [[Vocabulaire — domain]], [[Index des standards financiers]] (FIN), [[Index — Accès à Obsidian par Claude]] (VLT), [[Méthodologie — Incidents, bugs et backlog]]
- Conventions: [[Vault Conventions]], [[AI Bootstrap]]
<!-- VAULT-END: 99 - Méta/Système documentaire/Préfixes d'identifiants.md (full body) -->
