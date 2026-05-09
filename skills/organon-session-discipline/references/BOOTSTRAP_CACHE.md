# Bootstrap cache protocol (P7.1)

`[[AI Bootstrap]]` (`99 - Méta/AI/AI Bootstrap.md`) est canonique pour OS, naming, vault paths, system config, MCP wrapper version. Le cache projet permet d'éviter un `get_vault_file` à chaque vérification.

## Protocole

1. Lire `memory/skill_cache_manifest.json` (projet Cowork memory space).
2. Si présent : bash `sha256sum "/sessions/.../mnt/Organon/99 - Méta/AI/AI Bootstrap.md"` et comparer au champ `ai_bootstrap.sha256`.
3. **Cache hit** (sha256 identique) : charger `memory/cache_ai_bootstrap.md` au lieu de `get_vault_file`. Économie : ~300 tok.
4. **Cache miss ou manifeste absent** : `get_vault_file('99 - Méta/AI/AI Bootstrap.md')`, puis mettre à jour `skill_cache_manifest.json` et `cache_ai_bootstrap.md` avec le nouveau sha256 et le contenu.
5. **Session multi-artefact** : une seule vérification sha256 suffit par session — mémoriser « Bootstrap vérifié à [timestamp] » pour les appels suivants dans la même conversation.

## Cascade

Pour les ADRs qui réfèrent à des incidents/évents spécifiques, **également lire** les VLT-* notes mentionnées (VLT-BUG, VLT-INC, mémoires de session) — leur historique de versions et dates précises rendent la fiche substantiellement meilleure que ce que le training peut produire.
