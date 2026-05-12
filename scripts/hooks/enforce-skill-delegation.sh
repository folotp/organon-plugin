#!/usr/bin/env bash
# enforce-skill-delegation.sh — PreToolUse hook for the Skill tool.
#
# Reinforces the delegation mandate encoded in the thin-shim SKILL.md files
# for skills that carry a BLOCKING REQUIREMENT to dispatch a sonnet-pinned
# executor sub-agent. This hook catches those invocations and emits a
# stdout reinforcement block so the model's next turn sees an explicit
# routing directive — even if a hurried main session tries to inline the
# runbook instead of delegating.
#
# Covered skills (blocking mandate):
#   plugin-release       → plugin-release-executor
#   kepano-resync        → kepano-resync-orchestrator
#   organon-memory-audit → memory-audit-executor
#
# Excluded by design:
#   organon-diagramming  — delegation is advisory/optional, not blocking.
#
# Exit code: always 0. This hook reinforces; it does NOT block.
# Reinforcement goes to stdout (model context); audit line goes to stderr.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
[[ "$tool_name" == "Skill" ]] || exit 0

# The Skill tool payload uses `.tool_input.skill` — read both known field
# names defensively and take the first non-null value.
skill_name="$(printf '%s' "$input" | jq -r '(.tool_input.skill // .tool_input.skill_name) // empty')"
[[ -n "$skill_name" ]] || exit 0

case "$skill_name" in
    plugin-release)
        executor="plugin-release-executor"
        ;;
    kepano-resync)
        executor="kepano-resync-orchestrator"
        ;;
    organon-memory-audit)
        executor="memory-audit-executor"
        ;;
    *)
        # Non-mandated skill (including organon-diagramming) — no-op.
        exit 0
        ;;
esac

# Stdout: reinforcement block surfaced to the model as additional context.
cat <<EOF
[skill-routing] Delegation-mandatory skill \`${skill_name}\` invoked.
Your next tool call MUST be Agent(subagent_type="${executor}", ...).
The main session is not authorised to execute this runbook inline.
Runbook: .claude/agents/${executor}.md
EOF

# Stderr: audit trail mirroring block-absorbed-edits.sh convention.
echo "enforce-skill-delegation: routed ${skill_name} -> ${executor}" >&2

exit 0
