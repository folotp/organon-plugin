# Plan — Fix open issues (#44, #43) + telemetry-driven skill refactor

> **Resumability note.** Self-contained; a fresh session can execute without the originating conversation. **Task 0** persists this file into the repo so it survives context loss.

## Context

`folotp/organon-plugin` is the source repo for the **organon** plugin (skills shipped via a `.plugin` GitHub Release asset, consumed by `folotp/claude-marketplace`). Two open issues + a telemetry review motivate a skill refactor:

- **#44 (bug)** — `organon-vault-write` allegedly miscategorises VLT-BL / VLT-BUG as static templates, forcing manual ULID + ID discovery (≈5 wasted tool calls/artifact).
- **#43 (refactor)** — adopt new "vault intelligence" tools from `istefox/obsidian-mcp-connector` v0.8.0.
- **Telemetry** at `…/Organon/99 - Méta/AI/Telemetry/sessions.ndjson` (6 sessions) surfaces recurring MCP-write errors the skills should pre-empt.

### Root-cause finding that reframes #44 (verified in the vault)

The vault has **two parallel template sets**:

- **Legacy static instruction gabarits**: `VLT-BL-template.md`, `VLT-BUG-template.md`, `VLT-INC-template.md` — plain Markdown with `## Frontmatter à reproduire` fences and a bash ULID one-liner. **No Templater blocks.**
- **Active generic dual-mode templates**: `BL-template.md`, `BUG-template.md`, `INC-template.md`, **and `ADR-template.md`** — all open with `<%*`, detect MCP via `tp.mcpTools`, are **domain-parameterised** (`domain` arg; default `"VLT"` in MCP mode), resolve `cfg = tp.user.domain(domain)` for folder + id-digits, and inject IDs server-side via `tp.user.next_id(tp, cfg.<x>_folder, domain+"-BL", cfg.<x>_id_digits)` + `tp.user.ulid()`. They emit Linter-ordered frontmatter **and the full body skeleton** (BL: `## Objet … ## Liens`).

The skill's "Static gabarits — two-step" table routes VLT-BL/BUG/INC (and SD-BL, VLT-ADR/SD-ADR) to the **legacy static files**, so it forces the manual ULID + `list_vault_files` max-id dance. **The fix is to re-point routing to the active generic templates with `domain:"VLT"` — no template authoring needed.** The legacy `VLT-*-template.md` files are stale duplicates.

**PA decision on Q2 (do we need a VLT-specific active set?): No.** Reuse the existing active generic `BL/BUG/INC` (and `ADR`) templates via the `domain` arg. Flag the legacy static `VLT-*-template.md` for deprecation.

### `execute_template` mechanics (verified from tool schema)

- `arguments`: optional `{string: string}` map, forwarded to the template via `tp.user.mcpTools.prompt(argName)`.
- `createFile`: **string** `"true"` / `"false"` (NOT boolean — the skill currently shows boolean `true`; fix).
- `targetPath`: vault-relative; omit + `createFile` unset → returns rendered string for inspection.

## Locked decisions (PA)

1. **#44** — Re-point `organon-vault-write` routing to the active generic templates (`BL/BUG/INC-template.md`, `domain:"VLT"`), collapse the stale static-gabarits table. Verify ADR routing too (it's active). Flag legacy `VLT-*-template.md` for deprecation. **No new template authoring.**
2. **#43** — High-value tools only: `search_and_replace`, `find_broken_links`, `find_orphaned_notes`. Skip `get_note_outline` (overlaps `mode=outline`) and `list_bookmarks` (niche).
3. **Vault-side edits** — make directly in Organon via MCP.
4. **PR** — one bundled PR, branch `feat/issues-44-43-telemetry`. No `Co-Authored-By`/Claude attribution; never commit to `main`.
5. **B3** (`~/.claude/CLAUDE.md` skill-count fix) — **PA does manually.** Out of executor scope.
6. **Part C** — also update the relevant **VLT-BUG-xxxx** (and VLT-INC) vault notes; confirm the VLT-BUG↔GitHub-issue mapping with PA before writing (session-discipline Rule 4).

## v0.8.0 tool facts (PR #179, ADR-0004)

- `search_and_replace` — regex find/replace, vault-wide or scoped. **`dry_run:"true"` is the default safety gate** (pass `"false"` to apply). `g` flag always injected. ReDoS guard. (Telemetry S3 already used it — undocumented in the skill.)
- `find_broken_links` — vault-wide broken-link scan (wiki/embed/frontmatter); per link: source path, 1-based line, type, syntax.
- `find_orphaned_notes` — zero-incoming-link notes; `exclude_folders` filters output only.

