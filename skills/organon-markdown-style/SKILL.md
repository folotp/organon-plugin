---
name: organon-markdown-style
description: Apply when writing prose body for an Organon Obsidian vault note (path contains "iCloud~md~obsidian/Documents/Organon"). Organon body conventions — no H1 in body (titre = frontmatter `title:`), language by folder (`99 - Méta/AI/` in EN, all other folders in FR — folder default supersedes prompt language for vault artifacts), typographic apostrophes, no trailing whitespace, no systematic anchors (politique C4), table+block-ref pitfall. Use this skill EVERY TIME prose body content is being drafted or edited on an Organon note — these conventions are the difference between content that survives Linter passes cleanly and content that triggers re-import banners or silent normalisation. Cascades to obsidian-markdown (kepano) for generic Obsidian syntax.
---

# organon-markdown-style

Generic Obsidian syntax (wikilinks, callouts, embeds, block refs, tables, footnotes, math, Mermaid) → `references/MARKDOWN_SYNTAX.md` (verbatim absorption from kepano `obsidian-skills` @ sha:fa1e131, cf. `kepano-sync.json` at repo root). Detailed embed types and callout types are in `references/EMBEDS.md` and `references/CALLOUTS.md`. Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`.

## Headings

**No H1 in body** — le titre vient du frontmatter `title:` et est rendu automatiquement par Obsidian au-dessus du body. H2 (`##`) est le premier niveau du body, puis H3, H4. Pourquoi : H1 dans le body crée un doublon visuel avec le title rendu et casse les outliners.

**Le titre est implicite — ne pas le restater au début du body**, ni en H1 ni en H2. Si tu corriges une note legacy qui avait `# Titre` au début, le retrait correct est de **supprimer la ligne**, pas de la convertir en `## Titre`. Le body commence directement par la première section de contenu (intro prose, ou première section thématique en H2).

> **Bad** (over-correction qui restaure le titre redondant) : `# Pleine conscience` → `## Pleine conscience`
> **Good** (titre retiré, body commence par le contenu) : `# Pleine conscience` → (rien — la prose suivante commence directement)

Pas de heading vide. Pas de saut de niveau (H2 → H4 sans H3) — préserve la navigabilité du sommaire.

## Langue par dossier — règle dure pour les artefacts vault

Trois principes cumulatifs :

1. **Folder default est la règle dure** pour le contenu vault structuré (ADR, BL, BUG, INC, Concept, Person, Note, etc.) :
   - `99 - Méta/AI/` (incluant `Claude/`, `ChatGPT/`) → **anglais**. Pourquoi : ces notes sont consommées par les LLMs en priorité ; l'anglais maximise la portée et l'efficacité de tokenization.
   - Tout autre dossier → **français** par défaut. Le vault Organon est principalement français.

2. **Le prompt-language gouverne le ton de la conversation, pas le contenu vault.** Si PA prompt en anglais à propos d'un ADR sous `99 - Méta/Outils/Accès à Obsidian par Claude/` (folder français), l'ADR reste écrit en français. La langue de la conversation est orthogonale à la langue de l'artefact persisté.

3. **Cohérence frontmatter ↔ body** : la prose dans `description:` (et autres prose-fields du frontmatter) doit être dans la même langue que le body et que le champ `lang:`. Une note avec body français mais `description:` en anglais est un fail.

Préserver la VO d'une citation/source en anglais ; traduire au besoin en regard.

## Style typographique

- **Apostrophes typographiques `’`** plutôt qu'ASCII `'` dans la prose. Pourquoi : le Linter normalise — sortir conforme évite le banner « Re-import » sur les écritures MCP suivies de UI save (cf. mémoire `mcp_write_then_ui_save_reimport_overwrite`, où une normalisation Linter post-MCP a écrasé une édition).
- Tirets : `—` (em-dash) dans titres et filenames de séries (`NN — Title`), `Index — Domaine` ; `-` (hyphen) dans les codes (`FIN-DEC-001`) et frontmatter keys (`yaml-key-priority-sort-order`).
- Pas de trailing whitespace ni de tab leading. Sortir conforme évite les collisions MCP write + UI save.

## Block references — politique « pas systématique » (C4)

- **Pas d'anchor systématique** post-frontmatter. N'injecte pas `^<id>` après les frontmatter des nouvelles notes — c'était une convention Organon abandonnée 2026-04-28 (PA arbitré). Sweep wave 3 nettoie le legacy vault-wide.
- Anchor `^<token>` autorisée **en dernier recours** quand un heading même nesté est insuffisant pour pointer un bloc spécifique. **Token descriptif** (ex. `^cas-1`, `^exemple-route`, `^def-canonical`), **pas** l'ID de la note.

## Pitfall — tables + block refs (et fenced code)

`patch_vault_file targetType: block` est rejeté fail-loud par istefox 0.4.2+ (#81) si le block ref `^id` ciblé se trouve dans une cellule de table — cause upstream = `markdown-patch` ne parse pas correctement les tables. istefox 0.4.3 (#84) étend le même reject aux block refs sur la frontière d'un fenced-code (les délimiteurs ``` ``` `` ne peuvent pas être splicés). Pas de corruption silencieuse, pas d'HTTP 400 obscur — un reject MCP structuré (VLT-BUG-015).

Le block ref reste valide pour la résolution Obsidian (lecture, lien, embed) ; c'est uniquement l'opération de patch ciblée qui est interdite. Pour éditer ce contenu : `patch_vault_file targetType: heading` sur la section parente, ou `create_vault_file` complet en dernier recours. Ne pas tenter de contourner le reject en supprimant temporairement le block ref — la perte de référentialité downstream coûte plus cher que la voie heading.

## Préférer wikilinks intra-vault

Pour renvois entre notes du vault, utilise `[[Note]]` (Obsidian propage les renames automatiquement). Réserve `[text](url)` aux URLs externes uniquement.

MCP write safety → `organon-vault-write`. Frontmatter schema → `organon-frontmatter`.
