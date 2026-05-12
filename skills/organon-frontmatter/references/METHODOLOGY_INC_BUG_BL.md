# Méthodologie — INC / BUG / BL (AI-slim)

**Source**: `[[Méthodologie — Incidents, bugs et backlog]]` (vault, canonical).
**Use**: composing/editing INC/BUG/BL fiches and transitioning their lifecycle.

**Active domains**: `VLT` (INC + BUG + BL); `SD` (BL only).

---

## INC — Incident

One observed occurrence. Immutable after recording.

**Naming**: `<DOMAIN>-INC-NNNN` — folder `<DOMAIN>/Incidents/`

**Status transitions**:

| From | To | Trigger |
|---|---|---|
| (new) | `recorded` | Fiche created |
| `recorded` | `assigned` | Linked to a BUG via `bug:` field |

**Required frontmatter**:

```yaml
id: <DOMAIN>-INC-NNNN
type: incident
date: YYYY-MM-DD
surface: <enum>
layer: <enum>
tool: <value>
operation: <enum>
status: recorded
up: ["[[Index — <DOMAIN>-INC]]"]
# optional:
bug: "[[<DOMAIN>-BUG-NNN]]"
```

**Lifecycle rules**:
- Append-only. Never rewrite past content.
- IF a cause hypothesis arises during observation → record it in a BUG fiche, NOT here.
- IF a `bug:` link is added later → update `status: assigned`.

---

## BUG — Bug

One underlying problem explaining recurring or severe incidents.

**Naming**: `<DOMAIN>-BUG-NNN` — folder `<DOMAIN>/Bugs/`

**Status transitions**:

| From | To | Condition |
|---|---|---|
| `open` | `investigating` | Diagnostic work started |
| `investigating` | `root-cause-known` | Root cause confirmed |
| `root-cause-known` | `fix-designed` | Remediation designed |
| `fix-designed` | `fix-deployed` | Fix applied |
| `fix-deployed` | `verified` | No recurrence on ≥ 1 subsequent session |
| `verified` | `closed` | Stable |

**Required frontmatter**:

```yaml
id: <DOMAIN>-BUG-NNN
type: bug
status: open
severity: <enum>
up: ["[[Index — <DOMAIN>-BUG]]"]
# optional:
component: <value>
first-incident: "[[<DOMAIN>-INC-NNNN]]"
last-occurrence: "[[<DOMAIN>-INC-NNNN]]"
remédiation: ["[[<DOMAIN>-BL-NNNN]]"]
```

**Lifecycle rules**:
- IF ≥ 3 incidents share a pattern → create BUG.
- IF 1 incident has obvious/reproducible root cause → create BUG.
- IF 1 incident caused data loss, corruption, or blocked critical workflow → create BUG.
- ELSE → leave incident at `recorded`; promote later if recurrent.
- AT closure → evaluate lesson-learned conversion (generality / transfer value / reintroduction risk criteria).

---

## BL — Backlog

One atomic work item to execute.

**Naming**: `<DOMAIN>-BL-NNNN` — folder `<DOMAIN>/Backlog/`

**Status transitions**:

| From | To | Condition |
|---|---|---|
| `open` | `planned` | Scheduled |
| `planned` | `in-progress` | Work started |
| `in-progress` | `done` | Work complete |
| `done` | `verified` | Acceptance criteria confirmed |
| any | `abandoned` | Documented reason |

**Required frontmatter**:

```yaml
id: <DOMAIN>-BL-NNNN
type: backlog
status: open
priority: <enum>
origin: <enum>
up: ["[[Index — <DOMAIN>-BL]]"]
# required if origin: bug:
linked-bug: "[[<DOMAIN>-BUG-NNN]]"
# optional:
effort: <value>
```

**Lifecycle rules**:
- IF a BUG remediation is concrete enough to track → create BL; link in `bug.remédiation:`.
- IF item is a micro-adjustment → keep in fiche journal, do NOT create a BL.
- IF `status: done` but not yet observed without recurrence → stay `done`, not `verified`.

---

## Cross-shape flow

```
INC → (promotion criteria met) → BUG
BUG → (root cause → remediation designed) → BL
BL → (executed + verified) → BUG moves to fix-deployed → verified → closed
```

---

## MCP write discipline

After any `create_vault_file` / `patch_vault_file` / `append_to_vault_file` on a critical chain:

1. Re-read the file immediately.
2. Compare `id:`, `status:`, `bug:`, `linked-bug:`, `up:`, and any `[[…]]` wikilink to intent.
3. IF mismatch → do NOT retry same write; use `create_vault_file` (full rewrite) and record an INC.

Why: VLT-BUG-005 / VLT-INC-0022 demonstrated silent mutation with no error returned.

---

## Anti-patterns

- Creating a BUG for each INC — dilutes the registry; wait for promotion criteria.
- Recording hypotheses in an INC fiche — breaks append-only; hypotheses belong in BUG.
- Closing a BUG at `fix-deployed` without a verified observation session.
- Creating BL items for micro-adjustments — journal entries suffice.
- Inventing a 4th type (debt, risk, observation…) — test INC/BUG/BL first.
- Recycling an ID after supersession — retired IDs stay retired.
