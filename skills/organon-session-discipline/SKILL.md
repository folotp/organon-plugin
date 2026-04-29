---
name: organon-session-discipline
description: Apply at the start of any Claude session operating on the Organon Obsidian vault (path contains "iCloud~md~obsidian/Documents/Organon"), or before any multi-step Organon task (drafting an ADR, BL, BUG, INC, sweep, refactor wave, decision memo). 7 behavioral rules from PA-validated session patterns — arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder. Use this skill EVERY TIME a new Organon-touching session starts or a multi-step task begins — these are recurring frictions PA has explicitly flagged, not nice-to-haves.
---

# organon-session-discipline

6 frictions Claude récurrentes (cf. VLT-ADR-012). Domaine purement behavioral — pas de cascade kepano. Pour conventions techniques, cascade vers `organon-vault-write`, `organon-frontmatter`, `organon-markdown-style`.

## 1. Arbitrate, don't over-clarify

PA prefers arbitrage motivé over sur-clarification. Quand une décision est inférable du contexte (ADRs, conventions, transcript), faire l'appel et proposer direction. Demander uniquement si stakes hauts (overwrite, delete, batch > 3, cross-domain refactor) **ou** ambiguïté maximale — et même là, proposer un défaut et laisser PA le contester.

> **Bad** : « Veux-tu que je préserve la numérotation existante VLT-BUG-001…021 (3 chiffres) ou que je renumérote en 4 chiffres comme les nouveaux ? »
> **Good** : « Je préserve VLT-BUG-001…021 en 3 chiffres (no-renumber per SD-ADR-008 §existing IDs) ; les nouveaux suivent 4 chiffres. Conteste si non. »

## 2. Read bootstrap before writing artifacts — actually read, not just affirm

`[[AI Bootstrap]]` est canonique pour OS, naming, vault paths, system config, MCP wrapper version. Avant de drafter une fiche qui mentionne ces faits, **lire effectivement** via `get_vault_file('99 - Méta/AI/AI Bootstrap.md')`, pas affirmer la valeur de mémoire. Pour les ADRs qui réfèrent à des incidents/évents spécifiques, **également lire** les VLT-* notes mentionnées (VLT-BUG, VLT-INC, mémoires de session) — leur historique de versions et dates précises rendent la fiche substantiellement meilleure que ce que le training peut produire.

> **Bad** : drafter une note mentionnant « macOS 15 Sequoia » par défaut depuis training.
> **Bad** : drafter une note disant « v0.3.12 » sans avoir lu le bootstrap pour confirmer la version exacte.
> **Good** : `get_vault_file('99 - Méta/AI/AI Bootstrap.md')` → confirme `macOS Tahoe 26.x` + `mcp-tools-istefox v0.3.12` → drafte avec les valeurs lues (et non recall). Pour ADR sur fork/upgrade : lire aussi `[[mcp_tools_istefox_brat_upgrade_restart]]` ou notes équivalentes pour récupérer les dates et numéros de release précis. (Burnt 2026-04-28.)

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

> **Good** : « Je vois qu'on vient de produire 3 sweeps avec la même structure (inventaire → cleanup → validation). Je propose un template Templater pour le 4e que je pressens. Veux-tu que je le drafte ? »

## 6. Check meta-skills before producing typed artifacts

Avant de drafter un artefact d'un type spécifique (SKILL.md, ADR, plugin Cowork, MCP server, manifest, etc.), itérer sur `available_skills` pour identifier une skill méta qui code des best practices structurelles. Anchoring biases courants à neutraliser : (a) framing projet l'emporte sur framing artefact (« phase 5 wave 1 chat 1.A » → exécuter le step plutôt que reconnaître « créer un SKILL.md »), (b) sentiment d'avoir « toute l'info locale » via les exemples disponibles. Skill-creator note explicitement : Claude tend à *undertrigger* les skills utiles.

> **Bad** : démarrer la rédaction de 4 SKILL.md sans consulter `skill-creator` parce qu'on a kepano sous la main comme exemple.
> **Good** : avant de drafter le 1er SKILL.md, scanner `available_skills` pour « create / skill / X.md / artifact » → invoke skill-creator → suivre ses best practices. (Burnt 2026-04-28.)

## 7. Language coherence — folder default beats prompt language for vault artifacts

Quand l'artefact est destiné au vault Organon (ADR, BL, BUG, INC, Concept, Note, etc.), la langue est gouvernée par le **folder** où la note vit, pas par la langue du prompt. Le prompt-language gouverne uniquement le ton de la conversation chat. Cohérence requise : `lang:` frontmatter, prose-fields (`description:`, `title:`), et body tous dans la même langue.

> **Bad** : prompt en français → drafter un ADR sous `99 - Méta/Outils/...` (folder français) en anglais parce qu'on en discutait avec un terme anglais.
> **Bad** : drafter un ADR avec `lang: fr` mais `description: Architectural decision record …` en anglais.
> **Good** : ADR sous `99 - Méta/Outils/Accès à Obsidian par Claude/` → français complet (body, description, title-prose). ADR sous `99 - Méta/AI/Claude/` → anglais complet. Cf. `organon-markdown-style` §Langue par dossier.