All three already present in the live deferred-tool list (MCP 0.8.0 installed).

## Telemetry findings → routing

| # | Symptom (session) | Fix | Home |
|---|---|---|---|
| T1 | `patch_vault_file` rejected: *"operation must be 'append','prepend' or 'replace' (was missing)"* (S3) | Mark `operation` **REQUIRED, no default** in tool table + footgun | `organon-vault-write` |
| T2 | *"Heading is level-4 with no H1 parent — allowRootHeadings:true required"* (S3) | Clarify `allowRootHeadings:true` must be **passed explicitly** for H2-rooted notes; add wire example | `organon-vault-write` §Heading-patch safety |
| T3 | `mcp__mcp-tools-istefox__bash` — *"No such tool available"* (S3) | Footgun: mcp-tools-istefox has **no bash**; shell via Code `Bash` / Cowork `mcp__workspace__bash` | `organon-vault-write` §Footguns |
| T4 | `get_vault_file` *timed out* / *server unavailable* (S4) | Name timeout/unavailable as "abnormal signal" → **retry once** before escalating | `organon-vault-write` §Footguns |
| T5 | pytest `tmp_path` **RecursionError on MCP-mounted fs cleanup** (S4) | Discipline: test-framework temp dirs must not target the vault mount; use OS temp outside it | `organon-session-discipline` |

Non-skill / generic (no action): `TaskCreate unexpected parameter status`, `Edit string-not-found`, missing-file reads.

## Drift finding (vault, via MCP)

