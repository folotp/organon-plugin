---
name: organon-session-discipline
description: Use at the start of any Claude session operating on the Organon vault (path contains `Organon`), or before any multi-step Organon task (drafting/updating an ADR, BL, BUG, INC, sweep, refactor wave, or any "check if an Organon note needs updating" prompt). 9 behavioral rules: arbitrate over over-clarify, read bootstrap, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills, language coherence by folder, semantic pre-filter before exploratory reads, test temp dirs outside vault mount.
---

# organon-session-discipline

9 behavioral rules (cf. VLT-ADR-012). For technical conventions, cascade to `organon-vault-write`, `organon-vault-read`, `organon-frontmatter`, `organon-markdown-style`.

## 1. Arbitrate, don't over-clarify

If decision is inferable from context (ADRs, conventions, transcript), make the call and propose direction. Ask only for high-stakes ops (overwrite, delete, batch > 3, cross-domain refactor) or maximal ambiguity — even then, propose a default and let PA contest.

## 2. Read bootstrap once per session, only when needed

`[[AI Bootstrap]]` is canonical for vault topology: folder → domain entry note, pointers to domain bootstraps. Read once per session when drafting requires these facts; memoize for subsequent artifacts in same conversation.

## 3. No in-fiche redundancy

If info exists in table, list, or frontmatter, don't restate it in prose before or after. One canonical form per fact.

## 4. Confirm inferred mappings explicitly

When mapping across systems (`VLT-BUG-NNN ↔ GitHub issue #N`, `ADR ↔ problem ID`, `timestamp ↔ commit`), state the inference and ask "confirm?" in same response. PA accepting passively ≠ explicit validation.

## 5. Propose generalizations when patterns recur

When 2+ similar artifacts are produced (sweeps, layers, BL templates, parallel-structure fiches), propose a meta-pattern or template. Don't wait for PA to ask.

## 6. Check meta-skills before producing typed artifacts

Before drafting typed artifact (SKILL.md, ADR, plugin, MCP server, manifest), scan `available_skills` for a meta-skill encoding structural best practices.

**Why:** Claude undertriggers useful skills when local examples create false sense of full context.

## 7. Language coherence — folder default beats prompt language

For vault artifacts (ADR, BL, BUG, INC, Concept, Note, etc.), language governed by folder, not prompt. Full rule and examples: `organon-markdown-style` §Langue par dossier (canonical home).

## 8. Semantic pre-filter before exploratory reads

Before calling `get_vault_file` on unknown path (not hardcoded in skill or given in prompt), call `search_vault_smart` first with natural-language query.

**When to use:** Finding relevant notes, checking prior art, identifying context before multi-step task. Exempt: skill-hardcoded paths (`AI Bootstrap`, `Vault Conventions.md`, `references/*`), paths given explicitly by PA.

**Result interpretation:** Results are similarity-ranked. Read only top 1-3, only when path (folder + title) plausibly matches query — `search_vault_smart` returns paths and scores, no body excerpts. Off-topic top result (wrong domain folder, unrelated title) = skip.

**Read budget:** At most 3 reads per smart-search result set before re-evaluating. Prefer `get_vault_file_partial` (frontmatter / heading / outline) over full `get_vault_file` — see `organon-vault-read` for decision tree. All 3 candidates low-relevance → report to PA instead of reading further.

**Provider-not-ready fallback:** If `search_vault_smart` errors or times out, fall back to `search_vault_simple` (keyword). Don't skip pre-filtering entirely.

**Why:** Without this rule, exploratory reads default to full `get_vault_file` on uncertain paths, burning context tokens on irrelevant notes. `search_vault_smart` is a cheap path-filter before committing to any body read.

## 9. Test-framework temp dirs must be outside the vault mount

Never point pytest `tmp_path` (or any test-framework temporary directory) at the MCP-mounted vault path. The vault mount's cleanup walks the filesystem recursively, which recurses into the MCP mount and raises a `RecursionError` (observed: telemetry session S4). Use `tempfile.mkdtemp()` or a path under `/tmp` that is outside the vault root.
