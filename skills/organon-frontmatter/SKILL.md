---
name: organon-frontmatter
description: Use when composing or editing frontmatter on an Organon vault note (path contains `Organon`). Schema, key ordering (Linter `yaml-key-priority-sort-order`), controlled vocabularies, ULID forward-only, creator dual-mode, archive/supersession, alias-only versioning, navigation fields for typed shapes (ADR/BL/BUG/INC).
---

# organon-frontmatter

**Authoritative source** : `[[Registre des clés de frontmatter]]` (vault). The plugin carries a drift-tracked snapshot ; **vault wins on disagreement**. Run `./scripts/sync-vault.sh` to detect drift ; cf. `docs/syncing-vault.md`.

**Language coherence** (folder default, prose-fields ↔ `lang:` ↔ body) is governed by `organon-markdown-style` §Langue par dossier — read it once per session ; not duplicated here.

**References** (chargées à la demande) :

- `references/VOCABULARIES.md` — vocabulaires fermés (12 enums absorbés verbatim + Organon-curated lookup pour `type`, `status`, `content-model`).
- `references/REGISTRE_KEYS.md` — schéma frontmatter complet (clés globales, per-type, per-domain, Tri Linter canonique). **Lire quand** une fiche structurée est composée ou qu'une clé inhabituelle est nécessaire.
- `references/SHAPES_QUICKREF.md` — champs additionnels exigés par shape (ADR, BL, BUG, INC, Person/Book/Quote, nouveau ID). **Lire quand** une fiche typée est créée.
- `references/PREFIXES.md` — registre des préfixes d'identifiants. **Lire quand** un nouvel ID doit être généré.
- `references/METHODOLOGY_ADR.md` — workflow ADR. **Lire quand** un ADR (VLT-ADR / SD-ADR / FIN-DEC) est créé ou que son `status:` change.
- `references/METHODOLOGY_INC_BUG_BL.md` — workflow incidents/bugs/backlog. **Lire quand** un INC, BUG, ou BL est créé ou que son `status:` change.
- `references/PROPERTIES.md` — syntaxe YAML générique et property types. Verbatim absorption depuis kepano `obsidian-skills` ; cf. `kepano-sync.json`.

## Ordre Linter

`yaml-key-priority-sort-order` (`.obsidian/plugins/obsidian-linter/data.json`) fixe l'ordre. `ulid:` se place entre `id:` et `creator:`, **pas** après `modified:`. Ajouter une clé au Registre = mettre à jour aussi `yaml-key-priority-sort-order` ; sinon Linter retombe sur l'alphabétique au prochain save et écrase ton placement.

## Vocabularies essentiels (détail dans `references/VOCABULARIES.md`)

- **`type:`** (16 valeurs) : `note | concept | person | book | quote | index | organization | journal | ai | hypothesis | rule | tool | template | runbook | reference | plan`. Mappe folder canonique. Les 7 dernières valeurs ont été promues 2026-05-05 ([[FIN-BL-0107]]) — **ne jamais inventer** une nouvelle valeur sans entrée registre vault.
- **`status:`** par usage courant : général/standards → `active | draft` ; backlog → `open | in-progress | planned | done | verified | abandoned` ; bugs → `open | investigating | root-cause-known | fix-designed | fix-deployed | verified | closed` ; incidents → `recorded | assigned | superseded` ; ADRs / FIN-DEC → `proposed | accepted | rejected | superseded | deprecated`. Pour les 12 vocabulaires absorbés et le sous-ensemble per-domain : `references/VOCABULARIES.md`.
- **Tag namespaces** : `source/*`, `domain/*`, `topic/*`, `notetype/*` (legacy → `type:`), `statut/*` (legacy → `status:`). Tag réservé sans namespace (allowlist) : `mcp-tools-prompt`. Liste autoritaire des `topic/*` : `references/VOCABULARIES.md` §`topic`.

  **Important — namespaces sont des préfixes DANS le tableau `tags:`, pas des clés top-level séparées.** Forme correcte :

  ```yaml
  tags:
    - source/ia
    - domain/tooling
    - topic/methodology
  ```

  Erreur courante : utiliser `source: [ia]` / `domain: [tooling]` comme clés racine — non reconnues par Linter, Smart Connections, Bases (qui itèrent sur `file.tags`).

## Règles structurantes

- **`title:` Option C dual découplé** (depuis 2026-04-23) — `title:` est humain et descriptif. Fiches à code : `"CODE — Titre descriptif"` (citer en `"…"` si contient `:` ou `—`). `aliases:` porte le code seul. Filename reste technique. Linter `yaml-title` désactivé.
- **`ulid:`** Crockford base32 (26 chars, `0-9 A-Z` sans `I L O U`), forward-only à la création. Injection auto via `tp.user.ulid()` dans templates dual-mode. Une note sans ulid (oubli ou trim) ne se rattrape pas. **Toujours produire une valeur réelle**, jamais une clé vide ou un placeholder. Drafting hors-template : générer via le one-liner bash de `[[Vault Conventions]]` §`ulid:`.
- **`creator:` dual-mode** — UI → `Pierre-André Folot` sans tag `source/ia`. MCP → `Claude` avec tag `source/ia`. Détection via `tp.mcpTools` dans le prelude.
- **`creator` vs `author`** : `creator` = auteur de la note Organon. `author` = auteur de l'œuvre externe décrite (réservé aux `type: book` et similaires).
- **Archive** : `archived: true` + `archived-date: YYYY-MM-DD` (paire requise, orthogonal à `status:`).
- **Supersession** : sur la fiche superseded, `status: superseded` + `superseded-by: "[[…]]"` + callout `> [!warning] Superseded` en tête de corps (cf. `references/METHODOLOGY_ADR.md`). Sur la nouvelle fiche, `supersedes: "[[…]]"` est conditionnel pour ADR/FIN-DEC ; pour notes canoniques générales, en migration vers lien typé dans le corps (cf. `references/REGISTRE_KEYS.md`). Les clés `amends:` / `amended-by:` sont **dépréciées** (2026-05-05, [[SD-ADR-011]]).
- **Alias-only versioning** (notes-pivots, VLT-ADR-008) — alias court stable transféré entre versions. Pas de note-pointeur.

## Frontmatter shape-specific

Au-delà du frontmatter de base, certains shapes structurés exigent des champs additionnels (ADR, BL, BUG, INC, Person/Book/Quote, nouveau ID) — voir `references/SHAPES_QUICKREF.md`. Pour le **schéma complet par-domaine** : `references/REGISTRE_KEYS.md`.

## Touch-on-edit (legacy migration, VLT-ADR-007)

Édition d'une note legacy déclenche normalisation des clés legacy détectées : `shape:` → `content-model:`, tag `notetype/*` → champ `type:`, `#statut/*` → `status:`, `date created` → `created`, `author` → `creator`, `first-name` → `given-name`. Migration par attrition canonique — pas de sweep batch global.

**Seuil** — normaliser au plus ~3 clés legacy par édition. Au-delà, flagger à PA, laisser PA décider. **Skip explicite** : si l'édition demandée est déjà large (> 10 lignes touchées) ou si PA prompt « édit minimal », ne pas appliquer touch-on-edit ; mentionner les clés legacy comme dette.

**Journal** — documenter chaque normalisation : « Frontmatter normalisé : `<clé legacy>` → `<clé canonique>` ». Une ligne par clé migrée.

## Governance

Pas de nouvelle clé sans entrée dans `[[Registre des clés de frontmatter]]`. Vérifier le registre avant d'inventer un champ. Pour l'ordre Linter, mettre aussi à jour `yaml-key-priority-sort-order`.
