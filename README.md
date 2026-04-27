# Hermes Agent downstream hardening payload

This repository contains the downstream Hermes Agent hardening payload applied on top of a clean Hermes Agent install.

Main is the sole source of truth. The repository does not preserve iteration history, compatibility shims, or prior patch shapes. Git history is the only place to inspect older states.

It does not vendor, mirror, or fork Hermes Agent source.

Executable sources:

- `patches/hermes-safe-fetch-context/series` — apply order for final-state payload fragments
- `patches/hermes-safe-fetch-context/*.patch` — final-state deltas, one target file per fragment unless explicitly documented as an atomic group
- `patches/hermes-safe-fetch-context/base.ref` — recorded upstream base
- `patches/hermes-safe-fetch-context/manifest.yaml` — paths/tests covered by the hardening payload
- `scripts/verify-hermes-safe-fetch-context-payload.sh` — clean-base apply/test verifier

Human docs:

- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/INTENT.md`
- `docs/customizations/hermes-safe-fetch-context/SECURITY_MODEL.md`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`

Basic apply flow from a clean Hermes checkout:

```bash
while read -r fragment; do
  [ -z "$fragment" ] && continue
  git apply --3way $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/$fragment
done < $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/series
```
