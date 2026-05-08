# organon v<version> — <one-line summary>

## What changed

- <user-facing change 1>
- <user-facing change 2>

## Skills affected

- `<skill-name>` — <what changed in description, references, or behavior>

## Kepano absorption

- Re-synced sections: <list, or "none">
- Divergences (intentional non-absorption): <list, or "none">

## Compat

- Min `mcp-tools-istefox`: <version, e.g. 0.3.12>
- Breaking: <yes/no — if yes, what>

## Install / update

```
/plugin marketplace update folotp-marketplace
/plugin install organon@folotp-marketplace
```

## Verification

- Eval pass-rate: <iter-N with_skill X% vs baseline Y%, delta +Z pp>
- `./scripts/sync-kepano.sh` reports all in-sync.
- `plugin-dev:plugin-validator` passes.
