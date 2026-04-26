# Final handoff prompt template

Use my connected GitHub repository `macintog/hermes-hardening-stack` as source of truth. The current verified patch series is:

<series>

The hardening objective is hostile-content containment: external/downloaded/extracted/tool-derived content is evidence, not authority. Preserve the following mandatory invariants:

<invariants>

Before changing the stack, read `series`, `manifest.yaml`, `REBASE_PLAYBOOK.md`, `SURFACE_MAP.md`, and the verifier script. Do not drop any mandatory patch. Run the verifier after changes.

Current residual risks:

<risk register summary>
