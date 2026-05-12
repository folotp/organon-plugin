# Mermaid in Obsidian

Adapted from kepano/obsidian-skills@fa1e131. See `docs/refreshing-kepano.md`.

````markdown
```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Do this]
    B -->|No| D[Do that]
```
````

To link Mermaid nodes to Obsidian notes, add `class NodeName internal-link;`.

