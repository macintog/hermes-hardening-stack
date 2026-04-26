# Hermes safe fetch + context safety hardening

This directory documents the implementation carried by the patch stack in:

- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/*.patch`
- `scripts/verify-hermes-safe-fetch-context-stack.sh`

The implementation has four current invariants.

## 1. Safe HTTP download boundary

Remote byte ingress must go through a reviewed safe-fetch path or an equivalent call-site policy.

Required behavior:
- validate initial URL before fetch
- validate every redirect before following it
- block private, loopback, link-local, metadata, and malformed targets
- enforce caller-owned byte caps
- prevent credential/header leakage on unsafe redirects
- redact signed URLs, credentials, cookies, tokens, and raw query material in logs/errors

## 2. Context safety boundary

Text promoted from external, recalled, cron, skill, gateway, browser, extraction, or tool-result surfaces is evidence, not authority.

Required behavior:
- scan/render promoted risky text through shared context-safety helpers
- preserve structured findings and provenance labels
- escape spoofed fences/markup
- default model-visible string tool results to untrusted evidence unless explicitly exempted as trusted internal control output

## 3. Artifact provenance and action authority boundary

Side effects require trusted scoped authority.

Required behavior:
- preserve evidence-only taint across fetch, extraction, cache/temp artifacts, summaries, prompt promotion, and tool decisions
- block evidence-only attempts to authorize file writes, terminal execution, secret reads/transmission, outbound messages, memory/cron writes, skill/plugin execution, browser credentialed actions, config changes, and unknown side effects
- treat missing provenance as evidence-only for side-effect decisions

## 4. Skill load execution boundary

Skill text without explicit trusted local authority is evidence-only.

Required behavior:
- missing `loaded_skill["authority"]` defaults to evidence-only/untrusted
- inline shell expansion runs only for explicit `trusted_by_local_policy`
- external/community/plugin/unknown skill content must be fenced/rendered as data before it can influence action decisions

## Mechanical maintenance

The numbered patch files are mechanical layers. They are not a project history.

When refreshing the stack, do not generate a later patch from a base-to-tip diff if it shares paths with an earlier patch. Use per-layer commits/refs and diff each layer against the previous layer.
