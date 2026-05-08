# Syncing vault content into the organon plugin

This plugin **absorbs** content from the local Organon vault (canonical frontmatter registry, ID prefix registry, controlled vocabularies) into its own `skills/organon-frontmatter/references/` files. Absorption gives Claude offline access to vault truth: when `organon-frontmatter` triggers, the registres and vocabulaires are already loaded — no MCP round-trip required to the vault registre.

The script `scripts/sync-vault.sh` detects drift between absorbed content and the live vault. Drift surfaces as a report; **the script never auto-edits files or commits**. This is parallel to (and independent of) the kepano absorption mechanism (`scripts/sync-kepano.sh` + `kepano-sync.json`).

## Differences from kepano absorption

| | kepano | vault |
|---|---|---|
| Source of truth | external repo (`github.com/kepano/obsidian-skills`) | local Organon vault |
| Source identity | git commit sha | filesystem path + `synced_at_date` |
| Source mutability | upstream rewrites between fetches | live filesystem; Obsidian/Linter can rewrite during script run |
| Cache strategy | git clone + `git fetch` | direct read with `mktemp` snapshot for atomicity |
| Both ends owned by PA? | no — kepano is external | yes — PA owns both vault and plugin |

The shared discipline: hybrid Option D markers (heading + `body_sha256` fingerprint), per-section drift attribution, manual re-sync only.

## When to run

Whenever you suspect the vault registre, prefixes registry, or any controlled vocabulary has changed and you want to know whether a re-sync of the plugin is needed. Reasonable cadences: monthly, before plugin releases, after any FIN-BL or SD-BL that touches the registre. There is no automated trigger.

The vault file `[[Registre des clés de frontmatter]]` carries a governance rule: "ajouter une valeur à un enum = éditer la note vocabulaire + ajuster cette ligne du Registre dans la même unité de travail." So a vocab change usually surfaces as drift on **two** entries (the Vocabulaire `Valeurs` section + the corresponding cell in `REGISTRE_KEYS.md`). If only one drifts, that's a vault governance violation worth flagging.

## Detect drift

```bash
./scripts/sync-vault.sh
```

The script:

1. Reads `vault-sync.json` (each entry pins a vault-relative path + extraction mode + `body_sha256` snapshot at sync time).
2. For each entry, reads the live vault file via the path in `vault_root` + `vault_path`.
3. Snapshots the file to `mktemp` (atomic — protects against Obsidian/Linter rewriting mid-script).
4. Extracts the body (`extract_mode: "full-body"` for whole-note bodies, `"section-body"` for `## <heading>` sections without the heading line itself).
5. Hashes the extracted bytes, compares to stored `body_sha256`.
6. Prints a per-entry status table.

Possible statuses:

| status | meaning |
|---|---|
| `in-sync` | vault body matches the stored sha — no review needed |
| `vault-changed` | body differs — review and re-sync if appropriate |
| `section-missing` | the section heading was renamed or removed in the vault file — manual investigation needed |
| `vault-file-missing` | the source file no longer exists in the vault — manual investigation needed |

Exit code is `0` when everything is `in-sync`, `1` if any drift is detected.

Useful flags:

- `--json` — emit the report as JSON (for piping into other tools).

## Re-sync a drifted entry

The script does not auto-resolve drift. The reviewer pulls the new vault content manually, replaces the absorbed copy, updates `vault-sync.json`, and commits.

For each entry reported as drifted:

1. **Inspect the vault change.** Open the vault file in Obsidian or read it via MCP / filesystem. Compare what's there now to the absorbed copy in the plugin reference file.

2. **Decide whether to absorb the change.** Most vault changes are improvements; some may conflict with Organon-specific framing in the surrounding plugin reference file (the prose outside the `<!-- VAULT-BEGIN/END -->` markers). If the change conflicts, you may choose to **not** re-sync, and instead document the divergence in `vault-sync.json` (e.g., bump `synced_at_date` but keep the divergent body, with a `note` field explaining why).

3. **Pull the new content.** Replace the bytes between the `<!-- VAULT-BEGIN -->` and `<!-- VAULT-END -->` markers in the target reference file with the new vault body. Keep the framing prose (outside the markers) Organon-owned.

4. **Update the marker comment** with the new `synced_at_date`:

   ```
   <!-- VAULT-BEGIN: <vault_path> [§<heading>] @synced:<new-date> -->
   ```

