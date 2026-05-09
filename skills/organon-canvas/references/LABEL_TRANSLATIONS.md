# Canvas label translations EN ↔ FR

Translations à garder sous la main quand on draft un canvas dans un folder français pendant une conversation chat en anglais. Le default-English instinct slips into JSON labels même quand l'artefact vit en folder français — **traduire chaque label avant d'écrire**.

| English (default instinct) | French (folder default) |
|---|---|
| `cause`, `causes`, `causal link` | `cause`, `lien causal` |
| `root cause` | `cause racine` |
| `related to`, `related` | `relié à`, `connexe` |
| `parent`, `child`, `sibling` | `parent`, `enfant`, `frère` |
| `depends on`, `dependency` | `dépend de`, `dépendance` |
| `supersedes`, `superseded by` | `remplace`, `remplacé par` |
| `leads to`, `triggers` | `mène à`, `déclenche` |
| `blocks`, `blocked by` | `bloque`, `bloqué par` |
| `extends`, `refines` | `étend`, `affine` |
| `Project Overview`, `Summary` | `Vue d'ensemble`, `Synthèse` |

> **Bad** (canvas sous folder français mais labels EN dans le JSON) :
> ```json
> {"text": "Common root cause: YAML schema drift", "label": "causes"}
> ```
>
> **Good** (mêmes folder, labels FR) :
> ```json
> {"text": "Cause racine commune : dérive de schéma YAML", "label": "cause"}
> ```
