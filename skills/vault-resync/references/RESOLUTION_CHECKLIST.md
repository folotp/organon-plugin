# Resolution checklist — per drifted vault entry

Operational checklist for resolving a single drifted entry reported by `./scripts/sync-vault.sh`. Work this list once per entry; coupled vocabulary changes (Vocabulaire + Registre cell) typically surface as two entries — handle both before committing.

## Statuses

| status | meaning | routing |
|---|---|---|
| `in-sync` | live vault body matches stored sha | nothing to do |
| `vault-changed` | body differs | §Re-sync (§Divergence if conflict) |
| `section-missing` | heading renamed/removed in vault | §Heading rename |
| `vault-file-missing` | source file gone from vault | escalate — manual investigation |

## Re-sync (status: `vault-changed`)

1. **Pull the entry from `vault-sync.json`** — note `vault_path`, `section_heading`, `extract_mode`, `synced_at_date`, `target_file`, `body_sha256` (stored). If `target_section` is present (vocabulary entry into `references/VOCABULARIES.md`), note that too.

2. **Inspect the vault change.** Open the vault file in Obsidian or read it via MCP / filesystem. Compare what's there now to the absorbed copy in the plugin reference file:

   ```bash
   VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon"
   # full-body entries
   diff <(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$VAULT/<vault_path>") \
        <(sed -n '/<!-- VAULT-BEGIN/,/<!-- VAULT-END/p' "<target_file>" \
              | sed '1d;$d')
   # section-body entries: substitute the section extraction in the first <(...)
   ```

3. **Decide: absorb or diverge.** Most vault changes are improvements (PA owns both ends). If the change conflicts with plugin-specific framing prose surrounding the markers, choose §Divergence below instead.

4. **Pull the new content into `target_file`**, replacing only the bytes between `<!-- VAULT-BEGIN -->` and `<!-- VAULT-END -->`. The marker form:

   ```
   <!-- VAULT-BEGIN: <vault_path> [§<heading>] @synced:<new-date> -->
   <!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

   [verbatim absorbed content]

   <!-- VAULT-END: <vault_path> [§<heading>] -->
   ```

   Update the `@synced:` date on the BEGIN marker to today's ISO-8601 date (`date -u +%F`).

5. **Recompute `body_sha256`** — see §Hash recomputation. Use the same `extract_mode` the script uses for that entry. Always extract to a temp file (the script uses `mktemp`; bash command substitution strips trailing newlines and produces a different sha).

6. **Update `vault-sync.json`** entry:
   - `synced_at_date`: today, ISO-8601 (`date -u +%F`).
   - `body_sha256`: new sha from step 5.
   - `drift_status`: `"in-sync"`.

7. **Re-run** `./scripts/sync-vault.sh` — confirm `in-sync` for this entry. If it still reports drift, the sha computation didn't match — almost always a trailing-newline mismatch from forgetting the temp-file pattern.

8. **Test the affected `organon-frontmatter` skill** — load it in a fresh chat, confirm the absorbed content reads coherently with the surrounding `SKILL.md`. If a vocabulary value was added/removed/renamed, the framing prose may now contradict the absorbed list — update the framing prose in a *separate* commit so the re-sync commit stays "absorbed file + sync.json only".

9. **Commit** using the form in `commit-template.txt`. The re-sync commit must contain *only* the absorbed file + `vault-sync.json` change. Coupled entries (Vocabulaire + Registre) bundle in the same commit — they are one logical unit per the vault governance rule.

## Hash recomputation

The script's extraction shape varies by `extract_mode`. Match it exactly.

### `extract_mode: "full-body"` — whole-note absorption (Registre, Préfixes)

Strip the YAML frontmatter (everything before the second `---` line):

```bash
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon"
tmp=$(mktemp)
awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
    "$VAULT/<vault_path>" > "$tmp"
shasum -a 256 < "$tmp" | awk '{print $1}'
rm -f "$tmp"
```

