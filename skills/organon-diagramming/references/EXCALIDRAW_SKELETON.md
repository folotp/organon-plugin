# Excalidraw `.excalidraw.md` skeleton

The Excalidraw plugin parses literal markers in the file. Reproduce this skeleton verbatim when persisting a connector-generated drawing via the bridge. Wrap the `elements` array from `create_view` inside the JSON block on the `## Drawing` heading.

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

Any `cameraUpdate`, `delete`, or `restoreCheckpoint` pseudo-elements from `create_view` output. They are rendering directives for the connector, not real Excalidraw elements — leaving them in breaks the plugin's parser.

## Preserve verbatim

The `excalidraw-plugin: parsed` frontmatter key, the warning sentence, the `## Drawing` heading, the closing `%%` markdown comment. The plugin matches these literally.

## Save target

`99 - Méta/Media/Excalidraw/<name>.excalidraw.md` via `create_vault_file`. Plugin invariants (compression OFF, default font Virgil, Linter OFF) are documented in the SKILL.md.
