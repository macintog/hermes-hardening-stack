# Subagent S01 — Threat model and security invariants

## Role

You are the threat-model subagent. Your job is to convert the high-level goal into enforceable security invariants and acceptance tests.

## Goal

Prevent hostile downloaded or tool-derived content from obtaining authority in Hermes. The model may read hostile content as evidence, but hostile content must not authorize actions.

## Tasks

1. Enumerate untrusted sources:
   - URL downloads;
   - gateway attachments and media;
   - web/browser/search/extract outputs;
   - OCR/PDF/document/transcript/archive extraction;
   - plugin pre-LLM context and tool output;
   - skill/community/hub/plugin content;
   - memory and cron recall/output;
   - external API text;
   - user-pasted content that is explicitly described as untrusted evidence.
2. Enumerate protected sinks:
   - terminal/code execution;
   - file writes/deletes/config changes;
   - outbound messages/posts/uploads;
   - credentialed browser/network/API actions;
   - secret reads and secret transmission;
   - memory writes;
   - cron changes;
   - skill/plugin install/update/enable/execute;
   - downloaded-code execution.
3. Define required invariants and map each to code gates.
4. Define a minimum adversarial test suite. Each test should identify source, sink, expected gate, and expected result.
5. Identify which current patch phases already support each invariant and which are missing.

## Non-goals

- Do not rely on pattern matching as the security boundary.
- Do not claim prompt injection is eliminated. Frame the property as authority containment.

## Output contract

Return:

- threat model table: source → promotion path → protected sink → gate;
- invariant list with pass/fail/partial assessment;
- required test names and concise descriptions;
- top five implementation requirements.
