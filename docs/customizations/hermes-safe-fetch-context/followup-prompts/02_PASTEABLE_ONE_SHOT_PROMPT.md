# Pasteable one-shot prompt for Hermes/GPT-5.5

Use this if you do not want to make Hermes read every prompt file manually.

```text
You are the Hermes/GPT-5.5 orchestrator operating on the local Hermes checkout at ~/.hermes/hermes-agent and the downstream patch-stack repo at $HOME/.config/hermes-agent-patches.

Mission: complete hostile-download prompt-injection containment for Hermes. The hard invariant is: downloaded, retrieved, gateway-supplied, recalled, cron-supplied, skill-supplied, plugin-supplied, @-referenced, or otherwise external content may be evidence, but it must never be sufficient authority for side-effecting tool calls.

Read these existing docs first:
- $HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/INTENT.md
- $HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/IMPLEMENTATION_PLAN.md
- $HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md
- $HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
- $HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
- $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/series

Then execute this plan with fresh subagents for each workstream:

1. Hygiene/patch-stack audit: verify series, patch count, docs consistency, clean apply, and that tools/safe_http.py plus tests/tools/test_safe_http.py are actually carried unless upstream-owned.
2. Security model: create/update SECURITY_MODEL.md stating that provenance/taint and deterministic action-authority gating are mandatory, not optional.
3. Surface reconnaissance: inventory all remote-byte ingress, extraction/cache, context-promotion, and side-effecting action surfaces. Update SURFACE_MAP.md or create HARDENING_SURFACE_INVENTORY.md.
4. Safe-fetch completeness: ensure every relevant remote-byte ingress path uses tools.safe_http or an equivalent documented control with SSRF, redirect, byte-cap, credential, and redaction tests.
5. Artifact provenance/taint: implement first-class provenance for external/fetched/extracted content, preserving redacted URL, final URL, content type, bytes read, sha256, source type, fetch policy, extraction chain, trust level, and authority=none.
6. Context promotion: scan/fence all model-visible external text over the exact promoted text or all promoted chunks. Cover memory system blocks, plugin pre_llm_call, gateway reply/document context, @ file/git/url references, skill content, extracted document/OCR/metadata text, and cron context.
7. Action authority: implement a deterministic gate before side-effecting tools. Side-effecting actions include file write/delete, terminal execution, secret read/transmission, outbound messages, memory/profile writes, cron create/update/delete, skill/plugin install/update/execute, credentialed network calls, config changes, and downloaded code execution. Untrusted content cannot authorize these.
8. Skill/plugin/hub hardening: external/community/plugin skill content is evidence-only unless explicitly trusted by local policy; install/update/execute requires trusted user intent or confirmation.
9. Adversarial validation: add deterministic tests proving hostile content from downloads, gateway attachments, @ references, memory, cron output, skills/plugins, and extraction metadata cannot cause side-effecting tools. Tests must not depend on a live LLM.
10. Patch-stack refresh: regenerate logically owned patches, update series/base.ref/docs, and verify the stack can check-apply in a clean upstream worktree.

Use scripts/run_tests.sh where possible and .venv/bin/python for direct Python. Do not touch unrelated user work. Do not run npm install. Do not commit unless I explicitly ask. Do not pause between slices unless credentials, authorization, a hidden product/security tradeoff, unrelated local work, or an unresolvable test failure requires user intervention.

Final report must include changed files, tests run/results, clean patch-stack apply status, and residual risks.
```
