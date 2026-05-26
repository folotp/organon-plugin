# Report template — organon-memory-audit

Render inline in conversation. Write to file only if PA explicitly asks — conversation is the persistence.

`Stable run hash`: sha256 of `(plugin.json content + kepano-version.txt content + canonical vault note body + companion matrix body)`. Same hash on two consecutive runs = pole 1 + pole 2 unchanged.

```markdown
# Organon memory & instructions audit — <YYYY-MM-DD HH:MM>

## Run
- Surface: <Code | Cowork | Chat-Desktop | Chat-web | Chat-mobile>
- Scope: <global | project=<slug> | all>
- Mode: <interactive | report-only>
- Plugin source: <readable at <path> | inferred from harness skill list>
- Canonical vault note: <read at <vault path> | not reachable (no MCP) | paste-driven>
- Integrity gate: <kepano-sync exit 0 | DRIFT — see Bucket 0>

## Sources of truth
- Plugin v<X.Y.Z> @ <git short SHA> (<commit date>)
- Skills (<N>): <comma-separated names, with `(user-only)` annotation for disable-model-invocation: true>
- Commands (<N>): <comma-separated names>
- MCP server floor: mcp-tools-istefox >= <X.Y.Z>
- kepano-sync: <N>/<N> in-sync (or list drifted sections with their drift_status)
- Canonical snippets last synced: <date from each per-surface bloc>
- Stable run hash: <sha256 short>

## Findings

### Bucket 0 — Plugin internal drift (<N>)

For each drifted entry:

- **Source**: kepano-sync
- **Section**: <name>
- **Status**: <upstream-changed | heading-removed | section-missing>
- **Routing**: docs/refreshing-kepano.md
- **Why**: pole 1 must be self-consistent before pole 3 can be audited against it.

Non-empty Bucket 0 halts audit. PA fixes pole-1 drift, then re-runs.

### Bucket 1 — Memory edits (<N>)

For each finding:

- **File**: <absolute path>
- **Lines**: <range>
- **Current**:
  ```
  <verbatim>
  ```
- **Proposed**:
  ```
  <verbatim>
  ```
- **Why**: <citation — file:line of the authoritative source in pole 1 or pole 2>

### Bucket 2 — Instructions edits (<N>)

For each finding:

- **Store**: <~/.claude/CLAUDE.md | <repo>/CLAUDE.md | Settings → General | Cowork → Global | Cowork folder | Cowork project | claude.ai project>
- **Location**: <path | "paste-only — skill cannot write">
- **Current**:
  ```
  <verbatim>
  ```
- **Proposed**:
  ```
  <verbatim>
  ```
- **Why**: <citation>

### Bucket 3 — Plugin-update candidates (<N>)

For each finding:

- **Source memory**: <file path>
- **Pattern**: <one-line summary of the recurring rule the memory documents>
- **Proposed target skill**: <existing skill name | "new skill: <proposed-name>">
- **Proposed rule shape**:
  ```
  <draft text suitable for the target skill>
  ```
- **Rationale**: why this belongs in plugin source rather than memory.

Recommendation only — plugin work goes through `/plugin-release` on a feature branch.

### Bucket 4 — Canonical-snippets edits (<N>)

For each finding:

- **Vault path**: 99 - Méta/AI/Claude/<file>
- **Section**: <heading>
- **Current**:
  ```
  <verbatim>
  ```
- **Proposed**:
  ```
  <verbatim>
  ```
- **Why**: <citation against pole 1 or pole 3>

## Out of scope (not audited)

- <N> memory entries did not match organon keywords (see `references/AUDIT_KEYWORDS.md`):
  - <list paths, one per line; max 20 lines, then "and <M> more">

## Recommended next step

- Bucket 0 (if any): resolve before continuing the audit.
- Bucket 1: walk per-finding `apply / skip / defer` (interactive mode) or apply manually after triage (report-only).
- Bucket 2: edit ~/.claude/CLAUDE.md and project CLAUDE.md directly; for Settings → General and Cowork → Global, copy the proposed text and paste on the matching surface.
- Bucket 4: patch the canonical vault note via mcp__mcp-tools-istefox__patch_vault_file (consult organon-vault-write for wire-format invariants).
- Bucket 3: open a tracking issue at folotp/organon-plugin for any candidate you want to act on.

## Empty-report short form

All buckets 0:

```markdown
# Organon memory & instructions audit — <YYYY-MM-DD HH:MM>
- Surface / scope / mode: <…>
- All four buckets empty. Stable run hash: <sha>.
- Pole 1 ↔ pole 2 ↔ pole 3 aligned. Next scheduled run: <if known>.
```
```
