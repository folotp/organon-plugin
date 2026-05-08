# Méthodologie — Incidents, bugs et backlog (distilled, Claude-actionable)

**Distilled** from `[[Méthodologie — Incidents, bugs et backlog]]` (vault) at 2026-05-08. The vault file is the canonical methodology; this file is the Claude-actionable subset for composing/editing INC/BUG/BL fiches and transitioning their lifecycle. Re-derive manually after material methodology changes — there are no drift markers (Organon-owned, vault-inspired). Read this when creating an incident, bug, or backlog item, or when transitioning their status.

## Scope — three atomic types

Applies to any domain adopting the INC/BUG/BL triplet. **Active domains:**

- **`VLT`** — full triplet (INC + BUG + BL). Index: [[Index — Accès à Obsidian par Claude]].
- **`SD`** — BL only. Index: [[Mon système documentaire]].

### `<DOMAIN>-INC` — Incident

**One observed occurrence.** Something happened (timeout, error, wrong result, refused parameter…). Immutable after recording.

- **Shape**: short (1-3 paragraphs). Describes context, symptom, mitigation used.
- **Lifecycle**: `recorded` → (eventually) `assigned` to a bug. Never modified retroactively except to add a bug link.
- **Discipline**: append-only. A recorded incident stays as-is. If you later learn it had a different cause, do NOT rewrite — add a line to its journal.

### `<DOMAIN>-BUG` — Bug

**One underlying problem.** Explains why incidents recur. N:1 relationship with incidents (one bug groups several incidents).

- **Shape**: more substantial. Problem description, affected component, cause hypotheses, tests, root cause when identified, proposed remediation.
- **Lifecycle**: `open → investigating → root-cause-known → fix-designed → fix-deployed → verified → closed`. Each transition dated in the journal.
- **Discipline**: a bug fiche is NOT created for every incident. Typical threshold: ≥ 3 incidents share a pattern, OR 1 incident with an obvious actionable root cause.

### `<DOMAIN>-BL` — Backlog

**A work item to execute.** Atomic action — capability to add, verification to do, remediation to implement.

- **Shape**: short to medium. Object, trigger, prerequisites, acceptance criteria, estimated effort.
- **Lifecycle**: `open → planned → in-progress → done → verified`. Can become `abandoned` with documented reason.
- **Origin**: can come from a bug (its remediation), an identified need, a roadmap, or a verification to perform. All "we should do X" items live here.

## Flow

```
An incident occurs
  → <DOMAIN>-INC-NNNN created (Phase A: raw observation)

≥ 3 incidents share a pattern OR 1 incident has an obvious cause
  → <DOMAIN>-BUG-NNN created (Phase B: diagnosis)
  → Concerned incidents retroactively linked to the bug via their `bug:` field

Bug investigated → root cause identified
  → Remediation designed

Remediation = concrete work to execute
  → <DOMAIN>-BL-NNNN created (prescriptive)
  → Bug references the backlog item(s) in its `remédiation:` field

Backlog item executed → verified
  → Bug moves to fix-deployed, then verified after no recurrence observed
  → Bug closed
```

## Promotion criteria (incident → bug)

An incident becomes a bug candidate when **at least one** is satisfied:

- **Recurrence**: ≥ 3 incidents with similar symptom and context.
- **Identifiable cause**: a single incident suffices if root cause is obvious and reproducible.
- **Severity**: a single incident suffices if it caused data loss, corruption, or blocked an important workflow.

Conversely, some incidents do **NOT** become bugs:

- Incorrect tool use (human or agent error) — recorded, not promoted.
- Expected but little-known behavior — recorded as good-practice documentation, not promoted.
- Single incident with no pattern or severity — stays `recorded`, may be promoted later if recurrent.

## Phase A / B / C — temporal discipline

| Phase | Activity | Output | Where |
|---|---|---|---|
| **A — Observation** | Record what happened | `<DOMAIN>-INC-NNNN` | `<DOMAIN>/Incidents/` |
| **B — Diagnosis** | Extract patterns, hypothesize and test causes | `<DOMAIN>-BUG-NNN` + journal updates | `<DOMAIN>/Bugs/` |
| **C — Remediation** | Execute actions that close the bug | `<DOMAIN>-BL-NNNN` (prescriptive) + bug updates | `<DOMAIN>/Backlog/` |

For VLT: `99 - Méta/Outils/Accès à Obsidian par Claude/Incidents/`. For SD: not yet instantiated.

