# Instruction-quality checks — organon-memory-audit

Catalogue for `--checks=quality|all`. Findings → Bucket 5. Lens: are instruction files well-formed, not do they agree (poles 1–3).

## Contents

- Protocol
- Target resolution
- Language
- Family 1 — orientation files
- Family 2 — organon-* skills
- Family 3 — rule buckets
- Reasoning-quality gate
- Exclusions

## Protocol

Every check: trigger → judged read → finding or discard.

1. Trigger = fast pattern match. Yields candidates, never a verdict.
2. Read candidate in context (5–15 lines). Whole section if a rule spans it.
3. Decide. Real → 1–2 sentences of `reasoning`, specific to this line and file. False positive → discard, count it.
4. No concrete fix → no finding.

Lexical triggers skip frontmatter (family 2 excepted), fenced code, inline code.

Same line hit by several checks → one finding, all ids in `check`, highest severity.

Function over form: cite evidence from this vault or plugin. A source-framework convention alone justifies nothing.

Finding shape:

| Field | Content |
|---|---|
| `check` | id(s), e.g. `Q1.2`, `Q3/bare` |
| `path`, `line` | 1-indexed (MCP lines are 0-indexed → +1) |
| `severity` | `warn` / `fail` |
| `excerpt` | verbatim |
| `reasoning` | case-specific |
| `action` | concrete fix, or `upstream-pinned` |
| `language` | `en` / `fr`; `fr` adds `FR heuristic — uncalibrated` |

## Target resolution

Resolve by role, so a vault reorg doesn't break the audit. Print resolved list in report header.

**Orientation files** (family 1): notes read at session start or carrying always-applicable rules.

1. Seeds: session-start read instructions in canonical snippets note; `<organon>` block of `~/.claude/CLAUDE.md` on Code.
2. Follow links from seeds, one level. Keep notes with orientation role; skip domain-specific and on-demand notes.
3. Always in set, linked from seeds or not: `AI Bootstrap.md`, `Vault Conventions.md`, `Index — Contrôles.md`. Not resolved → `search_files_by_name`. Still missing → report-header note, not a finding.
4. Rules dirs: `~/.claude/rules/`, `<repo>/.claude/rules/` if present.

Seed stores are not targets — drift audit covers them.

**Skills** (family 2): `${PLUGIN_ROOT}/skills/organon-*/SKILL.md` + `references/*.md`. No filesystem (Cowork/Chat) → family 2 unavailable, say so in header.

**Rule files** (family 3): orientation files that hold instructions + rules dirs + every `organon-*` SKILL.md. Skip catalogue notes (e.g. control index) and `references/`.

**Pinned files**: paths from `ABSORBED_PATHS` in `scripts/hooks/block-absorbed-edits.sh`. See Exclusions.

## Language

Line language follows its note's folder (`organon-markdown-style`): `99 - Méta/AI/` EN, other vault folders FR; plugin files EN. Quoted other-language line → its own language.

Apply matching list only. EN list never runs on FR content.

| Trigger | EN | FR |
|---|---|---|
| Vague | `properly`, `correctly`, `clean`, `good`, `appropriate`, `reasonable`, `sensible`, `nicely`, `carefully`, `thoughtfully`, `as needed`, `when appropriate`, `as you see fit`, `be careful`, `follow best practices`, `use good judgment` | `correctement`, `proprement`, `bien`, `approprié(e)`, `raisonnable`, `judicieux`, `soigneusement`, `au besoin`, `si nécessaire`, `selon le cas`, `faire attention`, `bonnes pratiques`, `bon jugement` |
| Platitude | `write clean code`, `follow best practices`, `be careful`, `test your changes`, `do your best`, `be thorough` | `écrire du code propre`, `suivre les bonnes pratiques`, `faire attention`, `tester ses changements`, `faire de son mieux`, `être rigoureux` |
| Emphasis | `IMPORTANT`, `YOU MUST`, `CRITICAL`, `NEVER`, `ALWAYS`, `MUST`, `REQUIRED` | `IMPORTANT`, `TU DOIS`, `CRITIQUE`, `JAMAIS`, `TOUJOURS`, `DOIT`, `OBLIGATOIRE`, `IMPÉRATIF` |
| Modal | `always`, `never`, `must`, `don't` | `toujours`, `jamais`, `doit`, `ne pas` |
| Causal | `because`, `since`, `so that`, `otherwise` | `parce que`, `car`, `puisque`, `afin de`, `sinon` |

