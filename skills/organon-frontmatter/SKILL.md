---
name: organon-frontmatter
description: Apply when composing or editing frontmatter in an Organon Obsidian vault note (path contains "iCloud~md~obsidian/Documents/Organon"). Schema, key ordering (Linter `yaml-key-priority-sort-order`), controlled vocabularies (type, status, namespaces), ULID forward-only, creator dual-mode (UI vs MCP), archive/supersession, alias-only versioning, language coherence (lang field matches description prose), navigation fields (up, references) for structured shapes (ADR/BL/BUG/INC). Use this skill EVERY TIME frontmatter is being written or modified on an Organon note — schema drift is the most common silent regression in this vault, and the Linter normalisation pass that follows can hide pre-write violations.
---

# organon-frontmatter

Authoritative source : `[[Registre des clés de frontmatter]]` (vault). Pour vocabularies complets ou edge cases, **read** `references/VOCABULARIES.md` (chargé à la demande, pas avec ce SKILL.md). Syntaxe YAML générique → cascade `obsidian-markdown` (kepano) §Properties.

## Ordre Linter

`yaml-key-priority-sort-order` (`.obsidian/plugins/obsidian-linter/data.json`) fixe l'ordre. `ulid:` se place entre `id:` et `creator:`, **pas** après `modified:`. Ajouter une clé au Registre = mettre à jour aussi `yaml-key-priority-sort-order` ; sinon Linter retombe sur l'alphabétique au prochain save et écrase ton placement.

## Cohérence linguistique frontmatter ↔ body ↔ folder

Trois faits à aligner :

1. **Folder default** : `99 - Méta/AI/` (incluant `Claude/`, `ChatGPT/`) → anglais. Tout autre dossier → français.
2. **`lang:` dans le frontmatter** doit refléter la langue **réelle** du body et des prose-values du frontmatter (`description:`, `title:`).
3. **`description:`** (prose) **doit être dans la même langue** que `lang:`. Une note avec `lang: fr` ne peut pas avoir `description: Architectural decision record …` en anglais.

Cas de conflit (prompt en langue X mais convention de folder différente) : la convention de folder l'emporte pour les artefacts vault structurés (ADR, BL, BUG, INC, Concept, Note, etc.). Le prompt-language gouverne uniquement le ton de la conversation chat, pas le contenu vault. Si PA prompt en anglais à propos d'un VLT-ADR sous `99 - Méta/Outils/Accès à Obsidian par Claude/` (folder français), l'ADR reste en français.

## Vocabularies (essentiels — détail dans references/VOCABULARIES.md)

- **`type:`** : `note | concept | person | book | quote | index | organization | journal | ai`. Mappe folder canonique.
- **`status:` (essentiels par usage courant)** : général → `active | draft`. Backlog → `open | in-progress | planned | done | abandoned`. Bugs → `open | investigating | root-cause-known | fix-designed | fix-deployed | verified | closed`. ADRs → `proposed | accepted | rejected | superseded | deprecated`. **Pour la liste complète des 18 valeurs et sous-ensembles par domaine** : read `references/VOCABULARIES.md`.
- **Tag namespaces** : `source/*`, `domain/*`, `topic/*`, `notetype/*` (legacy → `type:`), `statut/*` (legacy → `status:`). Tag réservé sans namespace (allowlist) : `mcp-tools-prompt`.

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
- **Supersession** : `status: superseded` + `superseded-by: "[[…]]"`. Pas de `supersedes:` field.
- **Alias-only versioning** (notes-pivots, VLT-ADR-008) — alias court stable transféré entre versions. Pas de note-pointeur.

## Frontmatter shape-specific (champs additionnels selon `type:` ou famille)

Au-delà du frontmatter de base, certains shapes structurés exigent des champs additionnels. **Ne pas omettre** ces fields, même si la skill les présente comme "optionnels" — ils sont attendus par le template canonique correspondant.

- **ADR (VLT-ADR, SD-ADR)** — exiger : `date-decided: YYYY-MM-DD`, `references:` (liste de wikilinks vers notes citées dans Contexte/Décision), `up: ["[[Index — VLT-ADR]]"]` ou équivalent.
- **Backlog (VLT-BL, SD-BL)** — exiger : `priority:`, `effort:` (si connu), `up: ["[[Index — VLT-BL]]"]`.
- **Bug (VLT-BUG)** — exiger : `severity:`, `surface:`, `layer:`, `operation:`, `upstream-issue:` (si applicable), `up: ["[[Index — VLT-BUG]]"]`.
- **Incident (VLT-INC)** — exiger : `severity:`, `surface:`, `up: ["[[Index — VLT-INC]]"]`.
- **Person, Book, Quote** — voir `references/VOCABULARIES.md` §Person fields / Book fields.
- **Toute note** : `up:` (parent navigation, généralement un Index thématique) reste fortement recommandé pour la routabilité du vault.

Pour le frontmatter complet d'un ADR (exemple canonique) : référer à `[[VLT-ADR-002]]` ou tout VLT-ADR existant comme template avant de drafter de novo.

## Touch-on-edit (legacy migration, VLT-ADR-007)

Édition d'une note legacy déclenche normalisation des clés legacy détectées : `shape:` → `content-model:`, tag `notetype/*` → champ `type:`, `#statut/*` → `status:`, `date created` → `created`, `author` → `creator`, `first-name` → `given-name`. Migration par attrition canonique — pas de sweep batch global. Détection passive complémentaire via l'audit script Templater (cf. VLT-ADR-005, sortie `Audit-YYYY-MM-DD.md` §Clés frontmatter obsolètes).

**Seuil** — normaliser au plus ~3 clés legacy par édition. Au-delà, la modification dépasse le scope de l'édition demandée : flagger à PA dans la réponse, laisser PA décider de poursuivre ou skipper.

**Journal de la note** — documenter chaque normalisation appliquée. Forme canonique dans la table Journal/Historique : « Frontmatter normalisé : `<clé legacy>` → `<clé canonique>` ». Une ligne par clé migrée. Permet à PA de tracer la cause des changements et au script d'audit de mesurer la convergence.

**Skip explicite** — si l'édition demandée est elle-même large (> 10 lignes touchées) ou si PA prompt « édit minimal », ne pas appliquer touch-on-edit ; mentionner les clés legacy détectées comme dette dans la réponse pour traitement séparé.

## Governance

Pas de nouvelle clé sans entrée dans `[[Registre des clés de frontmatter]]`. Vérifier le registre avant d'inventer un champ. Pour l'ordre Linter, mettre aussi à jour `yaml-key-priority-sort-order`.
