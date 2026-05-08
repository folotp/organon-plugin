---
name: organon-frontmatter
description: Apply when composing or editing frontmatter in an Organon Obsidian vault note (path contains "iCloud~md~obsidian/Documents/Organon"). Schema, key ordering (Linter `yaml-key-priority-sort-order`), controlled vocabularies (type, status, namespaces), ULID forward-only, creator dual-mode (UI vs MCP), archive/supersession, alias-only versioning, language coherence (lang field matches description prose), navigation fields (up, references) for structured shapes (ADR/BL/BUG/INC). Use this skill EVERY TIME frontmatter is being written or modified on an Organon note — schema drift is the most common silent regression in this vault, and the Linter normalisation pass that follows can hide pre-write violations.
---

# organon-frontmatter

**Authoritative source** : `[[Registre des clés de frontmatter]]` (vault). The plugin carries a drift-tracked snapshot of the vault registre and prefixes registry; **vault wins on disagreement**. Run `./scripts/sync-vault.sh` to detect drift; cf. `docs/syncing-vault.md` for the re-sync workflow.

**References** (chargées à la demande, pas avec ce SKILL.md) :

- `references/VOCABULARIES.md` — vocabulaires fermés (12 enums absorbés verbatim + Organon-curated lookup pour `type`, `status`, `content-model`).
- `references/REGISTRE_KEYS.md` — schéma frontmatter complet (clés globales, per-type, per-domain, Tri Linter canonique). Verbatim absorption du vault registre. **Lire quand** une fiche structurée est composée (ADR, BL, BUG, INC, FIN-DEC) ou qu'une clé inhabituelle/ambiguë est nécessaire.
- `references/PREFIXES.md` — registre des préfixes d'identifiants (`<DOMAIN>-<TYPE>-NNNN`). Verbatim absorption du vault. **Lire quand** un nouvel ID doit être généré (vérification de collision + sous-types autorisés).
- `references/METHODOLOGY_ADR.md` — workflow ADR (lifecycle, immutabilité, supersession, anti-patterns). **Lire quand** un ADR (VLT-ADR / SD-ADR / FIN-DEC) est créé ou que son `status:` change.
- `references/METHODOLOGY_INC_BUG_BL.md` — workflow incidents/bugs/backlog (Phase A/B/C, promotion criteria, MCP write discipline). **Lire quand** un INC, BUG, ou BL est créé ou que son `status:` change.
- `references/PROPERTIES.md` — syntaxe YAML générique et reference complète des property types. Verbatim absorption depuis kepano `obsidian-skills` @ sha:fa1e131 ; cf. `kepano-sync.json`.

## Ordre Linter

`yaml-key-priority-sort-order` (`.obsidian/plugins/obsidian-linter/data.json`) fixe l'ordre. `ulid:` se place entre `id:` et `creator:`, **pas** après `modified:`. Ajouter une clé au Registre = mettre à jour aussi `yaml-key-priority-sort-order` ; sinon Linter retombe sur l'alphabétique au prochain save et écrase ton placement.

## Cohérence linguistique frontmatter ↔ body ↔ folder

Trois faits à aligner :

1. **Folder default** : `99 - Méta/AI/` (incluant `Claude/`, `ChatGPT/`) → anglais. Tout autre dossier → français.
2. **`lang:` dans le frontmatter** doit refléter la langue **réelle** du body et des prose-values du frontmatter (`description:`, `title:`).
3. **`description:`** (prose) **doit être dans la même langue** que `lang:`. Une note avec `lang: fr` ne peut pas avoir `description: Architectural decision record …` en anglais.

Cas de conflit (prompt en langue X mais convention de folder différente) : la convention de folder l'emporte pour les artefacts vault structurés (ADR, BL, BUG, INC, Concept, Note, etc.). Le prompt-language gouverne uniquement le ton de la conversation chat, pas le contenu vault. Si PA prompt en anglais à propos d'un VLT-ADR sous `99 - Méta/Outils/Accès à Obsidian par Claude/` (folder français), l'ADR reste en français.

## Vocabularies (essentiels — détail dans references/VOCABULARIES.md, schéma complet dans references/REGISTRE_KEYS.md)