Thresholds and FR lists uncalibrated on FR → every `fr` finding carries the label. Bias to discard when unsure.

Terse causal forms count in both languages: `X — breaks Y`, `X → Y`, `X (reason)`, `Why:` line. Terse style is repo convention; absence of a full sentence is no finding, and rewrites stay terse.

## Family 1 — orientation files

Pruning test: removing this line would cause mistakes? No → cut. Specific rules are followed far more reliably than vague ones.

| Id | Check | Trigger | Judge / fix |
|---|---|---|---|
| Q1.1 | Size | warn 200–300 lines, fail >300 (excl. frontmatter) | Routing tables compress well in attention; judge structure, not count alone. Name what to cut or move |
| Q1.2 | Specificity | Vague list | Not vague if line cites anchor (path, tool, command, threshold). Rewrite with existing anchor: CTRL id, frontmatter key, named skill |
| Q1.3 | File-by-file blocks | ≥6 contiguous items/rows, ≥4 describing a file/folder in >40 chars | Claude can read the vault. Short routing table (≤1 line/cell) → discard |
| Q1.4 | Platitudes | Platitude list, no anchor on line | Delete |
| Q1.5 | Emphasis ratio | emphasis markers ÷ rules (list items + imperative sentences): warn >0.3, fail >0.5 | Earned if genuinely safety-critical (CTRL description) → discard. Name lines to soften |
| Q1.6 | Position | First ~30 lines | Load-bearing rules up front, or preamble? Start and end get most attention, middle least. Name lines to move |
| Q1.7 | H1 repeats title | H1 in body | Already forbidden by `organon-markdown-style`: cite that rule, don't restate it |
| Q1.8 | Conflicts | Opposite modals, ≥3 shared content tokens after stopwords; within file and against the skill owning the topic. Token count approximate on vault notes | Read both. Different scope or stated exception → discard. Real → both excerpts + which should win + why |
| Q1.9 | Restatements | Rule duplicating a convention owned elsewhere (e.g. key order → `organon-frontmatter`) | Replace with pointer to canonical source |

## Family 2 — organon-* skills

Tiers: `name` + `description` load every session; body loads when relevant; references on demand. Keep each tier lean.

| Id | Check | Trigger | Judge / fix |
|---|---|---|---|
| Q2.1 | Body size | warn 400–500 lines, fail >500 (excl. frontmatter) | Name sections to move to `references/` |
| Q2.2 | `name` | >64 chars; not lowercase/digits/hyphens; contains `anthropic`/`claude`; XML tags | Propose valid name, list callers to update |
| Q2.3 | `description` | Empty; >1024 chars; missing what or when | Drives selection, most important field. Must state both, with trigger phrasing. User-only skill: invocation counts as when |
| Q2.4 | Reference depth | `references/*.md` linking another reference as required reading, target not linked from SKILL.md | Exactly one hop from SKILL.md: Claude may partial-read and miss a 2-hop chain. Link directly from SKILL.md. Verify all skills, not only those claiming it |
| Q2.5 | Reference TOC | `references/*.md` >100 lines without `## Contents` | Add TOC, so full read not truncated `head`. List the actual headings. Mostly one fenced template → discard |
| Q2.6 | Terminology | Several terms for one concept in a SKILL.md (vault/knowledge base, control/check for CTRL) | Real synonyms only: `note` vs `file` can be a deliberate distinction. Name canonical term |
| Q2.7 | Tool names and params | Tool name, param or mode named in skill | Compare against live schema (`ToolSearch`, `tool_catalog`). Fires on wrong name, stale prefix, wrong param, tool unavailable. Canonical prefix `mcp__claude_ai_organon__*`; bare correct name → discard. Read-only probe call OK as evidence; never a write tool |
| Q2.8 | Person | `I can`, `I help`, `Use me`, `you can` in `description` | Rewrite third person. Imperative `Use when…` = accepted trigger form → discard |
| Q2.9 | Skill-vault duplication | Reference re-describing a vault-canonical note (e.g. CTRL catalogue vs `Index — Contrôles.md`) | Quote overlap from both. Read vault note first. Deliberate offline snapshot stated as such → discard. Fix: point at note, drop copy |

## Family 3 — rule buckets

