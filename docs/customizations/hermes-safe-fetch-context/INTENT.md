# Intent: safe fetch and context safety

## Problem

Hermes has many fast-moving surfaces that accept external data:
- gateway platforms download images, audio, documents, and attachments from platform-provided URLs
- memory providers, cron scripts, skills, context files, and prompt builders can promote text into model-visible context

Those surfaces are useful, but they create two recurring risks:

1. Unsafe fetch risk
   - SSRF through user/platform-provided URLs
   - redirects from benign-looking URLs to private/internal hosts
   - large downloads exhausting memory/disk
   - sensitive signed URLs leaking into logs

2. Unsafe context promotion risk
   - untrusted text becomes privileged instruction-like prompt context
   - different callers invent inconsistent injection scans
   - warnings/blocks lack structured evidence
   - future maintainers cannot tell which surfaces are intended to be guarded

## Design principles

### Centralize the policy

Policy belongs in reusable modules:
- `tools/safe_http.py` for network fetch validation/downloads
- `agent/context_safety.py` for prompt/context promotion scanning and rendering

Call sites should mostly express local constraints:
- allowed schemes
- timeout
- byte cap
- required headers
- whether a finding blocks, warns, or gets reported

### Validate redirects, not just initial URLs

The initial URL is not enough. Every redirect target must be validated before it is followed.

### Byte caps are caller-owned

The central downloader enforces caps, but each caller chooses the cap based on product behavior:
- small media cache cap for image/audio previews
- larger cap for attachments/documents where already supported

Avoid a single global cap that silently changes platform behavior.

### Redact URLs at logging boundaries

Platform CDNs and signed URLs can contain tokens. Logs should describe the failure without preserving sensitive query material.

### Treat suspicious context as data

For context surfaces that can still be shown safely, render external text as fenced/untrusted data and include safety metadata. For surfaces that are too dangerous, block and return structured findings.

### Keep tests close to surfaces

Tests should cover both central policy and caller integration:
- central safe URL/download behavior
- central context scanning behavior
- gateway call sites using the safe downloader
- prompt/memory/cron/skill callers using the shared scanner

## Non-goals

- Do not create a general content moderation system.
- Do not block every possible hostile string in arbitrary file reads.
- Do not rewrite Hermes architecture broadly.
- Do not remove platform-specific auth/header behavior needed to download legitimate platform files.
- Do not mirror all Hermes source into a customization repo as the long-term maintenance mechanism.

## Desired future upstream state

If upstream Hermes accepts this direction, the ideal end state is:
- shared safe HTTP utility in Hermes proper
- shared context safety scanner in Hermes proper
- platform adapters migrated opportunistically as they change
- skill/memory/cron/prompt surfaces reporting structured context-safety results

Until then, maintain this as a small downstream patch stack.
