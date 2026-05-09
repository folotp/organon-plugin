# Syncing kepano content into the organon plugin

This plugin **absorbs** content from the upstream [kepano `obsidian-skills`](https://github.com/kepano/obsidian-skills) repo (skills `obsidian-markdown`, `obsidian-bases`, `json-canvas`) into its own `skills/organon-*/references/` files. Absorption eliminates the runtime cascade load: when an `organon-*` skill triggers, the corresponding kepano content is already present locally and the kepano plugin no longer needs to load.

To stay within shouting distance of upstream, the script `scripts/sync-kepano.sh` detects drift between absorbed content and current upstream HEAD. Drift surfaces as a report; **the script never auto-edits files or commits**.

## When to run

Whenever you suspect kepano upstream has changed and you want to know whether a re-sync review is needed. Reasonable cadences: monthly, before plugin releases, or when upstream issues a tagged release. There is no automated trigger.

## Detect drift

```bash
./scripts/sync-kepano.sh
```

The script:

1. Clones (first run) or `git fetch`es the upstream repo into `${XDG_CACHE_HOME:-~/.cache}/organon-plugin/kepano-skills`.
2. Reads `kepano-sync.json` (each entry pins a kepano source path + section heading + `body_sha256` snapshot at sync time).
3. For each entry, extracts the section body from upstream HEAD, hashes it, compares to the stored `body_sha256`.
4. Prints a per-section status table.

Possible statuses (bilateral check since v0.6.x — both upstream-side and plugin-target-side are verified):

| status | meaning |
|---|---|
| `in-sync` | upstream body AND plugin target between markers both match stored sha — no review needed |
| `upstream-changed` | upstream body differs from stored — review and re-sync if appropriate |
| `heading-removed` | the section heading was renamed or removed upstream — manual investigation needed |
| `upstream-file-missing` | the source file no longer exists upstream — manual investigation needed |
| `target-corrupt` | upstream matches stored, but the plugin target body inside `<!-- KEPANO-* -->` markers diverges — implies a hand-edit bypassed the resync flow; restore from upstream cache |
| `target-marker-missing` | upstream matches stored, but the BEGIN/END markers can't be located in the plugin target — markers were removed or corrupted, manual fix |

Exit code is `0` when everything is `in-sync`, `1` if any drift is detected (either upstream-side or target-side).

Useful flags:

- `--no-fetch` — operate on the cached upstream as-is (skip `git fetch`). Faster iteration when drilling into a single drifted section.
- `--json` — emit the report as JSON (for piping into other tools).

## Re-sync a drifted section

The script does not auto-resolve drift. The reviewer pulls the new upstream content manually, replaces the absorbed copy, updates `kepano-sync.json`, and commits.

For each section reported as drifted:

1. **Inspect the upstream change.** Compare upstream HEAD vs the stored sha:

   ```bash
   git -C ~/.cache/organon-plugin/kepano-skills log \
       --oneline <stored_sha>..HEAD -- skills/<kepano-skill>/<path>
   ```

2. **Decide whether to absorb the change.** Some upstream changes are improvements; others may conflict with Organon-specific deltas in the surrounding `organon-*/SKILL.md`. If the change conflicts, you may choose to **not** re-sync, and instead document the divergence in `kepano-sync.json` (e.g., bump `synced_at_sha` but keep the divergent body, with a note added to the JSON).

3. **Pull the new content.** Replace the bytes between the `<!-- KEPANO-BEGIN -->` and `<!-- KEPANO-END -->` markers in the target file with the new upstream body. Keep the framing prose (outside the markers) Organon-owned.

4. **Update the marker comment** with the new commit short SHA:

   ```
   <!-- KEPANO-BEGIN: <skill> <path> @sha:<new-short-sha> -->
   ```

5. **Recompute `body_sha256`** and update `kepano-sync.json`:

   - For SKILL.md whole-body absorption:
     ```bash
     awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
         ~/.cache/organon-plugin/kepano-skills/skills/<skill>/SKILL.md \
       | sha256sum | awk '{print $1}'
     ```
   - For whole-file absorption (e.g., `references/EMBEDS.md`):
     ```bash
     sha256sum ~/.cache/organon-plugin/kepano-skills/skills/<skill>/<path>
     ```
   - For section absorption (e.g., `§Diagrams (Mermaid)`): use the section-extraction awk in `scripts/sync-kepano.sh` (the `extract_section` function).

6. **Update the JSON entry** for that section: bump `synced_at_sha`, `synced_at_date`, `body_sha256`; reset `drift_status` to `"in-sync"`.

7. **Re-run `./scripts/sync-kepano.sh`** — should report `in-sync` for the touched section. If it still reports drift, your sha computation didn't match the script's. Most common cause: trailing-newline mismatch from bash command substitution; the script uses a temp-file pattern to avoid this — use the same.

8. **Test the affected `organon-*` skill** (a skill-creator eval at minimum, see `evals/`) before committing. Reading the absorbed file in context is not always enough — the surrounding SKILL.md prose may now contradict the new content.

9. **Commit**: bundle the absorbed-file change + `kepano-sync.json` update in one commit. Suggested message form:

   ```
   organon: re-sync <kepano-skill>/<section> from kepano @<new-short-sha>
   ```

## When upstream renames a heading (`heading-removed` status)

The script's section extraction matches by exact heading text. If upstream renames `## Diagrams (Mermaid)` to `## Mermaid Diagrams`, the script reports `heading-removed`. Investigate manually:

```bash
grep -n '^#' ~/.cache/organon-plugin/kepano-skills/skills/<skill>/SKILL.md
```

If the rename is real, choose one of:

- **Adopt the rename**: update `kepano_section_heading` in `kepano-sync.json`, re-extract, recompute sha, update markers, commit.
- **Reject the rename**: document the divergence (e.g., the rename was cosmetic and we keep our heading for continuity) by leaving `kepano_section_heading` unchanged and adding a `note` field. The script will continue to report `heading-removed` until the upstream heading reverts or you adopt.

If the section was removed entirely (kepano dropped that material), evaluate whether Organon still needs it — if yes, the absorbed content becomes Organon-owned (remove the markers and the `kepano-sync.json` entry, restate as Organon convention).

## Add a new absorption

To absorb a new kepano section:

1. Pick the `organon-*` skill that owns the cascade. Decide whether the new content goes inline in `SKILL.md` (≤ ~30 lines) or in a `references/` file (anything larger).
2. Insert the marker pair around the absorbed content:

   ```
   <!-- KEPANO-BEGIN: <skill> <path> [§<heading>] @sha:<short-sha> -->
   <!-- kepano-sync: see kepano-sync.json for body_sha256 + drift status -->

   [verbatim absorbed content]

   <!-- KEPANO-END: <skill> <path> [§<heading>] -->
   ```

3. Compute `body_sha256` (see step 5 above).
4. Add the entry to `kepano-sync.json` (`drift_status: "in-sync"`).
5. Update the surrounding `organon-*/SKILL.md` body if the cascade pointer or framing prose needs updating.
6. Run `./scripts/sync-kepano.sh` — confirm `in-sync` for the new entry.
7. Commit.

## Background

- Decision: [VLT-ADR-013](../../99-Méta/Outils/Accès%20à%20Obsidian%20par%20Claude/ADR/VLT-ADR-013.md) (Phase 7 cible recalibrée + B9 P7.3 conditionnelle).
- Implementation: [VLT-BL-0063](../../99-Méta/Outils/Accès%20à%20Obsidian%20par%20Claude/Backlog/VLT-BL-0063.md) (B4-complet, 9 absorption units, completed 2026-05-05).
- Marker convention rationale: hybrid Option D (heading + body sha256 fingerprint) — chosen over pure-heading (silent breakage on rename) and pure-content-hash (opaque to humans).
