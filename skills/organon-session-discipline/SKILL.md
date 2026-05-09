---
name: organon-session-discipline
description: Apply at the start of any Claude session operating on the Organon vault (path contains `Organon`), or before any multi-step Organon task (drafting an ADR, BL, BUG, INC, sweep, refactor wave). 7 behavioral rules — arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder.
---

# organon-session-discipline

7 frictions Claude récurrentes (cf. VLT-ADR-012). Domaine purement behavioral. Pour conventions techniques, cascade vers `organon-vault-write`, `organon-frontmatter`, `organon-markdown-style`.

## 1. Arbitrate, don't over-clarify

PA prefers arbitrage motivé over sur-clarification. Quand une décision est inférable du contexte (ADRs, conventions, transcript), faire l'appel et proposer direction. Demander uniquement si stakes hauts (overwrite, delete, batch > 3, cross-domain refactor) **ou** ambiguïté maximale — et même là, proposer un défaut et laisser PA le contester.

> **Bad** : « Veux-tu que je préserve la numérotation existante VLT-BUG-001…021 (3 chiffres) ou que je renumérote en 4 chiffres comme les nouveaux ? »
> **Good** : « Je préserve VLT-BUG-001…021 en 3 chiffres (no-renumber per SD-ADR-008 §existing IDs) ; les nouveaux suivent 4 chiffres. Conteste si non. »

## 2. Read bootstrap before writing artifacts — cache-aware

`[[AI Bootstrap]]` est canonique pour OS, naming, vault paths, system config, MCP wrapper version. Avant de drafter une fiche qui mentionne ces faits, **lire effectivement** le Bootstrap — mais via le cache projet si disponible et valide. Protocole détaillé (sha256 manifest, cache hit/miss, multi-artefact session memoization) : `references/BOOTSTRAP_CACHE.md`.

> **Bad** : drafter une note disant « v0.4.5 » sans avoir lu le bootstrap pour confirmer la version exacte.
> **Good** : vérifier manifeste sha256 → cache hit → charger `cache_ai_bootstrap.md` → confirme `mcp-tools-istefox v0.4.5` → drafte avec les valeurs lues. (Burnt 2026-04-28.)

## 3. No in-fiche redundancy

Si l'info est dans une table/liste/frontmatter, ne pas la restater en prose juste avant ou après. One canonical form per fact.

> **Bad** : table « Statut: open / in-progress / done » immédiatement précédée de « Le statut peut être open, in-progress, ou done. »
> **Good** : 1-sentence intro qui annonce la table, puis la table seule.

## 4. Confirm inferred mappings explicitly

Quand on map des items entre systèmes (`VLT-BUG-NNN ↔ GitHub issue #N`, `ADR ↔ Diagnostic problem ID`, `transcript timestamp ↔ commit`), énoncer l'inférence et demander « confirm? » dans la même réponse. PA accepting passively ≠ validation explicite.

> **Bad** : « VLT-BUG-020 correspond à #58 et VLT-BUG-021 à #62. » (PA accepte sans valider.)
> **Good** : « Mapping inféré — VLT-BUG-020 ↔ istefox/obsidian-mcp-tools#58, VLT-BUG-021 ↔ #62. Confirme? » (Burnt 2026-04-27.)

## 5. Propose generalizations when patterns recur

Si 2+ artefacts similaires sont produits (sweeps, layers, prompts, BL templates, fiches avec structure parallèle), proposer un meta-pattern ou template. Ne pas attendre que PA demande.

## 6. Check meta-skills before producing typed artifacts

Avant de drafter un artefact d'un type spécifique (SKILL.md, ADR, plugin Cowork, MCP server, manifest), itérer sur `available_skills` pour identifier une skill méta qui code des best practices structurelles. Anchoring biases courants à neutraliser : framing projet l'emporte sur framing artefact, sentiment d'avoir « toute l'info locale » via les exemples disponibles. Skill-creator note explicitement : Claude tend à *undertrigger* les skills utiles. (Burnt 2026-04-28 — drafter 4 SKILL.md sans consulter `skill-creator`.)

## 7. Language coherence — folder default beats prompt language

Pour les artefacts vault (ADR, BL, BUG, INC, Concept, Note, etc.), la langue est gouvernée par le folder, pas par le prompt. Règle complète et exemples : `organon-markdown-style` §Langue par dossier (canonical home).