5. **Recompute `body_sha256`** and update `vault-sync.json`:

   - For `extract_mode: "full-body"`:
     ```bash
     awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
         "$VAULT/99 - Méta/Système documentaire/<file>.md" \
       | sha256sum | awk '{print $1}'
     ```
   - For `extract_mode: "section-body"` (e.g., `Valeurs` section): use the `extract_section_body` helper in `scripts/sync-vault.sh`. Paste this awk one-liner:
     ```bash
     awk -v target="Valeurs" '
         function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
         BEGIN { in_section = 0; depth = 0 }
         /^#+[[:space:]]/ {
             match($0, /^#+/)
             cur_depth = RLENGTH
             cur_text = trim(substr($0, RLENGTH + 1))
             if (in_section && cur_depth <= depth) { in_section = 0 }
             if (!in_section && cur_text == target) { in_section = 1; depth = cur_depth; next }
         }
         in_section { print }
     ' "$VAULT/99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — <key>.md" \
       | sha256sum | awk '{print $1}'
     ```

6. **Update the JSON entry** for that entry: bump `synced_at_date`, `body_sha256`; reset `drift_status` to `"in-sync"`.

7. **Re-run `./scripts/sync-vault.sh`** — should report `in-sync` for the touched entry. If it still reports drift, your sha computation didn't match the script's. Most common cause: trailing-newline mismatch from bash command substitution. Use the temp-file pattern (the script does this internally with `mktemp`):

   ```bash
   tmp=$(mktemp)
   awk '...' "$file" > "$tmp"
   sha256sum "$tmp" | awk '{print $1}'
   rm -f "$tmp"
   ```

8. **Test the affected skill** (a skill-creator eval at minimum, see `evals/`) before committing. Reading the absorbed file in context is not always enough — the surrounding SKILL.md prose may now contradict the new content.

9. **Commit**: bundle the absorbed-file change + `vault-sync.json` update in one commit. Suggested message form:

   ```
   organon: re-sync <vault file>/<section> from vault @<new-date>
   ```

## When the vault renames a heading (`section-missing` status)

The script's section extraction matches by exact heading text. If the vault Vocabulaire file renames `## Valeurs` to `## Liste` (hypothetical), the script reports `section-missing`. Investigate manually:

```bash
grep -n '^#' "$VAULT/99 - Méta/Système documentaire/Vocabulaires/Vocabulaire — <key>.md"
```

If the rename is real, choose one of:

- **Adopt the rename**: update `section_heading` in `vault-sync.json`, re-extract, recompute sha, update markers, commit.
- **Reject the rename**: rare for vault content (PA owns both ends). If desired, document via a `note` field; the script will continue reporting `section-missing` until the heading reverts or you adopt.

If the section was removed entirely (PA dropped that vocabulary), evaluate whether the plugin still needs it. If yes, the absorbed content becomes Organon-owned (remove the markers and the `vault-sync.json` entry, restate as Organon convention).

## Add a new absorption

To absorb a new vault file or section:

1. Decide the target reference file. Vocabularies typically go in `references/VOCABULARIES.md`; new top-level governance documents go in their own file under `references/`.
2. Insert the marker pair around the absorbed content:

   ```
   <!-- VAULT-BEGIN: <vault-path> [§<heading>] @synced:<date> -->
   <!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

   [verbatim absorbed content]

   <!-- VAULT-END: <vault-path> [§<heading>] -->
   ```

3. Compute `body_sha256` (see step 5 above).
4. Add the entry to `vault-sync.json` with the right `extract_mode` and `drift_status: "in-sync"`.
5. Update the surrounding skill SKILL.md if the cascade pointer or framing prose needs updating.
6. Run `./scripts/sync-vault.sh` — confirm `in-sync` for the new entry.
7. Commit.

## When the vault path uses non-ASCII characters

The vault uses `99 - Méta/Système documentaire/...` with diacritics. The script reads JSON via `jq` and shells the path through bash's parameter expansion (`${~/$HOME}`) — both handle UTF-8 fine on macOS APFS. No encoding gymnastics required. If you see a `vault-file-missing` status on a path that visibly exists, check for NFC/NFD mismatch (rare on APFS but possible if the path was copy-pasted from a different source).

## Background

- Decision: this work was scoped in the v0.5.0 release (Tier 1 + Tier 2 + drift machinery — see plan `hidden-singing-ladybug.md` and the v0.5.0 release notes).
- Marker convention rationale: hybrid Option D (heading + body sha256 fingerprint) — same as kepano absorption. Chosen over pure-heading (silent breakage on rename) and pure-content-hash (opaque to humans).
- Why no `vault-resync` skill yet: the parallel `kepano-resync` runbook was written *after* drift had been resolved manually a few times and the failure modes were known. Same strategy here — exercise the manual flow first, codify after.
