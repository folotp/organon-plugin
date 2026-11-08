# Large reads in subagents

Subagents (`canvas-author`, `bases-author`, `memory-audit-executor`) read in chunks, whatever the host. The rule lives in each agent file under `## Large reads`; this note records why.

## Two truncation sources

- **Connector ceiling.** `get_vault_file` cuts text past its size limit and points to `get_vault_file_partial`. Always on.
- **Host rewriting.** Some hosts replace large tool results with a summary or pointer. context-mode did this for anything over ~4 KB (#102). It is disabled until mksglu/context-mode#1342 and #1343 are fixed, so #102 doesn't reproduce now; #102 stays open until re-tested with it on.

A subagent that read a whole note and got a pointer back had no way to recover, and reported wrong or partial findings.

## Rule

| Source | Read |
|---|---|
| Vault note | `get_vault_file_partial mode=document-map` → `mode=lines`, ≤ 40 lines/window, section by section. No `get_vault_file` on a note of unknown size. |
| Local file | `Read` with `offset`/`limit`, ≤ 150 lines/call. |
| Bash output | Page with `sed -n 'A,Bp'` or `head`. |

Result cut short or ends in a pointer → halve the window, retry. One line still cut → report failure; never guess the rest.

Measured 2026-11-07: a 52 KB note's `document-map` came back at ~3.5 KB with heading line numbers, small enough for any host.

## Related

- Issue #115 (this rule), #102 (context-mode truncation), #97 (earlier offset/limit wording, replaced).
- Main-session read routing: `skills/organon-vault-read/SKILL.md` rule 20.
