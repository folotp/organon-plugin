#!/usr/bin/env python3
"""Token harness — formal P6.2 successor.

Measures the runtime token cost of the organon plugin across 13
representative session shapes, with a built-in pre/post comparison
between the cascade-eager era and the v0.4.0 lazy-load era.

See docs/token-harness-methodology.md for the design and methodology.

Usage:
    python3 scripts/token-harness.py [--iteration N]

Default iteration N is auto-discovered from eval-workspace/ (next
unused integer). Output:
    eval-workspace/iteration-N/harness-output.json   (machine-readable)

Requires: tiktoken (pip install --user tiktoken)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
from pathlib import Path

try:
    import tiktoken
except ImportError:
    sys.stderr.write(
        "tiktoken not installed. Run: pip install --user tiktoken\n"
    )
    sys.exit(2)


REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
EVAL_DIR = REPO_ROOT / "eval-workspace"

ENCODING = tiktoken.get_encoding("cl100k_base")

# ---------------------------------------------------------------------------
# Skill file classification.
#
# Per skill: which references files were absorbed from kepano (eager pre,
# lazy post) vs. which are Organon-specific (lazy in both eras).
# ---------------------------------------------------------------------------

SKILLS: dict[str, dict[str, list[str] | str | None]] = {
    "organon-frontmatter": {
        "core": ["SKILL.md"],
        "absorbed_refs": ["references/PROPERTIES.md"],
        # SHAPES_QUICKREF split out from core in v0.6.0 (perf trim).
        "own_refs": [
            "references/VOCABULARIES.md",
            "references/SHAPES_QUICKREF.md",
        ],
        "dispatch_to": None,
    },
    "organon-vault-write": {
        "core": ["SKILL.md"],
        "absorbed_refs": [],
        "own_refs": [],
        "dispatch_to": None,
    },
    "organon-markdown-style": {
        "core": ["SKILL.md"],
        "absorbed_refs": [
            "references/MARKDOWN_SYNTAX.md",
            "references/CALLOUTS.md",
            "references/EMBEDS.md",
        ],
        "own_refs": [],
        "dispatch_to": None,
    },
    "organon-bases": {
        # v1.0.0: dispatch shim. SKILL.md is a 1.6 kB router; the full
        # author runbook + the absorbed refs are loaded by the sonnet
        # sub-agent, not by the main session.
        "core": ["SKILL.md"],
        "absorbed_refs": [
            "references/BASES_SYNTAX.md",
            "references/FUNCTIONS_REFERENCE.md",
        ],
        "own_refs": [],
        "dispatch_to": "bases-author",
    },
    "organon-canvas": {
        # v1.0.0: dispatch shim.
        "core": ["SKILL.md"],
        "absorbed_refs": [
            "references/CANVAS_SPEC.md",
            "references/EXAMPLES.md",
        ],
        # LABEL_TRANSLATIONS split out from core in v0.6.0 (perf trim).
        "own_refs": [
            "references/LABEL_TRANSLATIONS.md",
        ],
        "dispatch_to": "canvas-author",
    },
    "organon-diagramming": {
        # MERMAID_SYNTAX (kepano-absorbed) and EXCALIDRAW_SKELETON
        # split out from core in v0.6.0 (perf trim).
        "core": ["SKILL.md"],
        "absorbed_refs": [
            "references/MERMAID_SYNTAX.md",
        ],
        "own_refs": [
            "references/EXCALIDRAW_SKELETON.md",
        ],
        "dispatch_to": None,
    },
    "organon-session-discipline": {
        # BOOTSTRAP_CACHE retired in v0.8.0.
        "core": ["SKILL.md"],
        "absorbed_refs": [],
        "own_refs": [],
        "dispatch_to": None,
    },
    "organon-vault-read": {
        # v1.1.0 — read-side counterpart to organon-vault-write.
        "core": ["SKILL.md"],
        "absorbed_refs": [],
        "own_refs": [
            "references/READ_TOOL_MATRIX.md",
        ],
        "dispatch_to": None,
    },
}


# ---------------------------------------------------------------------------
# Session shapes.
#
# Each session lists triggered skills and the references the task needs
# (would actually consume post-absorption). Refs not in `needs` count
# eagerly pre-absorption but not post.
# ---------------------------------------------------------------------------

SESSIONS: list[dict] = [
    {
        "id": "S01",
        "name": "Frontmatter touch (1-2 keys, no schema lookup)",
        "skills": ["organon-frontmatter", "organon-vault-write"],
        "needs": [],
    },
    {
        "id": "S02",
        "name": "Structured note creation (ADR via Templater-first routing)",
        "skills": [
            "organon-frontmatter",
            "organon-vault-write",
            "organon-session-discipline",
        ],
        "needs": [
            ("organon-frontmatter", "references/PROPERTIES.md"),
            ("organon-frontmatter", "references/VOCABULARIES.md"),
            ("organon-frontmatter", "references/SHAPES_QUICKREF.md"),
        ],
    },
    {
        "id": "S03",
        "name": "Body markdown style edit (typographic, no H1)",
        "skills": ["organon-markdown-style"],
        "needs": [],
    },
    {
        "id": "S04",
        "name": "Bases simple filter add",
        "skills": ["organon-bases"],
        "needs": [],
    },
    {
        "id": "S05",
        "name": "Bases deep schema (formula columns + custom views)",
        "skills": ["organon-bases"],
        "needs": [
            ("organon-bases", "references/BASES_SYNTAX.md"),
            ("organon-bases", "references/FUNCTIONS_REFERENCE.md"),
        ],
    },
    {
        "id": "S06",
        "name": "Canvas creation (file-node + group + edge)",
        "skills": ["organon-canvas"],
        "needs": [
            ("organon-canvas", "references/CANVAS_SPEC.md"),
            ("organon-canvas", "references/EXAMPLES.md"),
            ("organon-canvas", "references/LABEL_TRANSLATIONS.md"),
        ],
    },
    {
        "id": "S07",
        "name": "Multi-artifact session (BL + ADR + INC sequential)",
        "skills": [
            "organon-frontmatter",
            "organon-vault-write",
            "organon-session-discipline",
        ],
        "needs": [
            ("organon-frontmatter", "references/PROPERTIES.md"),
            ("organon-frontmatter", "references/VOCABULARIES.md"),
            ("organon-frontmatter", "references/SHAPES_QUICKREF.md"),
        ],
    },
    {
        "id": "S08",
        "name": "Diagramming triage (mermaid vs canvas decision)",
        "skills": ["organon-diagramming"],
        "needs": [],
    },
    {
        "id": "S09",
        "name": "Vault-write append (heading patch, no schema)",
        "skills": ["organon-vault-write"],
        "needs": [],
    },
    {
        "id": "S10",
        "name": "Sweep / refactor wave (frontmatter migration N notes)",
        "skills": [
            "organon-frontmatter",
            "organon-vault-write",
            "organon-session-discipline",
        ],
        "needs": [
            ("organon-frontmatter", "references/VOCABULARIES.md"),
        ],
    },
    {
        "id": "S11",
        "name": "Atomic frontmatter write (set_note_property, 1-3 keys)",
        "skills": ["organon-frontmatter", "organon-vault-write"],
        "needs": [],
    },
    {
        "id": "S12",
        "name": "Partial read (get_vault_file_partial mode=heading)",
        "skills": ["organon-vault-read"],
        "needs": [],
    },
    {
        "id": "S13",
        "name": "Exploratory semantic pre-filter (search_vault_smart → top-3 partial)",
        "skills": ["organon-session-discipline", "organon-vault-read"],
        "needs": [
            ("organon-vault-read", "references/READ_TOOL_MATRIX.md"),
        ],
    },
]


# ---------------------------------------------------------------------------
# Tokenization.
# ---------------------------------------------------------------------------


def file_tokens(path: Path) -> int:
    if not path.is_file():
        raise FileNotFoundError(f"Missing file: {path}")
    return len(ENCODING.encode(path.read_text(encoding="utf-8")))


def skill_path(skill: str, rel: str) -> Path:
    return SKILLS_DIR / skill / rel


# ---------------------------------------------------------------------------
# Per-session pre/post computation.
# ---------------------------------------------------------------------------


def session_costs(session: dict, token_cache: dict[Path, int]) -> dict:
    """Return per-session pre/post tokens and the file lists used.

    `pre_tokens`: cascade-eager era (every absorbed ref loaded with the SKILL).
    `post_tokens`: v0.4.0+ lazy-load era, MAIN-CONTEXT only.

    For skills with `dispatch_to` set (v1.0.0+), only the SKILL.md shim
    is loaded into the main session; the author sub-agent picks up the
    referenced bodies in its own context (counted under
    `subagent_tokens` for visibility but not against post_tokens).
    """

    def cached(p: Path) -> int:
        if p not in token_cache:
            token_cache[p] = file_tokens(p)
        return token_cache[p]

    pre_files: list[tuple[str, int]] = []
    post_files: list[tuple[str, int]] = []
    subagent_files: list[tuple[str, int]] = []

    needs_set = {(s, r) for (s, r) in session["needs"]}

    for skill in session["skills"]:
        spec = SKILLS[skill]
        dispatches = spec.get("dispatch_to") is not None

        # Core: always loaded in both eras (SKILL.md, dispatch shim or full body).
        for rel in spec["core"]:
            p = skill_path(skill, rel)
            t = cached(p)
            pre_files.append((str(p.relative_to(REPO_ROOT)), t))
            post_files.append((str(p.relative_to(REPO_ROOT)), t))

        # absorbed_refs: eager pre, lazy post.
        # If the skill dispatches, refs go to sub-agent context, not main.
        for rel in spec["absorbed_refs"]:
            p = skill_path(skill, rel)
            t = cached(p)
            pre_files.append((str(p.relative_to(REPO_ROOT)), t))
            if (skill, rel) in needs_set:
                if dispatches:
                    subagent_files.append((str(p.relative_to(REPO_ROOT)), t))
                else:
                    post_files.append((str(p.relative_to(REPO_ROOT)), t))

        # own_refs: lazy in both eras.
        for rel in spec["own_refs"]:
            p = skill_path(skill, rel)
            t = cached(p)
            if (skill, rel) in needs_set:
                pre_files.append((str(p.relative_to(REPO_ROOT)), t))
                if dispatches:
                    subagent_files.append((str(p.relative_to(REPO_ROOT)), t))
                else:
                    post_files.append((str(p.relative_to(REPO_ROOT)), t))

        # If the skill dispatches, count the sub-agent's body too.
        if dispatches:
            agent_path = SKILLS_DIR / skill / f"{spec['dispatch_to']}.md"
            if agent_path.is_file():
                t = cached(agent_path)
                subagent_files.append(
                    (str(agent_path.relative_to(REPO_ROOT)), t)
                )

    pre_tokens = sum(t for _, t in pre_files)
    post_tokens = sum(t for _, t in post_files)
    subagent_tokens = sum(t for _, t in subagent_files)
    ratio = pre_tokens / post_tokens if post_tokens > 0 else float("inf")

    return {
        "id": session["id"],
        "name": session["name"],
        "skills": session["skills"],
        "pre_tokens": pre_tokens,
        "post_tokens": post_tokens,
        "subagent_tokens": subagent_tokens,
        "ratio": round(ratio, 3),
        "pre_files": pre_files,
        "post_files": post_files,
        "subagent_files": subagent_files,
    }


# ---------------------------------------------------------------------------
# Output helpers.
# ---------------------------------------------------------------------------


def auto_iteration() -> int:
    if not EVAL_DIR.is_dir():
        return 1
    pattern = re.compile(r"^iteration-(\d+)$")
    used = []
    for entry in EVAL_DIR.iterdir():
        m = pattern.match(entry.name)
        if m:
            used.append(int(m.group(1)))
    return (max(used) + 1) if used else 1


def render_table(rows: list[dict]) -> str:
    cols = ("id", "name", "pre_tokens", "post_tokens", "subagent_tokens", "ratio")
    headers = ("ID", "Session shape", "pre_tok", "post_tok", "sub_tok", "ratio")
    widths = [len(h) for h in headers]
    for r in rows:
        for i, c in enumerate(cols):
            val = str(r[c])
            if len(val) > widths[i]:
                widths[i] = len(val)
    sep = "  ".join("-" * w for w in widths)
    fmt_h = "  ".join(f"{h:<{widths[i]}}" for i, h in enumerate(headers))
    lines = [fmt_h, sep]
    for r in rows:
        line = "  ".join(
            f"{str(r[c]):<{widths[i]}}" if c in ("id", "name") else f"{str(r[c]):>{widths[i]}}"
            for i, c in enumerate(cols)
        )
        lines.append(line)
    return "\n".join(lines)


def verdict(mean_ratio: float) -> str:
    if mean_ratio >= 2.15:
        return "PASS (target ≥ 2.15× B4-complet)"
    if mean_ratio >= 2.0:
        return "PASS-marginal (within closure projection 2.0-2.5×, target nominally missed)"
    return "FAIL (below closure projection lower bound)"


# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--iteration",
        type=int,
        default=None,
        help="iteration number (default: auto-pick next unused).",
    )
    parser.add_argument(
        "--no-write",
        action="store_true",
        help="print results only, do not create eval-workspace/iteration-N/.",
    )
    args = parser.parse_args()

    iteration = args.iteration if args.iteration else auto_iteration()
    iter_dir = EVAL_DIR / f"iteration-{iteration}"

    token_cache: dict[Path, int] = {}
    rows: list[dict] = []
    for s in SESSIONS:
        rows.append(session_costs(s, token_cache))

    ratios = [r["ratio"] for r in rows]
    mean_ratio = round(statistics.mean(ratios), 3)
    median_ratio = round(statistics.median(ratios), 3)
    p90_ratio = round(sorted(ratios)[int(0.9 * len(ratios))], 3)

    pre_total = sum(r["pre_tokens"] for r in rows)
    post_total = sum(r["post_tokens"] for r in rows)
    subagent_total = sum(r["subagent_tokens"] for r in rows)
    aggregate_ratio = round(pre_total / post_total, 3)

    print(f"# Token harness — iteration {iteration}\n")
    print(render_table(rows))
    print()
    print(f"mean(ratio)         = {mean_ratio}")
    print(f"median(ratio)       = {median_ratio}")
    print(f"p90(ratio)          = {p90_ratio}")
    print(f"aggregate ratio     = {aggregate_ratio}  ({pre_total} / {post_total})")
    print(f"pre tokens (cascade)= {pre_total}")
    print(f"post tokens (main)  = {post_total}   ← main opus session cost")
    print(f"sub-agent tokens    = {subagent_total}   ← dispatched to sonnet/haiku, separate context")
    print(f"target              = ≥ 2.15× (B4-complet)")
    print(f"verdict             = {verdict(mean_ratio)}")

    if args.no_write:
        return 0

    iter_dir.mkdir(parents=True, exist_ok=True)
    out = {
        "iteration": iteration,
        "tokenizer": "cl100k_base",
        "sessions": rows,
        "summary": {
            "mean_ratio": mean_ratio,
            "median_ratio": median_ratio,
            "p90_ratio": p90_ratio,
            "aggregate_ratio": aggregate_ratio,
            "pre_tokens_total": pre_total,
            "post_tokens_total": post_total,
            "subagent_tokens_total": subagent_total,
            "target": 2.15,
            "verdict": verdict(mean_ratio),
        },
    }
    out_path = iter_dir / "harness-output.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False))
    print(f"\nWrote {out_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
