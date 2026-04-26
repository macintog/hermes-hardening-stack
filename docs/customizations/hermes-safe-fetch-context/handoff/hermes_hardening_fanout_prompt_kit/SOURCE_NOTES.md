# Source notes captured while preparing this kit

This kit was prepared against the public GitHub repository `macintog/hermes-hardening-stack`.

Observed repository facts:

- The root README describes the repo as a downstream Hermes hardening patch stack and says it intentionally does not vendor, mirror, or fork the Hermes Agent source tree.
- The root README identifies `patches/hermes-safe-fetch-context/` as the executable patch stack and `docs/customizations/hermes-safe-fetch-context/` as the maintainer documentation.
- The current `series` contains five patches, including `0005-tool-result-promotion-action-registry.patch`.
- The current `manifest.yaml` records mandatory phases for context promotion, safe fetch, customization tooling, provenance/action authority, action-authority tests, registry action classification, and tool-result promotion policy.
- The docs README and rebase playbook appeared stale relative to the manifest/series: the README still described a narrower two-intention shape and said current `0002` contains no WeCom diff, while the manifest/surface map include WeCom coverage; the rebase playbook listed and refreshed only through patch `0004` in its refresh section.

Fresh Hermes sessions should re-read the connected GitHub repo rather than relying on these notes if the repo has changed.