Canonical snippets note + live `~/.claude/CLAUDE.md` say **"7 auto-loaded skills"**. Now **8** (description-triggered: bases, canvas, diagramming, frontmatter, markdown-style, session-discipline, **vault-read**, vault-write — vault-read added in #41). Fix to 8.

## Question 1 — telemetry plugin-version capture (recommendation)

session-telemetry SCHEMA records `plugins` as **names only** (no version) and `mcp.versions` as `"unknown"`. There is no way today to distinguish pre/post-change organon runs by version. Two paths:

- **Interim (zero-code):** the skill changes warrant an organon release (version bump in `.claude-plugin/plugin.json`). Until telemetry captures versions, use **`ts` ≥ release date** as the pre/post cutover.
- **Proper (follow-up, separate repo):** enhance the session-telemetry plugin (`folotp-marketplace/plugins/session-telemetry`, SCHEMA `v:1`) to record per-plugin versions — resolvable from the plugin cache path which encodes the version (e.g. `…/cache/folotp-marketplace/session-telemetry/0.1.0/…`, `…/organon/<version>/…`). Bump SCHEMA to `v:2`, add a `plugin_versions` object (mirror the `mcp.versions` shape). **File this as a new issue in the marketplace repo — out of organon-plugin scope; do not bundle into this PR.**

---

## Work breakdown

### Task 0 — Persist plan + branch
Write this file to `docs/plans/2026-05-31-issues-44-43-telemetry.md` (`docs/` is not in the `.plugin` archive). `git checkout -b feat/issues-44-43-telemetry`.

### Part A — Repo skill edits (committable, one PR)

**A1. `skills/organon-vault-write/SKILL.md` (primary — design-sensitive).**
- **#44 routing rewrite:** Collapse the "Static gabarits — two-step" table (lines ~63–79). Route BL/BUG/INC/ADR shapes to the **active generic templates** in the one-step table:
  - VLT-BL / SD-BL → `99 - Méta/Templates/BL-template.md`
  - VLT-BUG → `…/BUG-template.md`
  - VLT-INC → `…/INC-template.md`
  - VLT-ADR / SD-ADR → `…/ADR-template.md` (verify active; it is)
  Document the call shape: `execute_template{ templatePath, targetPath:"<cfg folder>/<id>.md", createFile:"true", arguments:{ domain:"VLT", titre:"<summary, no code>", priority/severity/…, id:"" (empty → auto), … } }`. State that `domain` defaults to `"VLT"` in MCP, `tp.user.next_id` resolves the sequential ID **server-side** (no `list_vault_files`), `tp.user.ulid()` injects the ULID — directly answering #44's open question. List required vs optional args per shape (BL: `titre` required, `priority` default medium, `origin` default misc, conditional `linked_bug`; BUG: `titre` required, `severity` default minor, optional `component`/`first_incident`/`last_occurrence`; INC: `titre`,`surface`,`layer`,`tool`,`operation` required).
  - **Keep the BUG post-create side-effect** as an explicit manual step: each linked incident still needs `bug:` + `status: assigned` (Templater can't mutate siblings).
  - **Fix `createFile` to the string `"true"`** everywhere in the skill (currently boolean) and document the `arguments` map (`tp.user.mcpTools.prompt`).
- **#43:** Add `search_and_replace` to the MCP write-tool table + usage block (`dry_run:"true"` default → pass `"false"` to apply; `g` always on; ReDoS guard; scope via paths). Retire "read full body + manual regex + patch" as an anti-pattern in favour of scoped `search_and_replace`.
- **T1:** `patch_vault_file` row + footgun — `operation` is REQUIRED, no default.
- **T2:** §Heading-patch safety — H2-rooted (H1-free) notes require `allowRootHeadings:true` **passed explicitly**; add JSON wire example; drop "automatic acceptance" wording.
- **T3, T4:** §Footguns — (a) no bash on mcp-tools-istefox (Code `Bash` / Cowork `mcp__workspace__bash`); (b) timeout/"server unavailable" → retry once, then escalate.
- Header version line (~line 10): reflect 0.8.0 tools.

**A2. `skills/organon-vault-read/SKILL.md` (#43).**
New **"Integrity / graph-health scans"** subsection after the decision tree (vault-wide scans, not per-target reads): `find_broken_links` and `find_orphaned_notes` (note `exclude_folders` filters output only). Cheaper than ad-hoc `get_outgoing_links` loops for whole-vault health.

**A3. `skills/organon-memory-audit/SKILL.md` (#43, light touch).**
Read first; where it covers vault link-health in the drift audit, reference `find_broken_links` / `find_orphaned_notes` as the canonical mechanism. Minimal.

**A4. `skills/organon-session-discipline/SKILL.md` (T5).**
Brief discipline note: test-framework temp dirs (pytest `tmp_path`) must not target the MCP-mounted vault path — cleanup recurses → `RecursionError`. Use OS temp outside the mount.

**A5. Verify token cost + links.**
- `python3 scripts/token-harness.py --no-write`; compare to `eval-workspace/iteration-5/harness-output.json`; keep within ~5% (the routing rewrite should *reduce* vault-write tokens — net likely neutral/positive).
- `markdown-link-validator` over `skills/`.

### Part B — Vault edits via MCP (PA's Organon; not committed)

**B1. Legacy static templates — deprecate.** `VLT-BL-template.md`, `VLT-BUG-template.md`, `VLT-INC-template.md` are stale duplicates of the active generic ones. Recommend: confirm no live references, then either move to an archive folder or delete via `delete_vault_file`. **PA confirms before deletion** (irreversible-ish; link-safety). No authoring of new templates.

**B2. Canonical snippets note — edit via MCP.** `…/99 - Méta/AI/Claude/Canonical snippets — per-canal Claude instructions.md`:
- Fix **"7 auto-loaded skills" → "8"** in the Settings → Cowork → Global bloc and the `~/.claude/CLAUDE.md` bloc.
- Add an early-skill-load cue to `<organon>` (telemetry: heavy vault sessions ran without invoking `organon-vault-write` until late) — terse, best-effort.
- Update §Last synced + append a §Journal entry dated 2026-05-31. Full-file rewrite if any heading patch would cross fenced-code `##` boundaries (documented pitfall); else atomic edits.

**B3.** *(PA does this manually — live `~/.claude/CLAUDE.md` skill-count fix.)* Not in executor scope.

**B4. AI Bootstrap** — no change (lean topology; no tool/skill section).

### Part C — Close issues + update vault bug notes
1. After PR merges, close **#44** (comment: root cause was routing to legacy static template files; resolved by re-pointing to the active generic domain-parameterised templates — no manual ULID/ID needed) and **#43** (adopted `search_and_replace` + `find_broken_links` + `find_orphaned_notes`; `get_note_outline`/`list_bookmarks` skipped). Reference the PR.
2. **Update relevant VLT-BUG / VLT-INC notes** (PA Q5): search `…/Accès à Obsidian par Claude/{Bugs,Incidents}/` for notes tracking the vault-write routing miscategorisation (#44) and the telemetry errors (T1 patch-operation, T2 allowRootHeadings, T3 bash-tool, T4 MCP-timeout, T5 pytest-recursion). **State the inferred VLT-BUG↔GitHub-issue / VLT-INC↔error mapping and confirm with PA before writing** (Rule 4). Then update lifecycle `status` + append journal entries (→ `fix-deployed`/`verified`) cross-referencing the PR and GitHub issue. If no VLT-BUG exists for #44, propose creating one (via the now-active `BUG-template.md`, `domain:"VLT"`) or recording the resolution in the methodology note — confirm with PA. Known candidates to check: `VLT-BUG-0022` (heading fenced-code, status `fix-requested`), `VLT-BUG-020/021` (patch frontmatter, closed).

---

## Model & thinking-level recommendation (PA Q3)

| Part | Model | Thinking | Why |
|---|---|---|---|
| A1 (routing rewrite + arg/wire docs) | **Opus** | **high** | Table redesign + precise tool-mechanics docs; correctness-critical. |
| A2–A4 (vault-read/memory-audit/session-discipline edits) | Sonnet | medium | Bounded prose additions guided by this plan. |
| A5 (harness + link validation) | Haiku/Sonnet | low | Run commands, compare numbers. |
| B1 (deprecate legacy templates) | Sonnet | medium | Reference check + confirm-before-delete. |
| B2 (canonical snippets edit) | Sonnet | medium | Count fix + journal; heading-patch pitfall awareness. |
| C (issue close + VLT-BUG/INC updates + mapping) | **Opus/Sonnet** | high | Lifecycle judgment + Rule-4 mapping confirmation. |
| Telemetry follow-up issue (marketplace repo) | Sonnet | low | Draft issue from the Q1 recommendation. |

Default driver: Sonnet 4.6 at medium; escalate to Opus + high for A1 and C.

## Verification

**Repo skills:** harness `--no-write` clean, no >5% regression vs iteration-5; `markdown-link-validator` clean; routing tables internally consistent (no shape in both tables).

**Templates (MCP sandbox):** `execute_template{ templatePath:"99 - Méta/Templates/BL-template.md", arguments:{domain:"VLT", titre:"test"} }` (no `createFile`) → inspect render: ULID present, `id:` = next sequential, `creator: Claude`, `source/ia`, full body skeleton. Then `createFile:"true"` into `00 - Boîte de réception/_tmp-tpl-test/<id>.md`, read back frontmatter, confirm no `next_id` collision, `delete_vault_file` the artifact. Repeat for BUG/INC/ADR.

**search_and_replace:** dry-run on a scoped path returns match preview without mutation (confirms `dry_run:"true"` default).

**find_broken_links / find_orphaned_notes:** one vault-wide invocation each; sanity-check output shape vs PR #179.

## Risks & notes
- The #44 fix is now **doc-only routing change + optional legacy-template cleanup** — far lower risk than authoring new Templater (the original mistaken framing). No `<%* %>` authoring.
- `createFile` is a **string** in `execute_template`; passing boolean `true` is a latent bug — fix in the skill.
- Vault edits need mcp-tools-istefox ≥ 0.8.0 live; on timeout/unavailable retry once (the very guidance being added), then surface to PA.
- B1 deletion is link-affecting — confirm no references before removing legacy templates.
- Part C writes to bug-tracking notes — confirm mappings with PA (Rule 4) before editing.

## File reference index
- Repo skills: `skills/organon-vault-write/SKILL.md`, `skills/organon-vault-read/SKILL.md`, `skills/organon-memory-audit/SKILL.md`, `skills/organon-session-discipline/SKILL.md`. Harness: `scripts/token-harness.py`; baseline `eval-workspace/iteration-5/`.
- Vault active templates (reuse): `…/Organon/99 - Méta/Templates/{BL,BUG,INC,ADR}-template.md`; helpers `…/Templates/scripts/{ulid.js,next_id.js,domain.js,vocab.js,arg.js,topic.js}`. Legacy to deprecate: `…/Templates/{VLT-BL,VLT-BUG,VLT-INC}-template.md`.
- Vault instructions: `…/Organon/99 - Méta/AI/Claude/Canonical snippets — per-canal Claude instructions.md`.
- Vault bug/incident notes: `…/Organon/99 - Méta/Outils/Accès à Obsidian par Claude/{Bugs,Incidents}/`.
- session-telemetry (Q1 follow-up, separate repo): `…/folotp-marketplace/plugins/session-telemetry/skills/session-telemetry/SCHEMA.md`.
- Issues: `gh issue view 44 --repo folotp/organon-plugin`, `gh issue view 43 …`.
