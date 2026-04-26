# Hermes Agent downstream patch stack

This repository contains only the downstream patch stack and maintainer documentation for local Hermes Agent customizations.

It intentionally does not vendor, mirror, or fork the Hermes Agent source tree.

Canonical contents:

- `patches/hermes-safe-fetch-context/` — executable patch stack
- `docs/customizations/hermes-safe-fetch-context/` — intent, surface map, rebase playbook, and handoff docs

Start here:

1. `docs/customizations/hermes-safe-fetch-context/README.md`
2. `docs/customizations/hermes-safe-fetch-context/INTENT.md`
3. `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
4. `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`
5. `patches/hermes-safe-fetch-context/series`

Basic apply flow from a clean Hermes checkout:

```bash
while read -r patch; do
  [ -z "$patch" ] && continue
  git apply --3way /path/to/hermes-agent-patches/patches/hermes-safe-fetch-context/$patch
done < /path/to/hermes-agent-patches/patches/hermes-safe-fetch-context/series
```

See `REBASE_PLAYBOOK.md` for the full maintenance workflow.
