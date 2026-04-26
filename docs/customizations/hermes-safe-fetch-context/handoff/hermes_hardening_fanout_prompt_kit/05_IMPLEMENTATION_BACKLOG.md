# Prioritized implementation backlog

## P0: controls required for credible containment

1. Structured turn taint
   - Add a structured `TaintState` / `ContextAuthorityState` / equivalent object that records whether untrusted content influenced the current turn.
   - Feed this into action-authority evaluation.
   - Do not rely only on serialized `<untrusted-context>` tags.

2. Scoped authorization grants
   - Add a representation for trusted scoped user authorization.
   - Bind grants to tool/action class, target/path/recipient/origin, single-use/session scope, and whether untrusted-derived parameters are permitted.

3. Tool security metadata
   - Require every registered tool to declare action class and output trust.
   - Unknown side effects fail closed after untrusted influence.
   - Add a verifier/test that catches missing metadata.

4. Default-taint tool result promotion
   - All model-visible string outputs from tools are untrusted by default.
   - Exempt only explicitly trusted internal control outputs.

5. Durable taint for persistence
   - Memory, cron, notes, skills, plugin state, and generated files derived from untrusted content must preserve provenance.
   - Recalled persisted text is evidence-only.

6. Skill/plugin execution review
   - Ensure skill/plugin content cannot execute inline shell or authorize tool use before provenance/authority checks.

7. Adversarial E2E tests
   - Add deterministic tests where hostile downloads attempt RCE, exfiltration, outbound messages, memory poisoning, cron persistence, browser credentialed actions, and skill/plugin installation.

8. Docs/playbook/verifier drift hardening
   - Fix the five-patch documentation drift and WeCom contradiction.
   - Add drift checks so this class of issue recurs less easily.

## P1: important depth hardening

1. Safe HTTP DNS/proxy/connection-time assurance
   - Clarify and test DNS rebinding assumptions.
   - Block link-local, loopback, private, cloud metadata, IPv6 equivalents.
   - Confirm proxy environment variables cannot bypass policy.

2. Parser/extractor limits
   - Apply max extracted text length, page count, file count, decompression ratio, archive traversal protection, and timeouts where practical.

3. Browser and credentialed network distinctions
   - Distinguish unauthenticated public fetches from credentialed browser/API calls.
   - Add origin/credential handling tests.

4. Secret-source to outbound-sink policy
   - Avoid command-pattern exfil detection as the main boundary.
   - Block workflows that combine secret-bearing sources and outbound sinks under untrusted influence unless explicitly authorized.

## P2: maintainability and ergonomics

1. Better verification logs with path redaction and warning summaries.
2. Human-readable hardening surface inventory generated from manifest.
3. Regression-test matrix documentation.
4. More explicit user confirmation UX templates.