**Discipline rule**: in Phase A, NO cause hypothesis is recorded in the incident fiche. If an idea emerges during observation, note it in a bug fiche (existing or new), **NOT** in the incident. This protects the integrity of the append-only incident log and prevents the observation registry from becoming a hypothesis journal.

## Lesson learned conversion (on bug closure)

At each `<DOMAIN>-BUG` closure, Claude proposes explicitly to PA whether the lesson should be converted to a lesson-learned note. Conversion is required if **at least one** of:

1. **Generality** — lesson applies beyond the source bug (targets a principle, method, convention).
2. **Transfer value** — lesson would be useful to a future agent or PA in a future session start, without bug context.
3. **Reintroduction risk** *(secondary marker, optional)* — active recurrence risk. Entries with this flag are prefixed "⚠ Risque de réintroduction" in their title and read at session start with priority.

**Entry shape**: ≤ 5 lines — Contexte / Leçon / Règle opérationnelle / Source. Canonical format in `[[Lessons Learned — Accès de Claude à Organon#Format d'une entrée]]`.

**Convention "propose to PA"**: at bug closure, the agent evaluates the 3 criteria and formulates a proposal: "Je propose de convertir en lesson learned: `<règle opérationnelle>`. Critères déclencheurs: G/T/R. Risque réintroduction: Y/N. Conteste si non." PA arbitrates by default tacit acceptance.

## MCP write discipline

Any MCP write on a critical chain (frontmatter, wikilink) is followed by re-read and diff between intent and persisted content. Applies regardless of operation (`create_vault_file`, `patch_vault_file`, `append_to_vault_file`).

**Why.** [[VLT-BUG-005]] showed a written chain can be silently altered with no error returned (silent mutation — incident [[VLT-INC-0022]]). A byte-identical round-trip is the only guarantee.

**Procedure.**

1. Emit the MCP write.
2. Re-read the file immediately (`get_vault_file` or `search_vault_simple` with a characteristic token).
3. Compare persisted value to intent: string identity on frontmatter and targeted wikilinks.
4. On mismatch: do NOT retry the same write — switch to `create_vault_file` (full rewrite) and record an incident `<DOMAIN>-INC-NNNN`.

**Priority perimeter.** `id:`, `status:`, `bug:`, `linked-bug:`, `up:`, and any field containing a `[[…]]` wikilink. Free-text fields (title, body) are less critical but benefit from the same verification reflex.

## Mandatory frontmatter shapes

See `REGISTRE_KEYS.md` for full per-domain tables. Quick reference:

- **`<DOMAIN>-INC`** — required: `id`, `type: incident` (VLT) / TBD (other domains), `date`, `surface`, `layer`, `tool`, `operation`, `status` (default `recorded`), optional `bug` wikilink. See `VOCABULARIES.md` for `surface | layer | operation | vlt-inc-status` enums.
- **`<DOMAIN>-BUG`** — required: `id`, `type: bug`, `status` (lifecycle enum), `severity`, optional `component`, `first-incident`, `last-occurrence` wikilinks. See `VOCABULARIES.md` for `vlt-bug-status | vlt-bug-severity` enums.
- **`<DOMAIN>-BL`** — required: `id`, `type: backlog`, `status`, `priority`, `origin`, conditional `linked-bug` (if `origin: bug`), optional `effort`. See `VOCABULARIES.md` for `vlt-bl-status | vlt-bl-priority | vlt-bl-origin` enums.

All three shapes also require `up: ["[[Index — <DOMAIN>-<TYPE>]]"]` for routability.

## Anti-patterns

- **Creating a bug for each incident.** Dilutes the bug registry's value. Wait for promotion criteria.
- **Mixing diagnosis and observation in an incident fiche.** Breaks append-only. Hypotheses go in a bug fiche.
- **Closing a bug without verified.** A deployed fix unobserved on ≥ 1 subsequent session without recurrence stays `fix-deployed`, not `verified` or `closed`.
- **Creating a backlog item for every minor mentioned action.** A backlog item earns its ID when distinct enough to track. Micro-adjustments stay in fiche journals.
- **Inventing a 4th type (debt, risk, observation, …).** Always test first whether incident/bug/backlog suffices. The temptation will return; see `PREFIXES.md` §Anti-patterns.
- **Recycling an ID after fiche supersession.** IDs are stable. Old IDs stay retired; new fiche gets a fresh number.