- **`type:`** (16 valeurs) : `note | concept | person | book | quote | index | organization | journal | ai | hypothesis | rule | tool | template | runbook | reference | plan`. Mappe folder canonique. Les 7 dernières valeurs ont été promues 2026-05-05 ([[FIN-BL-0107]]) — **ne jamais inventer** une nouvelle valeur sans entrée registre vault.
- **`status:` (essentiels par usage courant)** : général/standards → `active | draft`. Backlog → `open | in-progress | planned | done | verified | abandoned`. Bugs → `open | investigating | root-cause-known | fix-designed | fix-deployed | verified | closed`. Incidents → `recorded | assigned | superseded`. ADRs / FIN-DEC → `proposed | accepted | rejected | superseded | deprecated`. **Pour les 12 vocabulaires absorbés (avec descriptions par valeur) et le sous-ensemble per-domain** : read `references/VOCABULARIES.md`.
- **Tag namespaces** : `source/*`, `domain/*`, `topic/*`, `notetype/*` (legacy → `type:`), `statut/*` (legacy → `status:`). Tag réservé sans namespace (allowlist) : `mcp-tools-prompt`. Pour la liste autoritaire des valeurs `topic/*` (~25 valeurs) : voir `references/VOCABULARIES.md` §`topic`.

  **Important — les namespaces sont des préfixes DANS le tableau `tags:`, pas des clés top-level séparées.** Forme correcte :

  ```yaml
  tags:
    - source/ia
    - domain/tooling
    - topic/methodology
    - topic/migration
  ```

  **Erreur courante à éviter** :

  ```yaml
  # WRONG — ces clés top-level ne sont pas reconnues par les plugins
  source:
    - ia
  domain:
    - tooling
  topic:
    - methodology
  ```

  Les plugins (Linter, Smart Connections, Bases) itèrent sur `file.tags` qui ne lit que les entrées de `tags:`, pas les clés racine homonymes.

## Règles structurantes

- **`title:` Option C dual découplé** (depuis 2026-04-23) — `title:` est humain et descriptif. Fiches à code : `"CODE — Titre descriptif"` (citer en `"…"` si contient `:` ou `—`). `aliases:` porte le code seul. Filename reste technique. Linter `yaml-title` désactivé.
- **`ulid:`** Crockford base32 (26 chars, `0-9 A-Z` sans `I L O U`), forward-only à la création. Injection auto via `tp.user.ulid()` dans templates dual-mode. Une note sans ulid (oubli ou trim) ne se rattrape pas — c'est forward-only par design. **Toujours produire une valeur réelle**, jamais une clé `ulid:` vide ou un placeholder. Si tu drafts hors-template (sans Templater), génère via le one-liner bash de `[[Vault Conventions]]` §`ulid:` ou via `python3 -c "import time,random; …"`.
- **`creator:` dual-mode** — UI → `Pierre-André Folot` sans tag `source/ia`. MCP → `Claude` avec tag `source/ia`. Détection via `tp.mcpTools` dans le prelude.
- **`creator` vs `author`** : `creator` = auteur de la note Organon. `author` = auteur de l'œuvre externe décrite (réservé aux `type: book` et similaires).
- **Archive** : `archived: true` + `archived-date: YYYY-MM-DD` (paire requise, orthogonal à `status:`).
- **Supersession** : sur la fiche superseded, `status: superseded` + `superseded-by: "[[…]]"` + callout `> [!warning] Superseded` en tête de corps (cf. `references/METHODOLOGY_ADR.md` §Marking superseded fiches). Sur la nouvelle fiche, `supersedes: "[[…]]"` est un champ frontmatter conditionnel pour les ADR/FIN-DEC ; pour les notes canoniques générales, le `supersedes:` frontmatter est en migration vers un lien typé dans le corps (cf. `references/REGISTRE_KEYS.md` §Clés en migration). Les clés `amends:` / `amended-by:` sont **dépréciées** (2026-05-05, [[SD-ADR-011]]) — toujours superséder complètement.
- **Alias-only versioning** (notes-pivots, VLT-ADR-008) — alias court stable transféré entre versions. Pas de note-pointeur.

## Frontmatter shape-specific (champs additionnels selon `type:` ou famille)

