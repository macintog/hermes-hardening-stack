# Review R02 — Regression test review

You are reviewing whether tests prove the intended security properties.

## Checklist

- Do tests assert deterministic gate outcomes, not merely model refusals?
- Is there a paraphrased attack with no literal untrusted tag in final tool args?
- Is there an unknown tool-output promotion test?
- Is there a structured taint propagation test?
- Is there a persistence taint test?
- Is there a skill/plugin execution-before-fencing test?
- Is there a hostile cron/memory recall test?
- Is there a safe HTTP redirect/private/cloud metadata/credential test?
- Is there an allowed case with scoped trusted authorization?
- Are tests included in manifest and verifier?

## Output

Return missing test coverage, redundant tests, and exact additions needed.
