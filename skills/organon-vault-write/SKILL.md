---
name: organon-vault-write
description: Use before any `patch_vault_file`, `create_vault_file`, `append_to_vault_file`, or `execute_template` call on the Organon vault (path contains `Organon`). MCP write discipline (mcp-tools-istefox ≥ 0.4.5): YAML quoting, frontmatter array semantics, tags shape, heading-patch safety, NFC normalisation, Templater-first routing for structured shapes.
---

# organon-vault-write

Edge cases → `get_vault_file('99 - Méta/AI/Vault Conventions.md')`. (No kepano cascade — this skill is purely about MCP wire-format and write discipline; generic Obsidian syntax is not a content dependency.)

**Note de langue** : ce qui suit décrit le **wire-format MCP** et le **routage**, pas le contenu d'artefacts vault. Pour les réponses chat (plans, analyses, garde-fous explicatifs comme cette skill produit), la langue suit le prompt PA, pas le folder de la note ciblée. Si PA prompt en français pour expliquer un patch, la réponse est en français même si la note ciblée est sous `99 - Méta/AI/`.

## Templater-first routing (création de notes structurées)

Tout shape structuré passe par `execute_template`, jamais par `create_vault_file` ad-hoc. Pourquoi : Templater injecte ULID + ID séquentiel + creator dual-mode + ordre Linter conforme ; un `create_vault_file` ad-hoc rate ces invariants. Deux variantes selon la dérivation du path :

- **Two-step render-then-create (BL/BUG/INC/ADR — ID séquentiel)** : `execute_template … createFile:false` → parse `frontmatter.id` du rendu → `create_vault_file content=<rendu> filename=<folder>/<id>.md`. La filename ne peut être calculée *avant* le render parce que Templater génère l'ID via `tp.user.next_id` (incrément séquentiel par registre). Le caller LIT l'ID dans le rendu, ne l'invente jamais.
- **One-step render-and-create (Note/Concept/Person/Book/Quote/Index/Organization)** : `execute_template … createFile:true targetPath:<path>` ; lire `path` retourné. Path dérivable upfront depuis `tp.user.domain` (folder map) — pas besoin de séquence ID.

## Disciplines

- **YAML scalar quoting** : quoter `"…"` toute valeur frontmatter contenant `:`, `#`, `&`, `*`, `!`, `|`, `>`, `'`, `"`, `%`, `@`, `` ` ``. Pourquoi : Local REST API revalide tout le frontmatter à chaque `patch_vault_file`, même targetType: block — un scalaire mal échappé bloque toute édition ultérieure de la note (HTTP 500, VLT-BUG-018).

  **JSON wire-format** pour `patch_vault_file targetType: frontmatter` : le champ `content` doit être une JSON-encoded string (pas un JSON object), avec les double-quotes du scalaire YAML internes échappées en `\"`. Forme canonique : `"content": "\"Valeur avec : caractères YAML\""`, `"contentType": "application/json"`. Le wrapper unwrappe la JSON string et écrit le scalaire entre `"…"` au YAML. Erreur courante : passer un JSON object `"content": {"key": "..."}` — le wrapper l'interprète différemment et le scalaire YAML résultant peut ne pas être quoté.
- **Frontmatter array vs scalar** (depuis istefox 0.4.0) : sur un champ array (`tags:`, `aliases:`, `references:`), `replace` avec un scalaire renvoie une erreur explicite — la coercition silencieuse array → scalaire est terminée. `append`/`prepend` JSON-décodent le `content` et auto-wrappent les scalaires nus. Règle : sur champ array, passer une JSON array (`"content": "[\"a\", \"b\"]"`) ; sur champ scalaire, passer une JSON string. La forme du payload doit matcher la forme du field — sinon fail-loud.
- **`tags:`** = array of strings. Jamais `tags: 4` / `null` / date / vide. Pourquoi : YAML 1.1 parse silencieusement `tags: 4` en `[Number(4)]` ; les plugins itérant via `.startsWith()` crashent (Smart Connections, VLT-BUG-014). Si pas de tags : omettre la clé ou `tags: []`.
- **Heading patch — pré-vérifier la présence du target, ne PAS passer `createTargetIfMissing: false`.** Sur istefox 0.4.5, le défaut est `true` ; avec un target heading inexistant, le patch silently-append à EOF (pas d'erreur, pas de heading créé, contenu orphelin — VLT-BUG-018-bis observé 2026-05-08). Le flag `false` n'est PAS la solution sur Organon : il déclenche le H2-root reject d'istefox 0.4.2 (#80) qui considère tout heading H2 sans parent H1 comme « root-orphan » — or par convention Organon **toute** note est H2-root (titre en frontmatter, body commence en H2). Le flag `false` est donc incompatible avec ce vault. Discipline : `get_vault_file` (ou cache de session) + grep `^## <target>$` *avant* le patch ; abort si absent.
- **First heading patch of session** : post-write verify mtime + diff. Confiance après. Pourquoi : la confiance se construit par session, pas globalement.
- **Block-target garde-fous istefox 0.4.x** : `patch_vault_file targetType: block` est rejeté fail-loud sur (a) block ref dans une cellule de table (0.4.2 #81), (b) block ref sur frontière de fenced-code (0.4.3 #84). Pas de corruption silencieuse mais pas d'écriture non plus — voir pitfall dans `organon-markdown-style`.
- **NFC normalization** sur tout chemin/titre accentué. Si 404 sur chemin supposé exister : NFC alt → `list_vault_files` parent → comparer byte-à-byte → consigner VLT-INC. Pourquoi : Mac filesystems sont NFC ; chaînes construites par concaténation peuvent dériver en NFD et produire un 404 silencieux (VLT-BUG-012).

## Anti-pattern : pas de ping MCP systématique

**Ne pas inclure** un step « Vérifier que MCP répond » comme préambule systématique avant chaque write. Pourquoi : (a) un timeout silencieux peut être révélé par l'appel réel sans plus de coût, (b) un ping defensive ajoute latence + risque de race condition, (c) la procédure est `fail-fast on call → retry sur signal anormal (VLT-BUG-012 NFC, latence inhabituelle, return ambigu)`. La disponibilité MCP est confirmée par la première opération réelle, pas par un health-check préalable.

## Footguns

- `delete_active_file` est sans paramètre — supprime la note focusée par Obsidian. Toujours `delete_vault_file` avec filename explicite.
- MCP write + UI save subséquente : peut être écrasé par re-import externe. Attendre disparition du banner « Re-import » avant save.
- `create_vault_file`, `append_to_vault_file`, `execute_template` créent les dossiers parents manquants depuis istefox 0.4.5 (#86). Ne pas pré-`create_vault_directory` les ancêtres — laisser l'auto-mkdirp faire le travail. Le pattern « mkdir + write » défensif des versions antérieures est obsolète.

Schema frontmatter → `organon-frontmatter`. Body prose → `organon-markdown-style`.
