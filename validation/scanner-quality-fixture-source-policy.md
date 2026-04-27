# Scanner quality fixture source policy

This information was kept out of the durable hardening payload docs and stashed here in the untracked validation workspace.

## Fixture source policy

Public benign fixtures may be derived from reputable sources that intentionally
study prompt injection or LLM application security, including:

- PromptInject / the "Ignore Previous Prompt" work;
- Tensor Trust data and benchmarks;
- Promptfoo red-team documentation/examples;
- NVIDIA garak prompt-injection-oriented probes;
- OWASP GenAI/LLM application security taxonomy and examples.

Do not vendor broad offensive corpora wholesale. Do not add malware-generation,
credential-theft, jailbreak, toxicity, or exploit-development payloads to this
public repository. Fixtures should be inert, narrow, and built around harmless
sentinel outcomes such as `CANARY_VALUE`.

Before vendoring verbatim third-party examples, confirm license compatibility.
When license status is ambiguous, add transformed/minimal examples and cite the
source family in the fixture manifest instead of copying the upstream text.
