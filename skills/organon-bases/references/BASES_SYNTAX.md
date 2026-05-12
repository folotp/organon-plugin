# Bases Syntax

Adapted from kepano/obsidian-skills@fa1e131. See docs/refreshing-kepano.md.

## Schema

`.base` files contain valid YAML:

```yaml
filters:                   # Global filters (and/or/not)
formulas:                  # Computed properties
  formula_name: 'expr'
properties:                # Display config
  property_name:
    displayName: "Display Name"
summaries:                 # Summary formulas
  summary_name: 'values.mean()'
views:
  - type: table|cards|list|map
    name: "View Name"
    limit: 10
    groupBy:
      property: field_name
      direction: ASC|DESC
    filters: {}            # View-specific filters
    order: [prop1, prop2]
    summaries: {}
```

## Filter Syntax

Single filter:
```yaml
filters: 'status == "done"'
```

Recursive (and/or/not):
```yaml
filters:
  and:
    - 'status == "done"'
    - 'priority > 3'
  or:
    - 'file.hasTag("tag")'
  not:
    - 'file.hasTag("archived")'
```

Nested combinations:
```yaml
filters:
  or:
    - file.hasTag("tag")
    - and:
        - file.hasTag("book")
        - file.hasLink("Link")
```

### Filter Operators

| Operator | Meaning |
|----------|---------|
| `==` | equals |
| `!=` | not equal |
| `>`, `<`, `>=`, `<=` | comparison |
| `&&` | logical and |
| `\|\|` | logical or |
| `!` | logical not |

## Properties

### Types

- **Note**: frontmatter values — `author` or `note.author`
- **File**: metadata — `file.name`, `file.mtime`, etc.
- **Formula**: computed — `formula.my_formula`

### File Properties

| Property | Type | Description |
|----------|------|-------------|
| `file.name` | String | File name |
| `file.basename` | String | Name without extension |
| `file.path` | String | Full path |
| `file.folder` | String | Parent folder |
| `file.ext` | String | Extension |
| `file.size` | Number | Bytes |
| `file.ctime` | Date | Created |
| `file.mtime` | Date | Modified |
| `file.tags` | List | All tags |
| `file.links` | List | Internal links |
| `file.backlinks` | List | Backlinks |
| `file.embeds` | List | Embeds |
| `file.properties` | Object | All frontmatter |

### The `this` Keyword

- Main content: refers to base file
- Embedded: refers to embedding file
- Sidebar: refers to active file

## Formula Syntax

```yaml
formulas:
  total: "price * quantity"
  status_icon: 'if(done, "✅", "⏳")'
  formatted: 'price.toFixed(2) + " dollars"'
  created: 'file.ctime.format("YYYY-MM-DD")'
  days_old: '(now() - file.ctime).days'
  days_until_due: 'if(due_date, (date(due_date) - today()).days, "")'
```

### Duration Type (Date Arithmetic)

Subtracting two dates returns **Duration**, not number. Access field first (`.days`, `.hours`, etc.):

```yaml
# CORRECT
"(date(due_date) - today()).days"
"(now() - file.ctime).days.round(0)"

# WRONG
"(now() - file.ctime).round(0)"     # Duration ≠ number
```

Units: y/year, M/month, d/day, w/week, h/hour, m/minute, s/second

```yaml
"now() + \"1 day\""
"today() + \"7d\""
"(now() - file.ctime).days"
```

## Key Functions

For complete reference, see [FUNCTIONS_REFERENCE.md](FUNCTIONS_REFERENCE.md).

| Function | Signature | Description |
|----------|-----------|-------------|
| `date()` | `date(string): date` | Parse string (YYYY-MM-DD HH:mm:ss) |
| `now()` | `now(): date` | Current date+time |
| `today()` | `today(): date` | Current date (00:00:00) |
| `if()` | `if(condition, true, false?)` | Conditional |
| `duration()` | `duration(string): duration` | Parse duration string |
| `file()` | `file(path): file` | Get file object |
| `link()` | `link(path, display?): Link` | Create link |

## View Types

### Table View

```yaml
- type: table
  name: "My Table"
  order:
    - file.name
    - status
    - due_date
  summaries:
    price: Sum
    count: Average
```

### Cards View

```yaml
- type: cards
  name: "Gallery"
  order:
    - file.name
    - cover_image
    - description
```

### List View

```yaml
- type: list
  name: "Simple List"
  order:
    - file.name
    - status
```

### Map View

Requires latitude/longitude properties and Maps plugin.

## Default Summary Formulas

| Name | Type | Description |
|------|------|-------------|
| `Average`, `Min`, `Max`, `Sum`, `Range`, `Median`, `Stddev` | Number | Aggregations |
| `Earliest`, `Latest`, `Range` | Date | Date aggregations |
| `Checked`, `Unchecked` | Boolean | Count true/false |
| `Empty`, `Filled` | Any | Count null/non-null |
| `Unique` | Any | Count distinct |

## YAML Quoting Rules

- **Formulas with inner double-quotes**: wrap in single quotes
  ```yaml
  label: 'if(done, "Yes", "No")'
  ```
- **Simple strings**: double quotes
  ```yaml
  displayName: "My View"
  ```
- **Special characters** (`:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@` `` ` ``): must be quoted
  ```yaml
  displayName: "Status: Active"
  ```

## Common Errors

### Duration Math Without Field Access

Duration does not support `.round()` directly. Access `.days` (or other field) first:

```yaml
# WRONG
"(now() - file.ctime).round(0)"

# CORRECT
"(now() - file.ctime).days.round(0)"
```

### Missing Null Checks

Properties may not exist on all notes. Guard with `if()`:

```yaml
# WRONG - crashes if due_date missing
"(date(due_date) - today()).days"

# CORRECT
'if(due_date, (date(due_date) - today()).days, "")'
```

### Undefined Formula References

Verify `formula.X` in `order` or `properties` has a matching entry in `formulas`:

```yaml
# Fix: define it
formulas:
  total: "price * quantity"
```

## Embedding Bases

Embed in Markdown:

```markdown
![[MyBase.base]]
![[MyBase.base#View Name]]  # Specific view
```

## Example: Task Tracker

```yaml
filters:
  and:
    - file.hasTag("task")
    - 'file.ext == "md"'

formulas:
  days_until_due: 'if(due, (date(due) - today()).days, "")'
  is_overdue: 'if(due, date(due) < today() && status != "done", false)'
  priority_label: 'if(priority == 1, "🔴 High", if(priority == 2, "🟡 Medium", "🟢 Low"))'

views:
  - type: table
    name: "Active Tasks"
    filters:
      and:
        - 'status != "done"'
    order:
      - file.name
      - status
      - formula.priority_label
      - due
      - formula.days_until_due
    groupBy:
      property: status
      direction: ASC
```
