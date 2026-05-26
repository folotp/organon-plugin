# Excalidraw `.excalidraw.md` skeleton

Excalidraw plugin parses literal markers. Reproduce skeleton verbatim when persisting a connector drawing via the bridge. Wrap `elements` array from `create_view` inside the JSON block under `## Drawing`.

## Skeleton (reproduce verbatim)

````markdown
---
excalidraw-plugin: parsed
tags: [excalidraw]
---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠==

## Drawing
```json
{"type":"excalidraw","version":2,"source":"https://github.com/zsviczian/obsidian-excalidraw-plugin","elements":[ /* from create_view */ ],"appState":{"gridSize":null,"viewBackgroundColor":"#ffffff"},"files":{}}
```
%%
````

## Strip before saving

`cameraUpdate`, `delete`, `restoreCheckpoint` pseudo-elements from `create_view` output. Rendering directives for the connector, not real Excalidraw elements — leaving them breaks the plugin's parser.

## Preserve verbatim

`excalidraw-plugin: parsed` frontmatter key, warning sentence, `## Drawing` heading, closing `%%` markdown comment. Plugin matches these literally.

## Save target

`99 - Méta/Media/Excalidraw/<name>.excalidraw.md` via `create_vault_file`. Plugin invariants (compression OFF, default font Virgil, Linter OFF) documented in the SKILL.md.
