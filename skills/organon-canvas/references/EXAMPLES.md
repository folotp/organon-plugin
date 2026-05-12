# Canvas Examples — Absorbed from kepano

Adapted from kepano/obsidian-skills@fa1e131. See docs/refreshing-kepano.md.

<!-- kepano-sync: see kepano-sync.json for body_sha256 + drift status -->

## Text and Edges (Simple Hub)

```json
{
  "nodes": [
    { "id": "n1", "type": "text", "x": 0, "y": 0, "width": 300, "height": 100, "text": "Core idea" },
    { "id": "n2", "type": "text", "x": 400, "y": -80, "width": 200, "height": 60, "text": "Point A" },
    { "id": "n3", "type": "text", "x": 400, "y": 80, "width": 200, "height": 60, "text": "Point B" }
  ],
  "edges": [
    { "id": "e1", "fromNode": "n1", "fromSide": "right", "toNode": "n2", "toSide": "left" },
    { "id": "e2", "fromNode": "n1", "fromSide": "right", "toNode": "n3", "toSide": "left" }
  ]
}
```

Hub-and-spoke layout with two text nodes connected to a central node.

## Groups (Kanban Board)

```json
{
  "nodes": [
    { "id": "g1", "type": "group", "x": 0, "y": 0, "width": 300, "height": 400, "label": "To Do", "color": "1" },
    { "id": "g2", "type": "group", "x": 350, "y": 0, "width": 300, "height": 400, "label": "Done", "color": "4" },
    { "id": "t1", "type": "text", "x": 20, "y": 30, "width": 260, "height": 70, "text": "Task A" },
    { "id": "t2", "type": "text", "x": 370, "y": 30, "width": 260, "height": 70, "text": "Task B" }
  ],
  "edges": []
}
```

Groups organize workspace. Tasks placed within group bounds.

## Files and Links (Research)

```json
{
  "nodes": [
    { "id": "n1", "type": "text", "x": 200, "y": 150, "width": 300, "height": 120, "text": "Research topic" },
    { "id": "n2", "type": "file", "x": 0, "y": 0, "width": 150, "height": 100, "file": "Notes.md" },
    { "id": "n3", "type": "file", "x": 0, "y": 130, "width": 150, "height": 100, "file": "Paper.pdf", "subpath": "#Section" },
    { "id": "n4", "type": "link", "x": 0, "y": 260, "width": 150, "height": 60, "url": "https://example.com" }
  ],
  "edges": [
    { "id": "e1", "fromNode": "n2", "fromSide": "right", "toNode": "n1", "toSide": "left", "label": "supports" },
    { "id": "e2", "fromNode": "n4", "fromSide": "right", "toNode": "n1", "toSide": "left", "toEnd": "arrow" }
  ]
}
```

Files link to vault notes and attachments; links to external URLs. Edge labels optional.

## Flowchart (Decision Tree)

```json
{
  "nodes": [
    { "id": "n1", "type": "text", "x": 100, "y": 0, "width": 100, "height": 50, "text": "Start", "color": "4" },
    { "id": "n2", "type": "text", "x": 100, "y": 80, "width": 100, "height": 50, "text": "Check data" },
    { "id": "n3", "type": "text", "x": 250, "y": 80, "width": 100, "height": 50, "text": "Process" },
    { "id": "n4", "type": "text", "x": 100, "y": 180, "width": 100, "height": 50, "text": "End", "color": "4" }
  ],
  "edges": [
    { "id": "e1", "fromNode": "n1", "fromSide": "bottom", "toNode": "n2", "toSide": "top" },
    { "id": "e2", "fromNode": "n2", "fromSide": "right", "toNode": "n3", "toSide": "left", "label": "Yes" },
    { "id": "e3", "fromNode": "n3", "fromSide": "bottom", "toNode": "n4", "toSide": "top" }
  ]
}
```

Vertical flow with labeled decision edges. Directed via `fromSide`/`toSide`.
