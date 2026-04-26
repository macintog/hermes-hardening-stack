# Intent: hostile-content containment, safe fetch, and action authority

Hermes accepts external data and can perform high-impact local and network actions. This stack prevents attacker-controlled content from becoming action authority.

## Risks addressed

1. Unsafe fetch
   - SSRF through user/platform-provided URLs
   - redirects to private/internal hosts
   - oversized downloads
   - signed URL leakage in logs/errors

2. Unsafe context promotion
   - untrusted text entering prompt-like context as if it were instruction
   - inconsistent ad hoc scanner behavior across call sites
   - missing structured findings/provenance

3. Unsafe action authority
   - hostile evidence supplying commands, paths, URLs, recipients, schedules, selectors, package names, browser actions, or durable-state content
   - side-effecting tools running without trusted scoped user/system/developer authority
   - unknown tools silently behaving as side-effecting tools

4. Tool-result taint loss
   - hostile tool output being rewritten into clean-looking later tool arguments
   - model-visible string tool outputs being treated as trusted by default

## Design principles

### Centralize policy

Policy lives in reusable modules:
- `tools/safe_http.py` for network fetch validation/downloads
- `agent/context_safety.py` for context promotion scanning/rendering and default-untrusted tool-result promotion
- `agent/action_authority.py` for deterministic action classification and evidence-only authority gating

Call sites express local constraints such as byte cap, timeout, required headers, and block/report behavior.

### Validate every redirect

The initial URL is not enough. Every redirect target must be validated before it is followed.

### Treat evidence as data

Untrusted evidence may inform summaries and analysis. It cannot authorize tool execution, terminal commands, browser credentialed actions, memory/cron writes, file writes, outbound messages, secret access, skill/plugin execution, config changes, or concrete downstream tool arguments.

### Fail closed for missing provenance

Missing provenance is evidence-only for side-effect decisions.

### Keep tests close to enforced behavior

Tests should prove the implemented boundaries:
- central safe URL/download behavior
- central context scanning/rendering behavior
- gateway call sites using safe download paths
- prompt/memory/cron/skill callers using shared context handling
- action-authority gates blocking evidence-only side effects
- skill inline shell expansion requiring explicit trusted local authority

## Non-goals

- Do not build a general content moderation system.
- Do not block every possible hostile string in arbitrary read-only inspection.
- Do not remove explicit user ability to run terminal commands, install packages, manage cron, write files, or inspect security payloads.
- Do not trust hosted/vendor extraction, gateway, memory, cron, skill, plugin, or referenced content merely because transport was safe.
- Do not require LLM Guard or any new external scanner dependency.