Claude-5-generation models follow judgment better than bare rules. `never X` overfits or gets dropped; `X breaks because Y` generalises. Old failure = undertriggering → emphasis; current failure = overtriggering → same emphasis distorts, verify-lines cause redundant work.

Classify every instruction line into one bucket; routing lines, reasoned rules and data rows fit none → count as `OK`. Don't jump to rewriting.

| Bucket | Id | Signal | Action |
|---|---|---|---|
| RETIRED | `Q3/retired` | Model does it unprompted: `double-check your work`, `verify before responding`, `think step by step`, `be thorough`, `re-read the file`, `you are an expert…` | Delete |
| ONE-SIDED | `Q3/one-sided` | Cost or command with no counterweight → overfits | Both sides + decision criterion |
| BARE PROHIBITION | `Q3/bare` | `never`/`always`/`do not`, no causal form (see Language) | `[behavior] — [reason]`. Reason not in context → UNSURE |
| AGGRESSIVE | `Q3/aggressive` | `CRITICAL`, `YOU MUST`, ALL-CAPS, `!!!`, bold runs → routine steps read as safety boundaries | Sentence case, keep instruction |
| OBVIOUS | `Q3/obvious` | Discoverable by listing vault or reading file, no why or where-to-put | Delete |
| KEEP (hard rule) | `Q3/keep-hard` | Safety, destructive/irreversible, client/team-facing, money, credentials, data loss; CTRL enforcement, ULID assignment, vault-write safety | Untouched. Bare and forceful is correct |
| KEEP (gotcha) | `Q3/keep-gotcha` | Non-obvious, undiscoverable fact (EJS-literal Templater invariant, fenced-code H2 patch trap) | Untouched. Most valuable lines |
| UNSURE | `Q3/unsure` | Bare prohibition, reason unrecoverable; or bucket undecidable | Question for PA, no proposed line |

Hard rules:

- Never rewrite or soften a KEEP line. Fewer correct changes beat many cosmetic ones.
- Never invent a reason. Unknown → UNSURE + question.
- Routing ("where does X go") never OBVIOUS, even when naming a folder: most valuable class of line.
- Hard-rule test beats AGGRESSIVE and BARE: a forceful data-loss rule stays.
- KEEP line factually wrong or self-defeating → not a rewrite: report under `Off-catalogue` with evidence. Correctness, not softening.

**Missing guardrails** (`Q3/guardrail`): instruction layer lacks a guardrail for a documented difference of the model generation in use. Known candidates: fewer search/retrieval calls at low effort; whole-file rewrites over surgical edits; quoted passages reproduced unmarked; fewer tool calls per turn.

- Propose only for failure modes plausible in this vault's usage, with evidence. Read-only flows need no surgical-edit reminder.
- Published wording where available; otherwise mark `wording: draft`.
- No source for the behaviour difference → UNSURE.

Output per file:

```
RETIRED n → delete | BARE PROHIBITION n → rewrite | ONE-SIDED n → add counterweight
AGGRESSIVE n → soften | OBVIOUS n → delete | UNSURE n → ask PA
KEEP (hard rule) n → untouched | KEEP (gotcha) n → untouched | OK n | est. line reduction x%
```

Counts approximate → prefix `~`. Then three-column review, changed lines only: original / proposed or DELETE / one-line reason + bucket. KEEP lines count, not listed.

## Reasoning-quality gate

Reasoning that restates the rule ("this rule is vague") is a bug, not a finding.

After each family:

1. Sample up to 5 findings, across files.
2. Paraphrase test: would `reasoning` still read true pasted onto another line caught by same check? Yes → paraphrase.
3. ≥2 paraphrases → re-read all that family's candidates with wider context (≥15 lines, plus cited sources), rewrite or discard.
4. One re-run only. Then re-test whole family; remaining paraphrases → drop, count in report.

Report per family: candidates, discarded, findings, sampled, paraphrases, re-run y/n, dropped. Candidates = discarded + findings + dropped.

Family with no findings → explicit `no findings for family N` line, never silence.

## Exclusions

- **Pinned files**: one finding per file at most, `action: upstream-pinned`, no fix offered. Bytes come from kepano; route to `docs/refreshing-kepano.md`.
- **Obsidian-owned paths**: `.obsidian/`, index and sync state. Never targets.
- **Fix walk**: lives in `SKILL.md`, not here. Executor proposes only.

Real defect no check covers → `Off-catalogue` section of report, with evidence and fix.
