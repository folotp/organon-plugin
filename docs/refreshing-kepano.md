# Refreshing absorbed kepano content

The plugin pins one upstream sha for `kepano/obsidian-skills` in `kepano-version.txt`. Since v1.0.0 the absorbed references are **AI-slim adaptations** of upstream content, not byte-equivalent copies — the pin records the upstream version the adaptations were derived from. Run `scripts/kepano-check-upstream.sh` to detect when upstream has advanced past the pin.

## When upstream advances

1. `git clone https://github.com/kepano/obsidian-skills /tmp/kepano` (or update an existing clone).
2. For each path under `skills/*/references/` listed below, diff against the corresponding upstream file:
   ```
   git -C /tmp/kepano diff <pinned-sha>..HEAD -- <upstream-path>
   ```
3. Review the diff. Either:
   - **Adopt**: copy the new upstream content into the plugin reference (replacing the body inside the file — see note on markers below). Then bump the sha in `kepano-version.txt`.
   - **Skip**: leave the plugin reference at the older content; bump `kepano-version.txt` only when ready.
4. Commit on a `feat/kepano-refresh-<sha-short>` branch.

## Absorbed paths and their upstream counterparts

| Plugin path | Upstream path |
|---|---|
| `skills/organon-bases/references/BASES_SYNTAX.md` | `skills/obsidian-bases/SKILL.md` |
| `skills/organon-bases/references/FUNCTIONS_REFERENCE.md` | `skills/obsidian-bases/references/FUNCTIONS_REFERENCE.md` |
| `skills/organon-canvas/references/CANVAS_SPEC.md` | `skills/json-canvas/SKILL.md` |
| `skills/organon-canvas/references/EXAMPLES.md` | `skills/json-canvas/references/EXAMPLES.md` |
| `skills/organon-diagramming/references/MERMAID_SYNTAX.md` | `skills/mermaid/SKILL.md` |
| `skills/organon-frontmatter/references/PROPERTIES.md` | `skills/obsidian-frontmatter/references/PROPERTIES.md` |
| `skills/organon-markdown-style/references/CALLOUTS.md` | `skills/obsidian-markdown/references/CALLOUTS.md` |
| `skills/organon-markdown-style/references/EMBEDS.md` | `skills/obsidian-markdown/references/EMBEDS.md` |
| `skills/organon-markdown-style/references/MARKDOWN_SYNTAX.md` | `skills/obsidian-markdown/SKILL.md` |

## Markers

Prior absorbed files carried `<!-- KEPANO-BEGIN -->` / `<!-- KEPANO-END -->` HTML comments. v1.0.0 retired the body-hash comparison; markers are no longer required and were stripped. New refreshes should not re-add them — the sha pin is the only contract.

## Prior absorption model (pre-v1.0.0)

Before v1.0.0, each absorbed section was tracked individually: HTML `<!-- KEPANO-BEGIN -->` / `<!-- KEPANO-END -->` marker pairs delimited each section, and a `kepano-sync.json` ledger stored a `body_sha256` fingerprint per entry. A 317-LoC `scripts/sync-kepano.sh` compared the fingerprints against upstream on each resync.

This was retired at v1.0.0 (commit f0b8bee) because kepano references are refreshed as whole files, not section-by-section — a unified diff on `git diff <pin>..HEAD` is sufficient and requires no per-entry ledger. The version-pin model replaced ~500 LoC with `kepano-version.txt` + `kepano-check-upstream.sh` (~50 LoC).

The markers are no longer present in the reference files and should not be re-added.

## The PreToolUse hook (`scripts/hooks/block-absorbed-edits.sh`)

Still blocks direct `Edit|Write|MultiEdit` on the 9 paths above (hardcoded list) to prevent accidental drift. The legitimate refresh path is to bump `kepano-version.txt` and rewrite the file as part of the same commit — the pre-commit gate confirms `kepano-check-upstream.sh` is in-sync at the new pin before the commit lands.