Au-delà du frontmatter de base, certains shapes structurés exigent des champs additionnels. **Ne pas omettre** ces fields, même si la skill les présente comme "optionnels" — ils sont attendus par le template canonique correspondant. Pour le **schéma complet par-domaine** (avec toutes les clés conditionnelles et leurs vocabulaires) : `references/REGISTRE_KEYS.md`.

- **ADR (VLT-ADR, SD-ADR, FIN-DEC)** — exiger : `date-decided: YYYY-MM-DD`, `references:` (liste de wikilinks vers notes citées dans Contexte/Décision), `up: ["[[Index — VLT-ADR]]"]` ou équivalent. **Cascade obligatoire** : read `references/METHODOLOGY_ADR.md` quand un ADR est créé ou que son `status:` change (lifecycle, immutabilité, supersession, callout `[!warning] Superseded`, anti-patterns).
- **Backlog (VLT-BL, SD-BL)** — exiger : `priority:`, `origin:`, `effort:` (si connu), `linked-bug:` si `origin: bug`, `up: ["[[Index — VLT-BL]]"]`. **Cascade obligatoire** : read `references/METHODOLOGY_INC_BUG_BL.md` quand un BL est créé ou que son `status:` change (lifecycle, Phase A/B/C, MCP write discipline).
- **Bug (VLT-BUG)** — exiger : `severity:`, optional `component:`, `first-incident:`, `last-occurrence:`, `up: ["[[Index — VLT-BUG]]"]`. **Cascade obligatoire** : read `references/METHODOLOGY_INC_BUG_BL.md` (promotion criteria incident → bug, lifecycle transitions, lesson learned conversion).
- **Incident (VLT-INC)** — exiger : `date:`, `surface:`, `layer:`, `tool:`, `operation:`, `status: recorded` (default), optional `bug:` wikilink, `up: ["[[Index — VLT-INC]]"]`. **Cascade obligatoire** : read `references/METHODOLOGY_INC_BUG_BL.md` (Phase A discipline — pas de hypothèse de cause dans la fiche incident, append-only).
- **Nouveau ID `<DOMAIN>-<TYPE>-NNN(N)`** — avant de proposer un nouvel identifiant : read `references/PREFIXES.md` (vérification de collision, sous-types autorisés, protocole de création).
- **Person, Book, Quote** — voir `references/VOCABULARIES.md` §Person fields / Book fields ; schéma complet dans `references/REGISTRE_KEYS.md`.
- **Toute note** : `up:` (parent navigation, généralement un Index thématique) reste fortement recommandé pour la routabilité du vault.

Pour le frontmatter complet d'un ADR (exemple canonique) : référer à `[[VLT-ADR-002]]` ou tout VLT-ADR existant comme template avant de drafter de novo.

## Touch-on-edit (legacy migration, VLT-ADR-007)

Édition d'une note legacy déclenche normalisation des clés legacy détectées : `shape:` → `content-model:`, tag `notetype/*` → champ `type:`, `#statut/*` → `status:`, `date created` → `created`, `author` → `creator`, `first-name` → `given-name`. Migration par attrition canonique — pas de sweep batch global. Détection passive complémentaire via l'audit script Templater (cf. VLT-ADR-005, sortie `Audit-YYYY-MM-DD.md` §Clés frontmatter obsolètes).

**Seuil** — normaliser au plus ~3 clés legacy par édition. Au-delà, la modification dépasse le scope de l'édition demandée : flagger à PA dans la réponse, laisser PA décider de poursuivre ou skipper.

**Journal de la note** — documenter chaque normalisation appliquée. Forme canonique dans la table Journal/Historique : « Frontmatter normalisé : `<clé legacy>` → `<clé canonique>` ». Une ligne par clé migrée. Permet à PA de tracer la cause des changements et au script d'audit de mesurer la convergence.

**Skip explicite** — si l'édition demandée est elle-même large (> 10 lignes touchées) ou si PA prompt « édit minimal », ne pas appliquer touch-on-edit ; mentionner les clés legacy détectées comme dette dans la réponse pour traitement séparé.

## Governance

Pas de nouvelle clé sans entrée dans `[[Registre des clés de frontmatter]]`. Vérifier le registre avant d'inventer un champ. Pour l'ordre Linter, mettre aussi à jour `yaml-key-priority-sort-order`.
