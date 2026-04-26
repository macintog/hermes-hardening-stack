# Hermes Agent downstream patch stack

This repository lives at `$HOME/.config/hermes-agent-patches` by convention and contains only the downstream patch stack and maintainer documentation for local Hermes Agent customizations.

It intentionally does not vendor, mirror, or fork the Hermes Agent source tree.

Canonical sources for the executable stack:

- `patches/hermes-safe-fetch-context/series` — canonical patch order
- `patches/hermes-safe-fetch-context/manifest.yaml` — canonical machine-readable ownership, phases, and required checks
- `scripts/verify-hermes-safe-fetch-context-stack.sh` — canonical clean-base stack verifier
- `patches/hermes-safe-fetch-context/*.patch` — executable patch payloads
- `docs/customizations/hermes-safe-fetch-context/` — explanatory/maintenance documentation only; do not treat docs as overriding the series, manifest, verifier, or patch files

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
  git apply --3way $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/$patch
done < $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/series
```

See `REBASE_PLAYBOOK.md` for the full maintenance workflow.
