# Shape-specific frontmatter quickref

Champs additionnels exigés par `type:` ou famille, au-delà du frontmatter de base. **Ne pas omettre** ces fields, même si la skill les présente comme « optionnels » — ils sont attendus par le template canonique correspondant. Pour le **schéma complet par-domaine** (toutes les clés conditionnelles et leurs vocabulaires) : `REGISTRE_KEYS.md`.

## ADR (VLT-ADR, SD-ADR, FIN-DEC)

Exiger : `date-decided: YYYY-MM-DD`, `references:` (liste de wikilinks vers notes citées dans Contexte/Décision), `up: ["[[Index — VLT-ADR]]"]` ou équivalent.

**Cascade obligatoire** : read `METHODOLOGY_ADR.md` quand un ADR est créé ou que son `status:` change (lifecycle, immutabilité, supersession, callout `[!warning] Superseded`, anti-patterns).

## Backlog (VLT-BL, SD-BL)

Exiger : `priority:`, `origin:`, `effort:` (si connu), `linked-bug:` si `origin: bug`, `up: ["[[Index — VLT-BL]]"]`.

**Cascade obligatoire** : read `METHODOLOGY_INC_BUG_BL.md` quand un BL est créé ou que son `status:` change (lifecycle, Phase A/B/C, MCP write discipline).

## Bug (VLT-BUG)

Exiger : `severity:`, optional `component:`, `first-incident:`, `last-occurrence:`, `up: ["[[Index — VLT-BUG]]"]`.

**Cascade obligatoire** : read `METHODOLOGY_INC_BUG_BL.md` (promotion criteria incident → bug, lifecycle transitions, lesson learned conversion).

## Incident (VLT-INC)

Exiger : `date:`, `surface:`, `layer:`, `tool:`, `operation:`, `status: recorded` (default), optional `bug:` wikilink, `up: ["[[Index — VLT-INC]]"]`.

**Cascade obligatoire** : read `METHODOLOGY_INC_BUG_BL.md` (Phase A discipline — pas de hypothèse de cause dans la fiche incident, append-only).

## Nouveau ID `<DOMAIN>-<TYPE>-NNN(N)`

Avant de proposer un nouvel identifiant : read `PREFIXES.md` (vérification de collision, sous-types autorisés, protocole de création).

## Person, Book, Quote

Voir `VOCABULARIES.md` §Person fields / Book fields ; schéma complet dans `REGISTRE_KEYS.md`.

## Toute note

`up:` (parent navigation, généralement un Index thématique) reste fortement recommandé pour la routabilité du vault.

## Exemple canonique

Pour le frontmatter complet d'un ADR : référer à `[[VLT-ADR-002]]` ou tout VLT-ADR existant comme template avant de drafter de novo.
