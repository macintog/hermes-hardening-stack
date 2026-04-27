# Hermes Agent hostile-content hardening payload

This repository packages downstream Hermes Agent changes that prevent prompt-injection text in external content from authorizing tool calls or changing what the agent is allowed to do.

The payload hardens three connected boundaries:

- safe fetch: validate user/platform-provided URLs, redirects, byte caps, credential redirects, and URL redaction
- context promotion: render downloaded, recalled, cron, skill, gateway, browser, and tool-result text as evidence with provenance
- action authority: require trusted scoped user/system/developer intent before side-effecting tools can write files, run commands, send messages, persist memory/cron state, use credentials, or act in a browser

It is a patch payload for a clean Hermes Agent checkout. It does not vendor, mirror, or fork Hermes Agent source.

Main is the sole source of truth. The repository does not preserve iteration history, compatibility shims, or prior patch shapes. Git history is the only place to inspect older states.

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
