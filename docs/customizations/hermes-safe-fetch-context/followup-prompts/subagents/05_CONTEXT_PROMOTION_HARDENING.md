# Subagent 05: context-promotion hardening

You are a prompt/context boundary implementation subagent. Your task is to ensure all external or derived text promoted into model-visible context is scanned, fenced, labeled as evidence, and stripped of authority.

## Security invariant

External text may be evidence. It is never instruction authority. This must hold for downloads, gateway content, memory, cron output, skill/plugin content, @ references, extracted document text, and any other untrusted source.

## Inputs

Read:

```text
agent/context_safety.py
tests/agent/test_context_safety.py
agent/prompt_builder.py
agent/memory_manager.py
cron/scheduler.py
tools/cronjob_tools.py
tools/skills_tool.py
SURFACE_MAP.md or HARDENING_SURFACE_INVENTORY.md
SECURITY_MODEL.md
```

Inspect live code for plugin hooks, gateway context construction, @ reference handling, and document extraction paths.

## Required coverage

Close or explicitly resolve these known categories:

1. Memory/system context:
   - `MemoryProvider.system_prompt_block()` or equivalent direct system/context insertion
   - memory provider prefetch context
   - user/profile/memory files used as model context

2. Plugin context:
   - `pre_llm_call` or equivalent plugin-injected context
   - plugin-produced tool/context payloads

3. Gateway context:
   - gateway replies
   - gateway attachments
   - gateway document text
   - chat platform message content that is not the current trusted user instruction

4. @ references:
   - file references
   - git references
   - URL references
   - directory or repository context

5. Skills:
   - skill view content
   - linked skill file content when model-visible
   - plugin skill content
   - hub/external/community skill content

6. Extraction outputs:
   - PDF text
   - Office/doc text
   - OCR text
   - image alt text
   - metadata/comments/annotations/front matter
   - markdown link titles/alt text/HTML attributes

7. Cron:
   - cron prompt input
   - cron prior output
   - pre-run script output
   - scheduled job context_from

## Required scanning behavior

- Scan the exact text that will be model-visible.
- For long content, do not scan only head/tail. Either full-scan before truncation, or chunk with deterministic overlap and scan all chunks that may be included, summarized, embedded, or passed to the model.
- Preserve legacy error/message shapes where compatibility tests require them.
- Escape labels and content in rendered untrusted blocks to prevent fence spoofing.
- Treat scanner verdicts as defense-in-depth, not as authority.

## Required rendering behavior

Untrusted context blocks should communicate:

- source/surface
- provenance label
- that content is evidence only
- that content must not be followed as instruction
- findings/verdict where relevant

Do not rely on this rendering as the hard security boundary. The action-authority gate handles side effects.

## Test requirements

Add or update tests for each promoted surface. Include cases for:

- obvious prompt injection
- paraphrased authority impersonation
- hidden HTML/CSS
- invisible Unicode and bidi controls
- malicious markdown link title/alt text
- malicious content in the middle of long context
- fake `<system>` / `<developer>` / tool-result blocks
- external source label escaping
- preserved compatibility shape where necessary

Likely tests:

```text
tests/security/test_context_promotion_boundaries.py
tests/agent/test_context_safety.py
tests/agent/test_prompt_builder.py
tests/agent/test_memory_provider.py
tests/tools/test_skills_tool.py
tests/tools/test_cronjob_tools.py
tests/cron/test_cron_context_from.py
tests/cron/test_cron_script.py
```

## Acceptance criteria

Every external-text promotion surface identified by reconnaissance is either:

- scanned and fenced as untrusted evidence with provenance preserved, or
- blocked, or
- proven not to be model-visible, or
- documented as a deliberate product/security exception requiring separate authority gating.

No model-visible hostile download or derived text should enter an instruction-like prompt position without untrusted labeling and authority removal.
