# Report template — organon-memory-audit

Render inline in conversation. Write to file only if PA explicitly asks — conversation is the persistence.

`Stable run hash`: sha256 of `(plugin.json content + kepano-version.txt content + canonical vault note body + companion matrix body)`. Same hash on two consecutive runs = pole 1 + pole 2 unchanged.

## Contents

- Report skeleton: Run, Sources of truth, Findings, Out of scope, Recommended next step
- Empty-report short form

````markdown
# Organon memory & instructions audit — <YYYY-MM-DD HH:MM>

## Run
- Surface: <Code | Cowork | Chat-Desktop | Chat-web | Chat-mobile>
- Scope: <global | project=<slug> | all>
- Mode: <interactive | report-only>
- Plugin source: <readable at <path> | inferred from harness skill list>
- Canonical vault note: <read at <vault path> | not reachable (no MCP) | paste-driven>
- Checks: <drift | quality | all>
- Integrity gate: <kepano-check-upstream exit 0 | DRIFT — see Bucket 0 | skipped (--checks=quality)>
- Quality targets: <resolved orientation files, skills, rule files; or "not run">

## Sources of truth
- Plugin v<X.Y.Z> @ <git short SHA> (<commit date>)
- Skills (<N>): <comma-separated names, with `(user-only)` annotation for disable-model-invocation: true>
- Commands (<N>): <comma-separated names>
- MCP server floor: mcp-tools-istefox >= <X.Y.Z>
- Kepano pin: <in-sync at <sha> | upstream advanced (pinned <sha>, HEAD <sha>) | gate unavailable rc=N>
- Canonical snippets last synced: <date from each per-surface bloc>
- Stable run hash: <sha256 short> (pole 1 + 2 only — same hash doesn't mean quality targets unchanged)

Under `--checks=quality`: MCP floor, kepano pin, last synced, run hash → `n/a`.

## Findings

### Bucket 0 — Plugin internal drift (<N>)

One finding:

- **Source**: kepano-check-upstream
- **Status**: upstream advanced (pinned <sha>, HEAD <sha>)
- **Routing**: docs/refreshing-kepano.md
- **Why**: absorbed bytes stay valid at the pin, so this is informational. Audit continues.

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

Recommendation only — plugin work goes through `/pa-toolkit:plugin-release` on a feature branch.

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

### Bucket 5 — Instruction quality (<N>)

Omit section if `--checks=drift`. Family with no findings → `No findings for family <N>`, never omitted.

Per family:

- **Gate**: <candidates> candidates, <discarded> discarded, <findings> findings; sampled <n>, paraphrases <n>, re-run <y/n>, dropped <n>

For each finding (families 1, 2):

- **Check**: <Q1.2 — specificity>
- **Location**: <path>:<line>
- **Severity**: <warn | fail>
- **Language**: <en | fr — FR heuristic, uncalibrated>
- **Excerpt**:
  ```
  <verbatim>
  ```
- **Reasoning**: <specific to this line and file>
- **Action**: <concrete fix | upstream-pinned>

Family 3, per file:

```
<path>
RETIRED n → delete | BARE PROHIBITION n → rewrite | ONE-SIDED n → add counterweight
AGGRESSIVE n → soften | OBVIOUS n → delete | UNSURE n → ask PA
KEEP (hard rule) n → untouched | KEEP (gotcha) n → untouched | OK n | est. line reduction x%
```

| Line | Original | Proposed or DELETE | Reason + bucket |
|---|---|---|---|

`UNSURE` lines: question for PA in place of proposed text.

#### Off-catalogue

Defects no check id covers, or KEEP lines factually wrong. Same fields, `Check: off-catalogue`.

## Out of scope (not audited)

- <N> memory entries did not match organon keywords (see `references/AUDIT_KEYWORDS.md`):
  - <list paths, one per line; max 20 lines, then "and <M> more">

## Recommended next step

- Bucket 0 (if any): informational; refresh via docs/refreshing-kepano.md when convenient.
- Bucket 1: walk per-finding `apply / skip / defer` (interactive mode) or apply manually after triage (report-only).
- Bucket 2: edit ~/.claude/CLAUDE.md and project CLAUDE.md directly; for Settings → General and Cowork → Global, copy the proposed text and paste on the matching surface.
- Bucket 4: patch the canonical vault note via mcp__claude_ai_organon__patch_vault_file (consult organon-vault-write for wire-format invariants).
- Bucket 3: open a tracking issue at folotp/organon-plugin for any candidate you want to act on.
- Bucket 5: walk per-finding `apply-now / edit-first / decline`. Never bulk-applied.
````

## Empty-report short form

All buckets 0:

```markdown
# Organon memory & instructions audit — <YYYY-MM-DD HH:MM>
- Surface / scope / mode: <…>
- All buckets run were empty. Stable run hash: <sha>.
- Pole 1 ↔ pole 2 ↔ pole 3 aligned. Next scheduled run: <if known>.
```
