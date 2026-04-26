# Hermes Agent downstream hardening stack

This repository contains the downstream Hermes Agent hardening patch stack.

It does not vendor, mirror, or fork Hermes Agent source.

Executable sources:

- `patches/hermes-safe-fetch-context/series` — patch order
- `patches/hermes-safe-fetch-context/*.patch` — patch payloads
- `patches/hermes-safe-fetch-context/base.ref` — recorded upstream base
- `patches/hermes-safe-fetch-context/manifest.yaml` — paths/tests owned by the stack
- `scripts/verify-hermes-safe-fetch-context-stack.sh` — clean-base apply/test verifier

Human docs:

- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/INTENT.md`
- `docs/customizations/hermes-safe-fetch-context/SECURITY_MODEL.md`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`

Basic apply flow from a clean Hermes checkout:

```bash
while read -r patch; do
  [ -z "$patch" ] && continue
  git apply --3way $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/$patch
done < $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/series
```
