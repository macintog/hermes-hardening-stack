# Intent: hostile-content containment, safe fetch, and action authority

## Problem

Hermes has many fast-moving surfaces that accept external data:
- gateway platforms download images, audio, documents, and attachments from platform-provided URLs
- memory providers, cron scripts, skills, context files, and prompt builders can promote text into model-visible context

Those surfaces are useful, but they create four recurring risks:

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

3. Unsafe action-authority risk
   - hostile evidence from downloads, extraction, memory, cron, skills, plugins, browser pages, OCR/PDF/documents, transcripts, or tool outputs supplies commands, recipients, paths, schedules, selectors, package names, or other concrete side-effect arguments
   - side-effecting tools run without trusted scoped user/system/developer authority
   - unknown or newly registered tools silently behave as side-effecting tools without explicit classification

4. Tool-result taint-loss risk
   - a tool returns hostile text, the model rewrites it into clean-looking arguments, and the later tool call no longer contains literal fence markers
   - model-visible string tool outputs are treated as trusted by default unless a promotion boundary re-tags them as evidence

## Design principles

### Centralize the policy

Policy belongs in reusable modules:
- `tools/safe_http.py` for network fetch validation/downloads
- `agent/context_safety.py` for prompt/context promotion scanning, rendering, and default-untrusted tool-result promotion
- `agent/action_authority.py` for deterministic action classification and evidence-only authority gating

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

For context surfaces that can still be shown safely, render external text as fenced/untrusted data and include safety metadata. For surfaces that are too dangerous, block and return structured findings. Regex detection and textual fences are not the security boundary by themselves; provenance/taint must reach the action-authority gate before side effects.

### Make side effects require trusted scoped authority

Untrusted evidence may inform summaries and analysis, but it cannot authorize tool execution, terminal commands, browser credentialed actions, memory/cron writes, file writes, outbound messages, secret access, skill/plugin execution, config changes, or downstream tool arguments. Unknown side-effect behavior requires confirmation by default and blocks when untrusted evidence is involved.

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
- provenance/taint metadata carried through model-visible tool/evidence promotion
- an explicit action registry with fail-closed unknown side-effect behavior
- deterministic action-authority tests for taint-loss, scoped arguments, browser credentialed actions, skill/plugin execution order, persistence, and outbound side effects

Until then, maintain this as a small downstream patch stack.
