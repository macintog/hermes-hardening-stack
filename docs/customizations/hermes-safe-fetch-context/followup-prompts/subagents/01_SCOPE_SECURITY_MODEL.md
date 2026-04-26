# Subagent 01: scope and security model

You are a security architecture subagent. Your task is to turn the audit feedback into a precise security model and definition of done for Hermes hostile-download prompt-injection containment.

## Inputs to read

Read from the patch-stack repo:

```text
docs/customizations/hermes-safe-fetch-context/INTENT.md
docs/customizations/hermes-safe-fetch-context/IMPLEMENTATION_PLAN.md
docs/customizations/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md
docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
```

Read enough Hermes source to understand tool execution, prompt construction, memory, gateway, cron, skill, plugin, and @ context surfaces.

## Main task

Define the hard security invariant for this project:

```text
Downloaded, retrieved, gateway-supplied, recalled, cron-supplied, skill-supplied, plugin-supplied, @-referenced, or otherwise external content may be evidence, but it must never be sufficient authority for side-effecting tool calls.
```

Make artifact provenance/taint propagation and deterministic action-authority gating mandatory. They are not optional follow-up for this threat model.

## Required analysis

Classify the following separately:

1. Network ingress risk:
   - SSRF
   - redirects to private/internal/link-local/metadata targets
   - credential leakage across redirects
   - large download/resource exhaustion
   - signed URL leakage in logs/errors

2. Prompt/context risk:
   - hostile text from downloads or attachments
   - hostile text from extracted document layers, OCR, metadata, annotations, comments, alt text, markdown titles, HTML attributes
   - hostile text from memory, cron output, skill/plugin content, gateway replies, @ references

3. Action-authority risk:
   - tool calls
   - file writes/deletes
   - secret reads/transmission
   - outbound messages
   - installs/updates
   - cron creation/update
   - memory/profile writes
   - credentialed network calls
   - downloaded code execution

## Deliverables

Update or create a document under:

```text
docs/customizations/hermes-safe-fetch-context/SECURITY_MODEL.md
```

The document must include:

- threat model
- trust levels
- security invariants
- non-goals
- definition of done
- mapping from risks to enforcement layers
- explicit statement that prompt fences/scanner findings are defense-in-depth, not the hard boundary
- explicit statement that action-authority gating is required
- explicit statement that provenance/taint must survive fetch, extraction, caching, summarization, context promotion, and tool-call decision

## Acceptance criteria

The final document must be specific enough that implementation subagents can decide whether a call site is safe or unsafe without asking the user. Avoid generic statements like “sanitize inputs.” Use concrete terms such as `trusted_user_intent`, `untrusted_downloaded_text`, `side_effecting_tool`, `credentialed_network_call`, and `evidence_only`.
