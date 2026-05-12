# Functions Reference

Adapted from kepano/obsidian-skills@fa1e131. See docs/refreshing-kepano.md.

<!-- kepano-sync: derived from upstream; see kepano-sync.json and vault-sync.json for drift status -->

## Global Functions

| Function | Signature |
|----------|-----------|
| `date()` | `date(string): date` |
| `duration()` | `duration(string): duration` |
| `now()` | `now(): date` |
| `today()` | `today(): date` |
| `if()` | `if(condition, trueResult, falseResult?)` |
| `min()` | `min(n1, n2, ...): number` |
| `max()` | `max(n1, n2, ...): number` |
| `number()` | `number(any): number` |
| `link()` | `link(path, display?): Link` |
| `list()` | `list(element): List` |
| `file()` | `file(path): file` |
| `image()` | `image(path): image` |
| `icon()` | `icon(name): icon` |
| `html()` | `html(string): html` |
| `escapeHTML()` | `escapeHTML(string): string` |

## Any Type Functions

| Function | Signature |
|----------|-----------|
| `isTruthy()` | `any.isTruthy(): boolean` |
| `isType()` | `any.isType(type): boolean` |
| `toString()` | `any.toString(): string` |

## Date Functions & Fields

**Fields:** `date.year`, `date.month`, `date.day`, `date.hour`, `date.minute`, `date.second`, `date.millisecond`

| Function | Signature |
|----------|-----------|
| `date()` | `date.date(): date` |
| `format()` | `date.format(string): string` |
| `time()` | `date.time(): string` |
| `relative()` | `date.relative(): string` |
| `isEmpty()` | `date.isEmpty(): boolean` |

## Duration Type

Subtracting two dates returns **Duration**. Fields: `days`, `hours`, `minutes`, `seconds`, `milliseconds` (all numeric). Duration does NOT support `.round()` directly—access a field first: `(date1 - date2).days.round(0)`.

Duration arithmetic: Add/subtract via strings (`"1M"`, `"2h"`, `"7d"`, `"1 year"`).

## String Functions

**Field:** `string.length`

| Function | Signature |
|----------|-----------|
| `contains()` | `string.contains(value): boolean` |
| `containsAll()` | `string.containsAll(...values): boolean` |
| `containsAny()` | `string.containsAny(...values): boolean` |
| `startsWith()` | `string.startsWith(query): boolean` |
| `endsWith()` | `string.endsWith(query): boolean` |
| `isEmpty()` | `string.isEmpty(): boolean` |
| `lower()` | `string.lower(): string` |
| `title()` | `string.title(): string` |
| `trim()` | `string.trim(): string` |
| `replace()` | `string.replace(pattern, replacement): string` |
| `repeat()` | `string.repeat(count): string` |
| `reverse()` | `string.reverse(): string` |
| `slice()` | `string.slice(start, end?): string` |
| `split()` | `string.split(separator, n?): list` |

## Number Functions

| Function | Signature |
|----------|-----------|
| `abs()` | `number.abs(): number` |
| `ceil()` | `number.ceil(): number` |
| `floor()` | `number.floor(): number` |
| `round()` | `number.round(digits?): number` |
| `toFixed()` | `number.toFixed(precision): string` |
| `isEmpty()` | `number.isEmpty(): boolean` |

## List Functions

**Field:** `list.length`

| Function | Signature |
|----------|-----------|
| `contains()` | `list.contains(value): boolean` |
| `containsAll()` | `list.containsAll(...values): boolean` |
| `containsAny()` | `list.containsAny(...values): boolean` |
| `filter()` | `list.filter(expression): list` |
| `map()` | `list.map(expression): list` |
| `reduce()` | `list.reduce(expression, initial): any` |
| `flat()` | `list.flat(): list` |
| `join()` | `list.join(separator): string` |
| `reverse()` | `list.reverse(): list` |
| `slice()` | `list.slice(start, end?): list` |
| `sort()` | `list.sort(): list` |
| `unique()` | `list.unique(): list` |
| `isEmpty()` | `list.isEmpty(): boolean` |

## File Functions

| Function | Signature |
|----------|-----------|
| `asLink()` | `file.asLink(display?): Link` |
| `hasLink()` | `file.hasLink(otherFile): boolean` |
| `hasTag()` | `file.hasTag(...tags): boolean` |
| `hasProperty()` | `file.hasProperty(name): boolean` |
| `inFolder()` | `file.inFolder(folder): boolean` |

## Link Functions

| Function | Signature |
|----------|-----------|
| `asFile()` | `link.asFile(): file` |
| `linksTo()` | `link.linksTo(file): boolean` |

## Object Functions

| Function | Signature |
|----------|-----------|
| `isEmpty()` | `object.isEmpty(): boolean` |
| `keys()` | `object.keys(): list` |
| `values()` | `object.values(): list` |

## Regular Expression Functions

| Function | Signature |
|----------|-----------|
| `matches()` | `regexp.matches(string): boolean` |
