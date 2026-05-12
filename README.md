# organon

Organon vault conventions for Claude — packaged as a Cowork/Claude Code plugin.

## What this plugin provides

Nine skills total: seven description-triggered (load automatically when working with the Organon Obsidian vault at `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon`) plus two user-only skills invoked via slash command.

### Core (4 skills, validated in chat 1.A)

- **organon-vault-write** — MCP write discipline via `mcp-tools-istefox` 0.4.5+. Covers Templater-first routing for structured notes (two-step render-then-create / one-step render-and-create via `execute_template`), YAML scalar quoting, frontmatter array vs scalar semantics, `tags:` array shape, heading patch safety, NFC normalization, footguns.
- **organon-frontmatter** — Schema, key ordering, controlled vocabularies, ULID forward-only, `creator:` dual-mode (UI vs MCP), archive/supersession, alias-only versioning, ADR/BL/BUG/INC field requirements. Vocabularies externalized to `references/VOCABULARIES.md` (loaded on-demand).
- **organon-markdown-style** — Body conventions: no H1 in body, language by folder (`99 - Méta/AI/` in EN, rest in FR), typographic apostrophes, no trailing whitespace, no systematic block anchors, table+block-ref pitfall.
- **organon-session-discipline** — 7 behavioral rules: arbitrate over over-clarify, read bootstrap before drafting, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills before producing typed artifacts, language coherence by folder.

### Aux (3 skills, new in v0.2.0 — chat 1.B)

- **organon-bases** — Bases-default policy (Dataview is fallback only with explicit auth, even against directive prompts), Excluded-files trap diagnostic, dv-light optimised config, Organon vocabulary filters.
- **organon-canvas** — Purpose discriminator (cartography of existing notes vs. freeform sketches), placement beside the domain, file-node filename-only paths for vault-move robustness, language by folder for labels, ID convention (kepano 16-char hex).
- **organon-diagramming** — Tool-selection decision tree (Mermaid for code-expressible flows, Canvas for note-cartography, Excalidraw via connector+bridge for freeform, SVG for throwaways), Excalidraw bridge skeleton, plugin compression-OFF invariant, preview-before-persist pattern.

### User-only (2 skills, invoked via slash command — `disable-model-invocation: true`)

- **plugin-release** (`/plugin-release`, since v0.4.1) — Cut releases: bump version in `plugin.json`, package the `.plugin` archive, tag, create the GitHub Release with the archive uploaded as a Release asset.
- **organon-memory-audit** (`/organon-memory-audit`, since v0.5.0) — Three-pole drift audit aligning plugin/skill/tool reality, the canonical-snippets vault note, and per-surface implementations (Code / Cowork / Chat). Two scope modes (`--scope=global|project|all`) and two interaction modes (`--mode=interactive|report-only`). Edits never auto-applied — drifts and staleness are raised for human-in-the-loop approval.

## Absorbed kepano content — version-pin model (since v1.0.0)

