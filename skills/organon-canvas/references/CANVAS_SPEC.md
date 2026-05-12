# Canvas Spec

Adapted from kepano/obsidian-skills@fa1e131a. See docs/refreshing-kepano.md.

<!-- kepano-absorbed: derived from upstream https://jsoncanvas.org/spec/1.0/ -->

## File Structure

```json
{
  "nodes": [],
  "edges": []
}
```

## Nodes

| Attribute | Required | Type | Notes |
|-----------|----------|------|-------|
| `id` | Yes | string | 16-char lowercase hex (e.g., `6f0ad84f44ce9c17`) |
| `type` | Yes | string | `text`, `file`, `link`, or `group` |
| `x`, `y` | Yes | integer | Top-left position in pixels; negative allowed |
| `width`, `height` | Yes | integer | Dimensions in pixels |
| `color` | No | string | Preset `"1"`–`"6"` or hex (e.g., `#FF0000`) |

**Text node:** Requires `text` (string, supports Markdown; use `\n` for line breaks, not literal `\\n`).

**File node:** Requires `file` (path). Optional `subpath` (#-prefixed heading/block link).

**Link node:** Requires `url` (external URL).

**Group node:** Optional `label` (string), `background` (image path), `backgroundStyle` (`cover`, `ratio`, or `repeat`).

Example text node:
```json
{
  "id": "6f0ad84f44ce9c17",
  "type": "text",
  "x": 0,
  "y": 0,
  "width": 400,
  "height": 200,
  "text": "# Title\n\n**Bold** text."
}
```

## Edges

| Attribute | Required | Type | Default | Notes |
|-----------|----------|------|---------|-------|
| `id` | Yes | string | — | Unique identifier |
| `fromNode`, `toNode` | Yes | string | — | Source and target node IDs |
| `fromSide`, `toSide` | No | string | — | `top`, `right`, `bottom`, or `left` |
| `fromEnd`, `toEnd` | No | string | none / arrow | Arrow placement |
| `label` | No | string | — | Text label |
| `color` | No | string | — | Preset or hex |

Example:
```json
{
  "id": "0123456789abcdef",
  "fromNode": "6f0ad84f44ce9c17",
  "toNode": "a1b2c3d4e5f67890",
  "toEnd": "arrow",
  "label": "leads to"
}
```

## Colors

Presets: `"1"` (red), `"2"` (orange), `"3"` (yellow), `"4"` (green), `"5"` (cyan), `"6"` (purple). Or use hex.

## Validation

1. All IDs unique across nodes and edges
2. `fromNode`/`toNode` reference existing node IDs
3. Required fields per type: `text` (text), `file` (file), `url` (link)
4. `type` ∈ {`text`, `file`, `link`, `group`}
5. `fromSide`/`toSide` ∈ {`top`, `right`, `bottom`, `left`}
6. `fromEnd`/`toEnd` ∈ {`none`, `arrow`}
7. Color presets 1–6 or valid hex
8. Valid JSON

See [EXAMPLES.md](EXAMPLES.md) for complete canvases.

---

**References:** [JSON Canvas Spec 1.0](https://jsoncanvas.org/spec/1.0/) · [GitHub](https://github.com/obsidianmd/jsoncanvas)
