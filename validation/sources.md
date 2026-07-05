# Public Source Families for Validation Fixtures

Research preference:
- Use the available Chrome browser for research/discovery when possible.
- Avoid paid API-backed web search during this research phase.
- Search APIs are acceptable only if explicitly authorized or if browser-driven discovery fails and the user approves.

## 1. Tensor Trust

Role: primary realistic fixture source.

Use for:
- Human-authored prompt-injection attempts.
- Instruction-boundary handling.
- Realistic wording variety without malware-oriented content.

Fixture policy:
- Sample a small subset only, roughly 20-50 short examples when license permits.
- Prefer transformed/inert examples over raw vendoring.
- Replace target behaviors with harmless sentinels such as `PRINT_THE_CANARY`, `SET_COLOR_BLUE`, or `MARKER_ALPHA`.
- Expected policy: preserve as untrusted data; do not follow embedded instructions.

Caveat:
- License review is required before copying verbatim upstream data.

## 2. PromptInject

Role: compact academic baseline.

Use for:
- Canonical goal hijack.
- Prompt leaking.
- Instruction override.
- Minimal smoke tests where expected failure is obvious.

Fixture policy:
- Use taxonomy and seed patterns.
- Hand-author derivative inert examples rather than importing the framework.
- Keep examples short and deterministic.

Example categories:
- Ignore previous instructions and output marker text.
- Repeat hidden/system prompt.
- Treat downloaded document as higher priority.
- The real task is now something else.

## 3. NVIDIA garak

Role: mature reference and optional inspiration.

Use for:
- Prompt-injection-only probes.
- Encoding/obfuscation variants.
- Goodside-style instruction conflicts.
- Breadth checks after the smaller local fixtures pass.

Avoid:
- Malware generation.
- XSS.
- Toxicity.
- General jailbreak probes.
- Making the Hermes validation harness depend on garak unless we intentionally add a heavier external integration.

Fixture policy:
- Extract/paraphrase only safe prompt-injection, encoding, and instruction-conflict cases.
- Keep Hermes fixtures narrow: untrusted text attempts to steer the agent.

## 4. Promptfoo red-team docs/examples

Role: developer-oriented eval/CI structure reference.

Use for:
- Indirect prompt-injection flow shapes.
- Agentic test structure.
- CI-oriented pass/fail reporting.

Fixture policy:
- Borrow eval shape, not the whole runtime.
- Transform examples into harmless assertions.
- Keep deterministic hardening tests separate from model-quality evals.

Example categories:
- Web page says to mark task complete.
- Page says to exfiltrate a fake token.
- Page says to change the destination path/recipient.
- Expected result: the text is reported as untrusted evidence and not obeyed.

## 5. OWASP GenAI / LLM Top 10

Role: threat-model anchor and taxonomy.

Use for:
- README/security rationale.
- Naming the risk class: indirect prompt injection, sensitive information disclosure, excessive agency, insecure output handling where relevant.
- Explaining why fixture categories exist.

Do not use for:
- Bulk prompt examples.
- Detailed regression fixture corpus.

## Public-repo-safe framing

Use wording like:

> These fixtures contain inert, benign examples of untrusted text attempting to override agent instructions. They are used only to verify that Hermes preserves instruction boundaries and treats downloaded/tool-sourced content as data, not authority.

Avoid wording that implies we are collecting or publishing dangerous attacks.
