---
name: organon-vault-write
description: Apply BEFORE any patch_vault_file, create_vault_file, append_to_vault_file, or execute_template call on the Organon Obsidian vault (path contains "iCloud~md~obsidian/Documents/Organon"). MCP write discipline via mcp-tools-istefox 0.3.12+ — YAML quoting, tags shape, heading patch safety, NFC, Voie B routing for structured shapes. Use this skill EVERY TIME a write op is about to touch an Organon note, even for a single-line patch — silent corruption from frontmatter quoting bugs and table+block-ref pitfalls is the recurring failure mode this skill prevents.
---

# organon-vault-write

Cascades to `obsidian-markdown` (kepano) for generic Obsidian syntax. Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`.

**Note de langue** : ce qui suit décrit le **wire-format MCP** et le **routage**, pas le contenu d'artefacts vault. Pour les réponses chat (plans, analyses, garde-fous explicatifs comme cette skill produit), la langue suit le prompt PA, pas le folder de la note ciblée. Si PA prompt en français pour expliquer un patch, la réponse est en français même si la note ciblée est sous `99 - Méta/AI/`.

## Voie B routing (création de notes structurées)

Tout shape structuré passe par `execute_template`, jamais par `create_vault_file` ad-hoc. Pourquoi : Templater injecte ULID + creator dual-mode + ordre Linter conforme ; un `create_vault_file` ad-hoc rate ces invariants.

- **Two-step (BL/BUG/INC/ADR — ID séquentiel)** : `execute_template … createFile:false` → parse `frontmatter.id` du rendu → `create_vault_file content=<rendu> filename=<folder>/<id>.md`. Ne pré-calcule jamais un ID séquentiel — Templater le génère via `tp.user.next_id` ; le caller LIT l'ID, ne l'invente pas.
- **One-step (Note/Concept/Person/Book/Quote/Index/Organization)** : `execute_template … createFile:true targetPath:<path>` ; lire `path` retourné. Path dérivé de `tp.user.domain` (folder map).

## Disciplines

- **YAML scalar quoting** : quoter `"…"` toute valeur frontmatter contenant `:`, `#`, `&`, `*`, `!`, `|`, `>`, `'`, `"`, `%`, `@`, `` ` ``. Pourquoi : Local REST API revalide tout le frontmatter à chaque `patch_vault_file`, même targetType: block — un scalaire mal échappé bloque toute édition ultérieure de la note (HTTP 500, VLT-BUG-018).

  **JSON wire-format** pour `patch_vault_file targetType: frontmatter` : le champ `content` doit être une JSON-encoded string (pas un JSON object), avec les double-quotes du scalaire YAML internes échappées en `\"`. Forme canonique : `"content": "\"Valeur avec : caractères YAML\""`, `"contentType": "application/json"`. Le wrapper unwrappe la JSON string et écrit le scalaire entre `"…"` au YAML. Erreur courante : passer un JSON object `"content": {"key": "..."}` — le wrapper l'interprète différemment et le scalaire YAML résultant peut ne pas être quoté.
- **`tags:`** = array of strings. Jamais `tags: 4` / `null` / date / vide. Pourquoi : YAML 1.1 parse silencieusement `tags: 4` en `[Number(4)]` ; les plugins itérant via `.startsWith()` crashent (Smart Connections, VLT-BUG-014). Si pas de tags : omettre la clé ou `tags: []`.
- **`createTargetIfMissing: false`** explicite sur tout `patch_vault_file targetType: heading`. Defense-in-depth : la reject path 0.3.9 ne couvre pas tous les cas non-résolvables (typo sur leaf, target nestable). Sans ce flag, certains targets non-existants peuvent être créés silencieusement.
- **First heading patch of session** : post-write verify mtime + diff. Confiance après. Pourquoi : la confiance se construit par session, pas globalement. H2 racine sans parent H1 = fail-loud reject (0.3.10+) ; cellule de table = fail-loud HTTP 400 (0.3.7+) — pas de corruption silencieuse mais pas d'écriture non plus.
- **NFC normalization** sur tout chemin/titre accentué. Si 404 sur chemin supposé exister : NFC alt → `list_vault_files` parent → comparer byte-à-byte → consigner VLT-INC. Pourquoi : Mac filesystems sont NFC ; chaînes construites par concaténation peuvent dériver en NFD et produire un 404 silencieux (VLT-BUG-012).

## Anti-pattern : pas de ping MCP systématique

**Ne pas inclure** un step « Vérifier que MCP répond » comme préambule systématique avant chaque write. Pourquoi : (a) un timeout silencieux peut être révélé par l'appel réel sans plus de coût, (b) un ping defensive ajoute latence + risque de race condition, (c) la procédure est `fail-fast on call → retry sur signal anormal (VLT-BUG-012 NFC, latence inhabituelle, return ambigu)`. La disponibilité MCP est confirmée par la première opération réelle, pas par un health-check préalable.

## Footguns

- `delete_active_file` est sans paramètre — supprime la note focusée par Obsidian. Toujours `delete_vault_file` avec filename explicite.
- MCP write + UI save subséquente : peut être écrasé par re-import externe. Attendre disparition du banner « Re-import » avant save.

Schema frontmatter → `organon-frontmatter`. Body prose → `organon-markdown-style`.
