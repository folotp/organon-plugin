---
name: organon-memory-audit
description: Three-pole drift audit over Organon-related memory and instruction stores — aligns plugin/skill/tool reality, the canonical-snippets vault note, and per-surface implementations (Settings → General, Cowork → Global, ~/.claude/CLAUDE.md, project CLAUDE.md, per-surface memory). Surface-aware (Code / Cowork / Chat). Two scope modes (--scope=global default / --scope=project[=<slug>] / --scope=all) and two interaction modes (--mode=interactive default / --mode=report-only). User-only — drifts and staleness are raised for human-in-the-loop approval; edits are never auto-applied. Run manually with `/organon-memory-audit` or as a scheduled Cowork routine / Code remote agent in --mode=report-only. Skipping the surface-detection probe and writing edits to paste-only stores (Settings → General, Cowork → Global) is the recurring failure mode this skill prevents.
disable-model-invocation: true
---

# organon-memory-audit

End-to-end runbook for auditing Organon-related drift across three poles:

1. **Plugin / skill / tool capabilities** — runtime ground truth (`plugin.json`, `kepano-sync.json`, `vault-sync.json`, every `skills/*/SKILL.md` description, `commands/*.md`, MCP server floor).
2. **Canonical-snippets vault note** — the unified source PA copy-pastes from: `99 - Méta/AI/Claude/Canonical snippets — per-canal Claude instructions.md`, with companion matrix `99 - Méta/AI/Claude/Claude surfaces and instruction inheritance.md`.
3. **Per-surface implementations** — what is currently active in each store: `~/.claude/CLAUDE.md` (Code's global), Settings → General → Instructions for Claude (chat surfaces' global), Cowork → Global instructions (Cowork's global), Cowork folder/project instructions, claude.ai project instructions, plus per-surface memory (Code filesystem, Cowork server-side, Chat server-side).

The audit reads pole 1 + pole 2, walks every pole-3 target reachable from the current surface, and emits a four-bucket triage report. Bundles the kepano-sync and vault-sync invocations as the first integrity gate — if either reports drift, the audit halts the alignment work and routes to `/kepano-resync` or vault re-sync first.

`disable-model-invocation: true` — invoke deliberately via `/organon-memory-audit` or via a scheduled run.

## When this skill applies

- PA invokes `/organon-memory-audit` (manual hygiene sweep).
- A scheduled Cowork routine fires `/organon-memory-audit --scope=all --mode=report-only` on cadence.
- A Code-side scheduled remote agent (`schedule` skill) fires the same.
- Immediately after a `/plugin-release` cuts a new version (manual ad-hoc run on Code).
- After a long Organon-touching working session that produced new memory entries.

Not applicable when: PA wants to *create* a new memory entry — that's normal save flow, not audit. The audit assumes memory and instruction stores already exist and walks them.

## Flags

Parse from the user's invocation string (the slash-command wrapper forwards them verbatim). Defaults if absent: `--scope=global --mode=interactive`.

- `--scope=global` (default) — current surface's global store + canonical doc + plugin reality.
- `--scope=project[=<slug>]` — project-specific stores. On Code: `<slug>/CLAUDE.md`, `<slug>/CLAUDE.local.md`, `~/.claude/projects/<slug>/memory/`. If `<slug>` omitted, current CWD project. On Cowork: current project's folder + project instructions + memory.
- `--scope=all` — global + every reachable project on the current surface. Code only (Cowork/Chat have no cross-project reach; treat as `--scope=global` plus current project).
- `--mode=interactive` (default) — emit report, then walk findings with per-finding `apply / skip / defer` prompts.
- `--mode=report-only` — emit report and exit. Required for scheduled runs (no PA in the loop). PA can later resume triage interactively by pasting the report back.
- `--surface=code|cowork|chat` (override) — skip surface detection, force a specific branch. For testing only.

## Surface detection (first action on every run)

Probe in order, log each result in the report header:

1. Read `/Users/pierreandre/.claude/projects/` — if it exists and lists project dirs, surface = **Code**.
2. Else, attempt to read `/` via the Read tool — if a Cowork-style mount is visible (typically `/mnt/...` or `/workspace/...`), surface = **Cowork**.
3. Else, surface = **Chat**. Probe MCP availability via `mcp__mcp-tools-istefox__get_server_info`. If absent → web/mobile (paste-only mode); if present → Desktop Chat.

If `--surface=` is passed, skip probes.

## Pole 1 — read plugin / skill / tool reality

On Code (filesystem available):

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-/Users/pierreandre/Developer/organon-plugin}"
```

Read:

- `${PLUGIN_ROOT}/.claude-plugin/plugin.json` → version, name, description.
- `${PLUGIN_ROOT}/kepano-sync.json` → upstream baseline SHA, per-section `body_sha256`, `drift_status`.
- `${PLUGIN_ROOT}/vault-sync.json` → vault baseline, per-entry `body_sha256`, `drift_status`.
- `${PLUGIN_ROOT}/skills/*/SKILL.md` frontmatter blocks → canonical skill names + descriptions + `disable-model-invocation` flag.
- `${PLUGIN_ROOT}/commands/*.md` → published slash commands.
- `git -C "${PLUGIN_ROOT}" log --oneline -20` → recent release context.
- `git -C "${PLUGIN_ROOT}" tag --sort=-version:refname | head -5` → recent tags.

**Integrity gate:**

```bash
"${PLUGIN_ROOT}/scripts/sync-kepano.sh" --no-fetch || KEPANO_DRIFT=1
"${PLUGIN_ROOT}/scripts/sync-vault.sh" || VAULT_DRIFT=1
```

If either reports drift (exit 1), the audit emits a Bucket-0 finding ("plugin internal drift detected") and recommends running `/kepano-resync` or following `docs/syncing-vault.md` *before* continuing alignment work. Do not proceed to pole-3 reads until pole 1 itself is consistent.

On Cowork / Chat (filesystem not available the same way): infer pole 1 from the harness's published skill list and the canonical vault note's "Plugin name canonicalisation" section. The integrity gate is unavailable on those surfaces — note that limitation in the report header.

## Pole 2 — read canonical-snippets vault note

Via MCP (works on Code, Cowork, Desktop Chat):

```
mcp__mcp-tools-istefox__get_vault_file "99 - Méta/AI/Claude/Canonical snippets — per-canal Claude instructions.md"
mcp__mcp-tools-istefox__get_vault_file "99 - Méta/AI/Claude/Claude surfaces and instruction inheritance.md"
```

Capture `Last synced` markers from each per-surface bloc inside the canonical note.

If MCP is unavailable (web/mobile chat without a connector): degrade to paste-driven mode. Ask PA to paste the canonical doc and the live store; do an inline diff.

**Pole 1 ↔ pole 2 alignment** (always run, on every surface that has both):

For each per-surface bloc inside the canonical doc, check it against pole 1:

- Skill list claimed in the bloc matches `plugin.json` + `skills/*/SKILL.md` frontmatter names.
- MCP server floor matches the requirement that the plugin actually depends on (read it from a representative SKILL.md or the README).
- `description:` strings claimed in the bloc match the actual frontmatter descriptions of the listed skills.

Any mismatch → Bucket 4 (canonical-snippets edit), even if pole 3 is not yet read. This is the work a Code-side run can do for *all* surfaces, not just Code.

## Pole 3 — read per-surface implementations (depends on surface × scope)

### Code

| Scope mode | Targets read |
|---|---|
| `--scope=global` (default) | `~/.claude/CLAUDE.md` |
| `--scope=project[=<slug>]` | `<repo>/CLAUDE.md`, `<repo>/CLAUDE.local.md`, `~/.claude/projects/<slug>/memory/MEMORY.md` + every entry it points to |
| `--scope=all` | union of the above for every project under `~/.claude/projects/*/` |

Slug resolution for `--scope=project` (no explicit slug): convert current CWD to the slug form `~/.claude/projects/` uses (e.g. `/Users/pierreandre/Developer/organon-plugin` → `-Users-pierreandre-Developer-organon-plugin`).

Read every memory file listed in `MEMORY.md` plus any `*.md` in the memory dir not yet linked from the index (those are findings on their own — orphan memories — flagged as a structural issue in the report header).

### Cowork

| Scope mode | Targets read |
|---|---|
| `--scope=global` (default) | Cowork → Global instructions — prompt PA to paste, or read directly if a programmatic accessor exists |
| `--scope=project` | current Cowork project: folder instructions + project instructions + project memory (via in-conversation memory tools) |
| `--scope=all` | global + current project |

Cowork has no cross-project reach. `--scope=all` and `--scope=project` only differ from `--scope=global` by adding the current project, never sibling projects.

### Chat (Desktop Chat with MCP, claude.ai web/mobile, claude.ai project)

| Scope mode | Targets read |
|---|---|
| `--scope=global` (default) | Settings → General → Instructions for Claude — paste-based |
| `--scope=project` | current claude.ai project's project instructions (paste-based) + current conversation memory |
| `--scope=all` | global + current project |

For paste-based reads: emit a `<details><summary>Paste request</summary>...</details>` block telling PA exactly what to paste, then continue once they reply.

## Filtering

A memory or instruction line is "in scope" if it hits any keyword from `references/AUDIT_KEYWORDS.md`. Non-organon entries are explicitly skipped — list them once at the end of the report under "Out of scope (not audited)" for transparency. Always read the canonical doc and plugin manifests in full — filtering applies only to memory/instruction *entries*, not to sources of truth.

## Triage — four buckets

For each in-scope finding, classify into exactly one bucket:

### Bucket 0 — Plugin internal drift (gate)

`sync-kepano.sh` or `sync-vault.sh` returned exit 1. Emit one finding per drifted section. Output: routing instruction (`/kepano-resync` for kepano drift; `docs/syncing-vault.md` runbook for vault drift). The audit halts further-pole work until cleared.

### Bucket 1 — Memory edit

Memory asserts a fact (skill name, version, file path, behavioral rule, vocabulary value) that contradicts current plugin state or the canonical vault note. Examples:

- Memory says `mcp-tools-istefox 0.3.12+` but `plugin.json`'s effective floor is `0.4.5+`.
- Memory references `organon-vault-write` heading-patch guidance using a wording that contradicts the current SKILL.md.
- Memory names a file path that no longer exists or has been renamed.

Output: file path, line range, current text, proposed text, `Why:` (citing the authoritative source — file + line range).

### Bucket 2 — Instructions edit (per-surface store)

A per-surface store (`~/.claude/CLAUDE.md`, Cowork → Global, Settings → General, project `CLAUDE.md`, claude.ai project instructions) contradicts (a) plugin truth or (b) the canonical vault note. Examples:

- `~/.claude/CLAUDE.md` lists 7 write-discipline skills but plugin now ships N.
- Cowork → Global references an old MCP server name.
- The Organon block in `~/.claude/CLAUDE.md` has drifted from the canonical bloc.

Output: store name, location (path or "paste-only"), current text, proposed text, `Why:`. For `~/.claude/CLAUDE.md` and project `CLAUDE.md` files, `apply` writes directly. For Settings → General and Cowork stores, `apply` emits the corrected text in a fenced code block for PA to paste — the skill cannot write those.

### Bucket 3 — Plugin-update candidate

A memory (typically a `feedback` or `project` entry) documents a recurring behavioral rule, correction, or pattern *not yet captured* in any organon skill. Memory is the wrong long-term home — a skill rule is more durable.

Output: source memory file, proposed target skill (or "new skill needed"), proposed rule shape, rationale. **Recommendation only** — the audit never edits plugin source. Actual plugin work goes through the normal `/plugin-release` flow on a feature branch.

### Bucket 4 — Canonical-snippets edit

The per-surface store(s) are correct (match plugin reality) but the canonical vault note is stale, or one of its per-surface blocs disagrees with plugin reality. Updating the canonical doc is the fix.

Output: vault path, section, current text, proposed text, `Why:`. `apply` patches via `mcp__mcp-tools-istefox__patch_vault_file` — refer to `organon-vault-write` for the wire-format invariants before applying.

### Decision tie-breakers

- Same fact in **both** a memory and an instruction store, both contradict plugin → emit two findings (one per bucket) so each location gets fixed.
- Memory and instruction store agree but contradict plugin → both stale; one finding per location.
- Memory and instruction store disagree but neither contradicts plugin → flag as "internal inconsistency"; default-classify as Bucket 1 (memory edit), but mention both for PA to choose.
- Memory older than 90 days referencing a version no longer in the changelog → "staleness suspected; verify"; do not auto-classify.
- Pole 1 ↔ pole 2 mismatch with no pole-3 read on this surface → Bucket 4 only, even if PA might also need to update Settings → General manually later (the audit's job is to point at the canonical doc; correcting Settings → General is a separate run on a chat surface).

## Output — report format

Render inline in the conversation (the full skeleton is in `references/REPORT_TEMPLATE.md`). Section structure:

```
# Organon memory & instructions audit — <YYYY-MM-DD HH:MM>

## Run
- Surface: Code | Cowork | Chat (web/mobile/Desktop)
- Scope: global | project=<slug> | all
- Mode: interactive | report-only
- Plugin source: readable at <path> | inferred from harness
- Canonical vault note: read at <vault path> | not reachable (no MCP)

## Sources of truth
- Plugin v<X.Y.Z> @ <git short SHA>
- kepano-sync: <N>/<N> in-sync (or list drifted sections)
- vault-sync: <N>/<N> in-sync (or list drifted entries)
- Canonical snippets last synced: <date from vault note>
- Stable run hash: <sha256 of pole-1 + pole-2 inputs> (lets PA tell at a glance whether anything has changed since the last run)

## Findings

### Bucket 0 — Plugin internal drift (N)
### Bucket 1 — Memory edits (N)
### Bucket 2 — Instructions edits (N)
### Bucket 3 — Plugin-update candidates (N)
### Bucket 4 — Canonical-snippets edits (N)

## Out of scope (not audited)
- N memory entries did not match organon keywords.

## Recommended next step
```

If `0 findings across all buckets`, the report says so in one line and stays compact (one-screen).

In `--mode=interactive`, after the report walk each finding one by one: show the diff and ask `apply / skip / defer`. Direct-write targets execute on `apply`; paste-only targets emit corrected text for PA to copy. In `--mode=report-only`, exit after the report — no prompts, no edits.

## Triage-resume from a previous report

If PA pastes a report from a prior `--mode=report-only` run and asks to walk findings, recognise the format (header line `# Organon memory & instructions audit — `) and resume per-finding triage. Re-validate each finding against current pole-1 + pole-2 state before prompting — between report and resume, plugin state may have moved, so a finding may be stale.

## Scheduling

- **Cowork routines**: configure something like `Run /organon-memory-audit --scope=all --mode=report-only every Monday 09:00`. The routine posts the report; PA opens the conversation when convenient and triages.
- **Code-side schedules**: use the `schedule` skill to fire a remote agent running `/organon-memory-audit --scope=all --mode=report-only` on cadence. Use `loop` for ad-hoc polling rather than persistent schedules.

Hard rules for scheduled runs: `--mode=report-only` enforced; no edits ever; if Bucket 3 candidates surface, the report suggests opening a tracking issue in `folotp/organon-plugin` but does not create one.

Recommended cadence: weekly + ad-hoc after every `/plugin-release`.

## Anti-patterns

- **Editing Settings → General or Cowork → Global directly** — those are paste-only stores. The skill must emit corrected text in a code block, never claim it wrote them.
- **Skipping the integrity gate** (`sync-kepano.sh`, `sync-vault.sh`) — pole-1 inconsistencies cascade into false Bucket 4 findings. Always gate first on Code.
- **Auto-classifying memory older than 90 days** — versions cycle out of the changelog quickly; treat as "verify, not auto-fix".
- **Bundling Bucket 3 (plugin-update candidates) with Bucket 1 (memory edits) in the same triage walk and applying them together** — Bucket 3 is recommendation only, never executed by this skill.
- **Running `--mode=interactive` from a scheduled context** — there's no PA in the loop; the prompts will hang or apply default-skip silently. Scheduled = report-only, always.

## Files

- `references/AUDIT_KEYWORDS.md` — the keyword set used to filter in-scope memory/instruction lines.
- `references/REPORT_TEMPLATE.md` — the full report skeleton.
- `kepano-sync.json`, `vault-sync.json` (repo root) — drift ledgers; run `sync-kepano.sh` and `sync-vault.sh` against these as the integrity gate.
- `99 - Méta/AI/Claude/Canonical snippets — per-canal Claude instructions.md` (vault) — pole 2 source of truth.
- `99 - Méta/AI/Claude/Claude surfaces and instruction inheritance.md` (vault) — companion matrix.
