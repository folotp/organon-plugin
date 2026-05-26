# Token harness methodology

Reproducible measurement of the runtime token cost of the organon plugin
across representative session shapes, with a built-in comparison between
the pre-absorption (cascade-eager) era and the post-absorption (lazy-load,
v0.4.0) era. Used to confirm that the absorption gain meets the recalibrated
target ratio (≥ 2.15× for B4-complet, per [[VLT-ADR-013]]).

This document is the **from-now-on** baseline for token-cost measurements
on the plugin: every kepano re-sync, every architecture change touching
runtime cost, and every absorption iteration should be measured against
this harness. The previous P6.2/P7.1 harness methodology was archived
without preservation; this is the reproducible replacement.

## Objective

Quantify the runtime token cost of the organon plugin on a fixed set of
representative session shapes, expressed as a ratio:

    ratio_S = pre_tokens(S) / post_tokens(S)

where `pre_tokens` simulates the cascade-eager era (all references for a
triggered skill load eagerly) and `post_tokens` is the v0.4.0 lazy-load
behavior (references load only when the session shape genuinely needs
them). Higher ratio = more savings = better.

The harness reports `mean(ratio_S)` over 10 sessions and a per-session
table.

## Why a from-now-on harness, not a reconstruction

The original P6.2/P7.1 measurements (1.38× and 1.55× respectively) were
run inside chat sessions whose detailed methodology was not preserved
in any vault note or repo artifact ([[VLT-BL-0063]] explicitly flags
this: « détail non préservé dans l'archive »). Reconstructing them
exactly is infeasible. Rather than fabricate a ratio with false
precision, this harness redefines the measurement protocol cleanly so
future iterations are reproducible.

The trade-off: measured ratios from this harness are **not directly
comparable** to the P6.2 1.38× or P7.1 1.55× numbers — different
baseline definitions. Comparability starts at iteration-2.

## Tokenizer choice — tiktoken cl100k_base

Token counts come from `tiktoken` with the `cl100k_base` encoding
(GPT-4 family, OpenAI). Three reasons:

1. **Local + reproducible.** No API key, no network call, no rate
   limit. Anyone with a Python install can reproduce the run.
2. **Bias cancels in ratio.** `cl100k_base` is not Claude's tokenizer,
   so absolute counts diverge from what Claude actually consumes
   (~5-15% for natural language). But the harness reports a *ratio* of
   pre to post counts, both measured with the same tokenizer — the
   bias is a constant factor that cancels.
3. **Stable across re-runs.** No dependency on a hosted service whose
   tokenizer can update silently.

If absolute (Claude-faithful) counts ever become necessary,
`anthropic.beta.messages.count_tokens` is the right call — but it's
overkill for the ratio question, which is the only one the target
(≥ 2.15×) cares about.

## File classification per skill

Each skill's files fall into three categories:

| Category | Behavior pre-absorption | Behavior post-absorption (v0.4.0) |
|---|---|---|
| `core` (SKILL.md) | Loaded when skill triggers | Same |
| `absorbed_refs` (references absorbed from kepano) | Loaded eagerly via cascade | Loaded only if session needs |
| `own_refs` (Organon-specific references) | Loaded only if session needs | Same |

`absorbed_refs` is the category where the absorption mechanism produces
runtime savings. `own_refs` is unchanged across eras and contributes
nothing to the ratio.

Per skill:

| Skill | core | absorbed_refs | own_refs |
|---|---|---|---|
| organon-frontmatter | SKILL.md | references/PROPERTIES.md | references/VOCABULARIES.md |
| organon-vault-write | SKILL.md | (none) | (none) |
| organon-vault-read | SKILL.md | (none) | references/READ_TOOL_MATRIX.md |
| organon-markdown-style | SKILL.md | references/MARKDOWN_SYNTAX.md, references/CALLOUTS.md, references/EMBEDS.md | (none) |
| organon-bases | SKILL.md | references/BASES_SYNTAX.md, references/FUNCTIONS_REFERENCE.md | (none) |
| organon-canvas | SKILL.md | references/CANVAS_SPEC.md, references/EXAMPLES.md | (none) |
| organon-diagramming | SKILL.md (absorbed inline) | (none, absorbed inline) | (none) |
| organon-session-discipline | SKILL.md | (none) | (none) |

`organon-diagramming` is a special case: the absorbed kepano content
was inlined into SKILL.md rather than split into a `references/` file.
The harness models this as core-only post-absorption — the gain from
inline absorption shows up indirectly via other skills that share the
absorbed content.

## Session shapes (13 sessions)

Each session represents a realistic Organon task and lists which skills
trigger plus which references the task genuinely needs (would consume
post-absorption). This list is the harness configuration; updating it
re-runs the measurement.

| ID | Session shape | Triggered skills | Refs needed (post) |
|---|---|---|---|
| S01 | Frontmatter touch (1-2 keys, no schema lookup) | frontmatter, vault-write | (none) |
| S02 | Structured note creation (ADR via Templater-first routing) | frontmatter, vault-write, session-discipline | PROPERTIES.md, VOCABULARIES.md |
| S03 | Body markdown style edit (typographic, no H1) | markdown-style | (none) |
| S04 | Bases simple filter add | bases | (none) |
| S05 | Bases deep schema (formula columns + custom views) | bases | BASES_SYNTAX.md, FUNCTIONS_REFERENCE.md |
| S06 | Canvas creation (file-node + group + edge) | canvas | CANVAS_SPEC.md, EXAMPLES.md |
| S07 | Multi-artifact session (BL + ADR + INC sequential) | frontmatter, vault-write, session-discipline | PROPERTIES.md, VOCABULARIES.md |
| S08 | Diagramming triage (mermaid vs canvas decision) | diagramming | (none) |
| S09 | Vault-write append (heading patch, no schema) | vault-write | (none) |
| S10 | Sweep / refactor wave (frontmatter migration N notes) | frontmatter, vault-write, session-discipline | VOCABULARIES.md |
| S11 | Atomic frontmatter write (`set_note_property`, 1-3 keys) | frontmatter, vault-write | (none) |
| S12 | Partial read (`get_vault_file_partial mode=heading`) | vault-read | (none) |
| S13 | Exploratory semantic pre-filter (`search_vault_smart` → top-3 partial reads) | session-discipline, vault-read | READ_TOOL_MATRIX.md |

S11-S13 added in v1.1.0 to measure the post-refactor leverage of atomic
frontmatter tools, partial reads, and the Rule 8 semantic pre-filter.
These shapes were not measurable before the connector exposed the new
tools and the vault-read skill was authored.

Sessions S01, S03, S04, S08, S09 are the « lean » shapes where the
absorption savings are largest (eager cascade load avoided entirely).
S02, S05, S06 are the « deep » shapes where the lazy load happens
anyway — savings are small or zero. S07 and S10 are mixed multi-step
shapes.

## Measurement protocol

1. Snapshot the v0.4.0 plugin tree (or whatever version is under test).
2. For each session shape:
   - `pre_tokens(S)`  = Σ tokens(core) over triggered skills
                     + Σ tokens(absorbed_refs) over triggered skills (eager)
                     + Σ tokens(own_refs needed by S) over triggered skills (lazy)
   - `post_tokens(S)` = Σ tokens(core) over triggered skills
                     + Σ tokens(refs needed by S) over triggered skills (lazy)
   - `ratio(S)`       = pre_tokens(S) / post_tokens(S)
3. Report per-session table + `mean(ratio)`.
4. Compare `mean(ratio)` against target ≥ 2.15× (B4-complet, [[VLT-ADR-013]]).

## Pass criterion

- **PASS**: `mean(ratio) ≥ 2.15`
- **PASS-marginal**: `2.0 ≤ mean(ratio) < 2.15` — within projection
  range from closure benchmark, target nominally missed but absorption
  still delivers material savings; investigate per-session outliers
  before re-engineering.
- **FAIL**: `mean(ratio) < 2.0` — gain below projection. Re-examine
  absorption scope or session-shape weighting.

## Limitations and assumptions

- **Conservative on the "core" delta.** Post-absorption SKILL.md files
  are slightly larger than pre-absorption (they absorbed key insights
  that previously came from cascade). The harness uses current
  SKILL.md sizes for both eras, which slightly under-counts pre era
  and slightly over-counts post era. Net effect: harness gives a
  modestly conservative ratio (real-world savings likely a hair
  better).
- **No system-prompt overhead.** The harness measures plugin runtime
  load only. System prompt, conversation history, and tool-result
  accumulation are out of scope — they're constant across eras and
  don't affect the ratio.
- **Discrete session shapes.** Real usage is continuous and mixed.
  Mean over the 10 shapes assumes uniform weighting; real workload
  weighting can be applied a posteriori by re-aggregating per-session
  ratios.
- **No measurement of own_refs being unused.** When an own_ref is not
  needed by a session, it doesn't contribute to either pre or post —
  cancels cleanly. When it IS needed, it contributes to both equally —
  also cancels. So own_refs are noise-canceled in the ratio and the
  harness doesn't need to model them precisely.

## Re-running the harness

```sh
cd ~/Developer/organon-plugin
python3 scripts/token-harness.py
```

Output: a per-session token table plus the mean ratio. JSON sidecar at
`eval-workspace/iteration-N/harness-output.json`.

To extend the session list, edit the `SESSIONS` list at the top of
`scripts/token-harness.py` — same shape as the table above. Re-run
freezes a new iteration in `eval-workspace/iteration-N/`.

## Provenance

- Author: Claude (this session, 2026-05-06).
- Commissioned by: PA, follow-up to VLT-BL-0063 closure (the formal
  P6.2 harness measurement bullet was deferred at closure).
- Replaces: the original P6.2/P7.1 chat-archived methodology that was
  not preserved.
- Referenced by: [[VLT-ADR-013]] (target ≥ 3-5× session, ≥ 2.15×
  B4-complet), [[VLT-BL-0063]] (formal harness measurement deferred).