This plugin carries 9 references absorbed verbatim from [kepano `obsidian-skills`](https://github.com/kepano/obsidian-skills) for generic Obsidian syntax. One upstream sha is pinned in `kepano-version.txt`; the absorbed bytes are guaranteed to match upstream at that sha. Check: `./scripts/kepano-check-upstream.sh` (compares pin vs upstream HEAD). Refresh runbook: [`docs/refreshing-kepano.md`](docs/refreshing-kepano.md).

The pre-v1.0.0 design used per-section `body_sha256` fingerprints in `kepano-sync.json` plus a bidirectional drift detector + a `/kepano-resync` runbook. The version-pin model is ~95% cheaper to maintain (1 line vs a 9-section ledger; 65-LoC check script vs 317 LoC) at the cost of less granular drift reporting — for casual refresh cadence, the tradeoff is right-sized.

## Organon-owned reference content (was: absorbed vault content, retired v1.0.0)

`organon-frontmatter/references/` carries the canonical frontmatter key registry (`REGISTRE_KEYS.md`), ID prefix registry (`PREFIXES.md`), 12 controlled vocabularies (sectioned inside `VOCABULARIES.md`), and the methodology references (`METHODOLOGY_ADR.md`, `METHODOLOGY_INC_BUG_BL.md`). The plugin is now the **canonical home** for this content — edit it here directly. (Prior to v1.0.0 these files were absorbed verbatim from PA's local Organon vault with bidirectional drift tracking; the bidirectional contract was retired because the vault is PA's own, not a third-party upstream.)

Net effect: when `organon-frontmatter` triggers (drafting an ADR / VLT-BUG / FIN-DEC), the schema, vocab, and methodology are already in `references/` — no MCP round-trip to the vault needed.

## Empirical validation

- **Chat 1.A — 4 core skills** : 3 iterations of skill-creator eval workflow. iter-3 final pass-rate **94 %** with_skill vs 82 % baseline (delta +12 pp).
- **Chat 1.B — 3 aux skills + B1 fix** : 2 iterations. iter-2 final pass-rate **98 %** with_skill (54/55) vs 78 % baseline (43/55) — delta **+20 pp**, 0 regressions, 11 with_skill-only wins.
- Detailed results in `refactor-phase4/wave-1-skills-bootstrap/eval-workspace/` of the Organon project workspace.

## Changes since v0.1.0

### v0.6.2 (sub-agent cost optimisation)

- **Mechanical user-only skills now delegate to sonnet-pinned executor sub-agents instead of running inline on the main session.** The four `disable-model-invocation: true` skills with mechanical, deterministic runbooks (`plugin-release`, `kepano-resync`, `vault-resync`, `organon-memory-audit`) become thin shims that dispatch to a dedicated executor agent as their first and only action. The runbook bodies (~100–270 lines each) move from `SKILL.md` to `.claude/agents/<name>.md` verbatim — the cost reduction is the model swap, not a content rewrite. Frontmatter `name:` / `description:` / `disable-model-invocation: true` on the source skills is preserved byte-for-byte so trigger discovery, picker presence, and the slash-command wrappers continue to behave identically.
- **Four new executor agents under `.claude/agents/`** (all `model: sonnet`, dev-time only, not advertised in description-triggered discovery):
  - `plugin-release-executor` — post-pre-flight ship sequence (version bump, archive, tag, push, GitHub release).
  - `kepano-resync-orchestrator` — full kepano re-sync runbook; fans out to `kepano-drift-resolver` per drifted section; owns the `.organon-resync-token` lifecycle.
  - `vault-resync-orchestrator` — full vault re-sync runbook; owns the resync-token lifecycle for vault-absorbed paths.
  - `memory-audit-executor` — read-only three-pole audit; emits structured four-bucket findings.
- **Six existing agents now have explicit `model:` pins** — read-only auditors (`markdown-link-validator`, `readme-inventory-checker`, `release-readiness`, `token-harness-regression`) on `haiku`; editors/orchestrators (`kepano-drift-resolver`, `changelog-synthesizer`) on `sonnet`. Replaces the previous implicit "inherit from parent" default that billed at the parent session's model (typically opus).
- **New PreToolUse routing hook** `scripts/hooks/enforce-skill-delegation.sh` (registered in `.claude/settings.json`, matcher `"Skill"`, timeout 5 s). When one of the four delegation-mandatory skills fires, emits a stdout reinforcement block naming the executor + agent file path so the model's next turn sees an explicit routing directive, plus a stderr audit line. Never blocks (exit 0) — hard-blocking the Skill tool would break the shim flow itself, since the shim still dispatches the executor via the Agent tool from inside the Skill turn. The hook is a third reinforcement on top of the shim's BLOCKING REQUIREMENT paragraph and the skill's `disable-model-invocation: true` frontmatter.
- **Behavioural impact for end-users: none.** Same 11 skills, same 4 commands, same surface. The delegation is internal — visible only in `/agents` and in the per-skill billing trace. Trigger keywords, absorbed-content shas, and runbook semantics all unchanged.
- Breaking: no — internal cost-optimisation refactor with no user-facing surface change.

### v0.6.1 (resync flow hardening + automation tooling)

- **Resync flow now works end-to-end without bypass tricks.** A new `.organon-resync-token` file (gitignored, audit-logged via stderr) lets the model edit absorbed-content `target_file` paths under the supervision of the existing PreToolUse `block-absorbed-edits.sh` hook. Pre-commit refuses to commit while the token exists — silent leakage is impossible. Both `kepano-resync` and `vault-resync` skills, plus the `kepano-drift-resolver` subagent, document the lifecycle.
- **Bilateral drift verification.** `sync-kepano.sh` and `sync-vault.sh` now hash BOTH the source-side chain (vault/upstream extract → stored sha) AND the target-side chain (plugin target body inside `<!-- *-* -->` markers → stored sha). New statuses `target-corrupt`, `target-marker-missing`, `target-file-missing` surface when a hand-edit slipped past the hook. JSON output gains `detected_target_sha256` + `detected_target_status`.
- **New `vault-resync` skill (`/vault-resync`)** — end-to-end runbook mirroring `kepano-resync` for vault-side absorption. User-only.
- **CI: marketplace dispatch on release.** New `.github/workflows/notify-marketplace.yml` fires `repository_dispatch` at `folotp/claude-marketplace` on every `release: published`, triggering its `auto-bump-external-plugins` workflow within ~30 s instead of the up-to-30-min cron.
- **Local tooling.**
  - `scripts/hooks/install-git-hooks.sh` installs a managed `.git/hooks/pre-commit` that runs both drift detectors and refuses on token presence. Closes the asymmetry between Claude's PreToolUse hook (in-session edits only) and direct commits from other editors.
  - `scripts/hooks/stop-shellcheck.sh` is a Stop hook that lints modified `scripts/**/*.sh` at session end. Works on macOS default bash 3.2 (no `mapfile` dependency).
  - Two new subagents under `.claude/agents/` (dev-time only, not shipped in the plugin runtime): `readme-inventory-checker` (read-only consistency check between `README.md` and source-of-truth files) and `token-harness-regression` (PR-time harness diff against latest committed iteration).
- **Vault re-sync.** `domain` vocabulary FIN row updated to reflect the 2026-05-08 FIN-BL Templater dual-mode rollout.
- **Cleanup.** Shellcheck SC2034 + SC2295 findings silenced across all 7 bash scripts. `MARKDOWN_SYNTAX.md` had a stray extra blank line in its marker layout (caught by the new bilateral verifier; corrected).
- Breaking: no — additive infrastructure. Existing skill descriptions, trigger keywords, and absorbed content shas stable.

### v0.6.0 (perf trim — token-efficiency pass)
- **Core SKILL.md trim** (~−21.5 % across the 7 skills): bulky tables, skeletons, and verbose example blocks moved out of the always-loaded core into lazy-loaded `references/`. Net effect on the harness: `post_tokens_total` 67 257 → 61 080 (−9.2 %), `mean(ratio)` 1.464 → 1.509. Real-world per-session load drops 600–1700 tokens depending on how many skills trigger.
- **Five new `references/` files** (lazy-loaded only when the task genuinely needs them):
  - `organon-frontmatter/references/SHAPES_QUICKREF.md` — required-fields-by-shape (ADR/BL/BUG/INC/Person/Book/Quote/new ID).
  - `organon-canvas/references/LABEL_TRANSLATIONS.md` — EN↔FR translation table for canvas labels (most-missed rule when drafting in EN chat for an FR-folder canvas).
  - `organon-diagramming/references/MERMAID_SYNTAX.md` — kepano-absorbed Mermaid syntax (was inline in SKILL.md; `kepano-sync.json` `target_file` updated, `body_sha256` unchanged).
  - `organon-diagramming/references/EXCALIDRAW_SKELETON.md` — verbatim `.excalidraw.md` file structure for the connector→bridge persist step.
  - `organon-session-discipline/references/BOOTSTRAP_CACHE.md` — sha256-manifest cache protocol from rule 2.
- **Cross-skill de-duplication**: the "language by folder" rule is now canonical in `organon-markdown-style` §Langue par dossier. `organon-frontmatter` and `organon-session-discipline` cross-ref instead of duplicating the rule.
- **Tightened skill descriptions** (~400 chars each, down from ~700–850): dropped the `Use this skill EVERY TIME … is the recurring failure mode` boilerplate, simplified path discriminator from `iCloud~md~obsidian/Documents/Organon` to `Organon`. Discriminator keywords retained on all 7 skills.
- **Token harness extended**: `scripts/token-harness.py` SESSIONS list updated so deep sessions correctly mark the new lazy refs as needed (S02, S06, S07). Methodology unchanged (cf. `docs/token-harness-methodology.md`).
- Breaking: no — additive. Existing trigger keywords retained ; absorbed content paths/sha256 stable. Description path-pattern broadening is permissive (no false negatives expected).

### v0.2.0 (chat 1.B initial)
- Added 3 aux skills : `organon-bases`, `organon-canvas`, `organon-diagramming`.
- Fixed B1 : `organon-session-discipline` description bumped from "6 behavioral rules" to "7" (the iter-3 « language coherence » rule was added without the description being updated).

### v0.2.1 (chat 1.B feedback patch)
- `organon-canvas` : explicit ID convention (kepano 16-char hex via cascade) + anti-pattern note on semantic IDs.
- `organon-diagramming` : preview-in-chat-before-persist pattern made explicit on the Excalidraw bridge.

### v0.2.2 (closure Phase 5)
- `organon-frontmatter` : Touch-on-edit refined (≤ 3 keys/edit threshold, canonical journal entry, explicit skip if edit > 10 lines).

### v0.3.0 (P7.1 — session-discipline cache)
- `organon-session-discipline` rule #2 made cache-aware: sha256 manifest + cached AI Bootstrap snapshot in project memory space, ~300 tok saved per cache hit.

### v0.4.0 (VLT-BL-0063 — kepano absorption B4-complet)
- Absorbed verbatim kepano `obsidian-skills` content (commit `fa1e131`) into 5 organon skills via HTML provenance markers and per-skill `references/` files.
- Added `kepano-sync.json` (drift fingerprints), `scripts/sync-kepano.sh` (drift detection — read-only), `docs/syncing-kepano.md` (re-sync runbook).
- Removed runtime cascade to kepano plugin — eliminates the additive cascade load (~1.1k–3.4k tokens saved per session depending on task shape).
- Regression eval: 50/51 (98 %) on representative tasks, matching chat 1.B baseline.

### v0.4.1 (automation runbooks)
- New user-only skills `kepano-resync` and `plugin-release` (both `disable-model-invocation: true`) — end-to-end runbooks for drift resolution and release cuts.

### v0.4.2 (slash-command wrappers)
- New `/kepano-resync` and `/plugin-release` thin slash-command wrappers — make the v0.4.1 runbooks reachable from the picker. No skill content changes.

### v0.4.3 (istefox 0.4.0–0.4.5 alignment)
- Min `mcp-tools-istefox` floor bumped 0.3.12+ → 0.4.5+ (in-process MCP, auto-mkdirp, fail-loud rejects for upstream #80/#81/#84). Min Obsidian: 1.7.2 (transitive).
- **Renamed "Voie B routing" → "Templater-first routing"** across SKILL/README/docs/token-harness — the design-era label was meaningless to readers; the new name describes what the routing actually does. Variants relabeled: "Two-step render-then-create" (BL/BUG/INC/ADR sequential IDs) and "One-step render-and-create" (Note/Concept/Person/etc. — domain-folder-mapped).
- `organon-vault-write` — heading-patch safety **rewritten** based on smoke-test ground truth on istefox 0.4.5: `createTargetIfMissing: false` is **incompatible with Organon's H2-root convention** (triggers istefox 0.4.2 #80 reject on every heading patch since every Organon note is H2-root by design); default `true` silently appends to EOF on missing target. Correct discipline: pre-verify the heading exists with `get_vault_file` before patching. The previous skill text recommending `false` is reversed.
- `organon-vault-write` — also documents 0.4.0 frontmatter array semantics (`replace`-with-scalar on array fields now errors; `append`/`prepend` JSON-decode + auto-wrap), notes 0.4.5 auto-mkdirp on `create_vault_file`/`append_to_vault_file`/`execute_template`, refreshes block-target rejects (0.4.2 #81 table-cell, 0.4.3 #84 fenced-code).
- `organon-markdown-style` — VLT-BUG-015 reframed: table+block-ref + fenced-code-boundary cases are now structural fail-loud rejects (not HTTP 400 footguns), workaround language updated.
- `organon-session-discipline` — rule #2 cache-example refreshed `v0.3.12` → `v0.4.5` to match the new floor.
- Breaking: yes (version pin bumped + heading-patch discipline reversed; callers passing `createTargetIfMissing: false` to Organon notes will now see fail-loud rejects).

### v0.5.0 (vault absorption)
- **Tier 1 — Verbatim absorption with drift tracking** under `skills/organon-frontmatter/references/`:
  - `REGISTRE_KEYS.md` ← full body of vault `[[Registre des clés de frontmatter]]` (~400 lines: global keys, per-type tables, per-domain tables, Tri Linter canonique, retired/in-migration keys).
  - `PREFIXES.md` ← full body of vault `[[Préfixes d'identifiants]]` (FIN/VLT/SD/SPA + reserved + sub-types + protocols).
  - `VOCABULARIES.md` refactored: Organon-curated framing prose for `type`/`status`/`content-model` (cross-linking to `REGISTRE_KEYS.md`) + 12 absorbed sections wrapping verbatim `## Valeurs` tables from each vault `Vocabulaire — <key>.md` (markers + per-section drift tracking).
- **Tier 2 — Distilled Claude-actionable references** (no drift markers; provenance banner only — re-derive manually after material methodology changes):
  - `METHODOLOGY_ADR.md` (~150 lines from vault's 206 — lifecycle, immutability, supersession, callout, anti-patterns).
  - `METHODOLOGY_INC_BUG_BL.md` (~140 lines from vault's 152 — atomic types, Phase A/B/C, promotion criteria, MCP write discipline).
- **Drift machinery** paralleling kepano: new `vault-sync.json` (14 entries), `scripts/sync-vault.sh` (live-FS read with `mktemp` atomic snapshot, parallel exit-code contract), `docs/syncing-vault.md`. Both `vault-sync` and `kepano-sync` mechanisms remain independent.
- **`organon-frontmatter/SKILL.md`** updated: references list expanded with cascade triggers ("read METHODOLOGY_ADR.md when drafting an ADR or transitioning its `status:`", etc.). Inline `type:` enum corrected from 9 values to 16 (post-FIN-BL-0107 promotion 2026-05-05). Supersession discipline rewritten to permit ADR/FIN-DEC `supersedes:` frontmatter and reference the `[!warning] Superseded` callout. `amends:` / `amended-by:` flagged as deprecated (SD-ADR-011).
- **New skill `organon-memory-audit`** (PR #7) — three-pole drift audit aligning plugin/skill/tool reality, canonical-snippets vault note, and per-surface implementations. Surface-aware (Code / Cowork / Chat), two scope modes, two interaction modes, edits never auto-applied. Invoked via `/organon-memory-audit`. Adds a third user-only skill alongside `kepano-resync` and `plugin-release`.
- **Hook hardening** (PRs #6, #8, post-Codex review):
  - `scripts/sync-vault.sh` and `scripts/sync-kepano.sh` — fixed `sha256sum`/`shasum` fallback that was unreachable on macOS without coreutils (`require_tool` exit-2 short-circuit before the fallback).
  - `scripts/hooks/block-absorbed-edits.sh` — extended to also scan `vault-sync.json` (previously only blocked kepano-absorbed files; vault-absorbed `REGISTRE_KEYS.md` / `PREFIXES.md` / `VOCABULARIES.md` were unprotected). Added leading-`./` path canonicalization (also fixed pre-existing kepano blind spot).
  - `scripts/hooks/validate-sync-json.sh` — fixed `if ! cmd; rc=$?` pattern that always read `$?` as the negation's exit code (always 0); informational drift exit 1 from `sync-kepano.sh` no longer falsely escalates to a validation block.
  - `organon-memory-audit/SKILL.md` — surface-detection probe and `PLUGIN_ROOT` default switched from hard-coded `/Users/pierreandre/...` to `~` / `$HOME` (portable to remote Code agents and other macOS users). Integrity gate dropped `--no-fetch` (stale cache was defeating the gate) and rewrote the gate to distinguish drift (`rc=1` → recommends re-sync) from gate-unavailable (`rc≥2` → separate report-header note, doesn't block pole-3 reads).
- Fixes the silent drift between plugin VOCABULARIES.md and vault registre that had accumulated since v0.4.0 (plugin had 9 `type:` values, vault had 16).
- Breaking: no — additive. Existing skills unchanged in behavior; new references load on-demand.

## Installation

Click "Install plugin" when this `.plugin` file appears in Cowork chat. The 7 description-triggered skills load automatically when working with the Organon vault; the 3 user-only skills (`/kepano-resync`, `/plugin-release`, `/organon-memory-audit`) are invoked explicitly via slash command.

## Author

Pierre-André Folot · 2026-04-29 · Phase 5 wave 1 chat 1.B of the Claude × Organon refactor.
