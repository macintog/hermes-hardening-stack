# Review R01 — Security boundary review

You are reviewing whether the final implementation has a real security boundary.

## Review standard

A real boundary is deterministic code at promotion, persistence, and tool dispatch. Textual fences and regex findings are only assistance to the model and routing logic.

## Checklist

- Is untrusted influence tracked structurally or only via text tags?
- Does action authority receive taint state independent of final tool-argument text?
- Does the gate block side effects when a turn is untrusted-influenced and lacks scoped trusted authorization?
- Are unknown/dynamic/plugin tools conservative by default?
- Are tool outputs untrusted by default unless explicitly trusted?
- Are persisted untrusted-derived items recalled as untrusted?
- Are secret-source to outbound-sink workflows controlled beyond simple command-pattern matching?
- Are confirmation grants scoped and resistant to attacker text laundering?

## Output

Return pass/fail/partial for each item, with file/test references and required fixes.