(Use `sha256sum` instead of `shasum -a 256` if you're on a Linux box; macOS provides `shasum` by default.)

### `extract_mode: "section-body"` — heading-scoped absorption (Vocabulaire `Valeurs`)

Mirror the script's `extract_section_body` awk function exactly. Stops at the next heading at equal-or-shallower depth, or EOF. The heading line itself is **excluded**.

```bash
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon"
tmp=$(mktemp)
awk -v target="<section_heading>" '
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
' "$VAULT/<vault_path>" > "$tmp"
shasum -a 256 < "$tmp" | awk '{print $1}'
rm -f "$tmp"
```

### Footgun: trailing newline

Bash command substitution `$(…)` strips trailing newlines. If you compute the sha by piping a command-substituted body into `shasum`, the result will mismatch what the script computes (which uses `mktemp`). Always extract to a temp file first — the patterns above already do.

### Footgun: NFC vs NFD on vault paths

The vault uses non-ASCII paths (`99 - Méta/Système documentaire/...`). macOS APFS handles UTF-8 fine, but if you copy-pasted the path from a different source and see `vault-file-missing` on a path that visibly exists, suspect an NFC/NFD mismatch. Re-type the path or copy from `vault-sync.json` directly.

## Heading rename (status: `section-missing`)

The script's section extraction matches by exact heading text. A rename trips `section-missing`.

1. **Confirm the rename** — list current vault headings:

   ```bash
   VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Organon"
   grep -n '^#' "$VAULT/<vault_path>"
   ```

2. **Decide:**
   - **Adopt the rename**: update `section_heading` in `vault-sync.json` to the new heading, then proceed as §Re-sync from step 4.
   - **Reject the rename**: leave `section_heading` unchanged, add a `note` field documenting why. Drift will continue to be reported — that's the cost of divergence. Rare on the vault side: PA owns both ends, so usually fixing the vault is preferable.
   - **Section removed entirely**: evaluate whether the plugin still needs the content. If yes, the absorbed material becomes Organon-owned: remove the `<!-- VAULT-* -->` markers, delete the entry from `vault-sync.json`, restate the content as native plugin convention in the surrounding `SKILL.md` or reference file.

## Divergence (intentional non-absorption)

When a vault edit conflicts with plugin-specific framing, do not absorb. Instead:

1. **Do not change `body_sha256`** — drift remains reported (desired: visible reminder of divergence).
2. **Bump `synced_at_date`** to today — future runs measure drift against the post-decision baseline.
3. **Add `note`** field to the `vault-sync.json` entry: short rationale + decision date.
4. **Commit** with message: `organon: diverge from vault on <entry> — <reason>`.

Vault-side divergence is rare — usually fixing the vault is the right move. If you find yourself diverging more than once a quarter, raise the pattern to PA: the absorbed content's framing prose may need a structural rethink.

## Add a new absorption (not a re-sync; included for symmetry)

When a new vault file or section is worth absorbing:

1. Pick the plugin reference file. Vocabularies typically go in `skills/organon-frontmatter/references/VOCABULARIES.md`; new top-level governance documents go in their own file under `skills/organon-frontmatter/references/`.
2. Insert the marker pair around the absorbed content:

   ```
   <!-- VAULT-BEGIN: <vault-path> [§<heading>] @synced:<date> -->
   <!-- vault-sync: see vault-sync.json for body_sha256 + drift status -->

   [verbatim absorbed content]

   <!-- VAULT-END: <vault-path> [§<heading>] -->
   ```

3. Compute `body_sha256` (§Hash recomputation).
4. Add a new entry to `vault-sync.json` with the right `extract_mode` and `drift_status: "in-sync"`.
5. Update the surrounding `SKILL.md` framing prose if the new content needs a new pointer.
6. Run `./scripts/sync-vault.sh` — confirm `in-sync` for the new entry.
7. Commit: `organon: absorb vault <entry> @<date> into <target>`.
