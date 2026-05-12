---
name: organon-session-discipline
description: Use at the start of any Claude session operating on the Organon vault (path contains `Organon`), or before any multi-step Organon task (drafting an ADR, BL, BUG, INC, sweep, refactor wave). 7 behavioral rules: arbitrate over over-clarify, read bootstrap, no in-fiche redundancy, confirm inferred mappings, propose generalizations, check meta-skills, language coherence by folder.
---

# organon-session-discipline

7 behavioral rules (cf. VLT-ADR-012). For technical conventions, cascade to `organon-vault-write`, `organon-frontmatter`, `organon-markdown-style`.

## 1. Arbitrate, don't over-clarify

When a decision is inferable from context (ADRs, conventions, transcript), make the call and propose direction. Ask only for high-stakes operations (overwrite, delete, batch > 3, cross-domain refactor) or maximal ambiguity — and even then, propose a default and let PA contest.

## 2. Read bootstrap once per session, only when needed

`[[AI Bootstrap]]` is canonical for vault topology: folder → domain entry note, pointers to domain bootstraps. Read once per session when drafting requires these facts; memoize for subsequent artifacts in the same conversation.

## 3. No in-fiche redundancy

If information exists in a table, list, or frontmatter, do not restate it in prose immediately before or after. One canonical form per fact.

## 4. Confirm inferred mappings explicitly

When mapping items across systems (`VLT-BUG-NNN ↔ GitHub issue #N`, `ADR ↔ problem ID`, `timestamp ↔ commit`), state the inference and ask "confirm?" in the same response. PA accepting passively ≠ explicit validation.

## 5. Propose generalizations when patterns recur

When 2+ similar artifacts are produced (sweeps, layers, BL templates, parallel-structure fiches), propose a meta-pattern or template. Don't wait for PA to ask.

## 6. Check meta-skills before producing typed artifacts

Before drafting a typed artifact (SKILL.md, ADR, plugin, MCP server, manifest), scan `available_skills` for a meta-skill encoding structural best practices.

**Why:** Claude tends to undertrigger useful skills when local examples create a false sense of having full context.

## 7. Language coherence — folder default beats prompt language

For vault artifacts (ADR, BL, BUG, INC, Concept, Note, etc.), language is governed by the folder, not the prompt. Full rule and examples: `organon-markdown-style` §Langue par dossier (canonical home).
