# Acceptance criteria

A fresh session should not mark the work complete unless all applicable criteria are met or explicitly listed as residual risk.

## Patch-stack and repo criteria

- `series` includes every mandatory patch and remains aligned with `manifest.yaml`.
- `manifest.yaml` records every required phase, owned path, and required test.
- Rebase playbook refresh commands regenerate every patch in `series`.
- Docs do not contradict the manifest or patch contents.
- Verifier checks manifest/series/docs/test-list consistency.
- If CI is added, it runs the verifier or at least the manifest/series/docs drift checks.

## Security criteria

- Non-textual taint or equivalent deterministic state is propagated from untrusted ingress through promotion and into action authorization.
- Tool dispatch does not rely solely on untrusted-context tags in serialized text.
- Unknown side-effecting tools are blocked or require confirmation after untrusted influence.
- Tool output strings are untrusted by default unless explicit trusted metadata says otherwise.
- Persisted untrusted-derived material is recalled as untrusted.
- Skill/plugin load/view/install/execute paths cannot execute or authorize actions merely because hostile content says to do so.
- Inline shell expansion in skill/plugin contexts is disabled, gated, or provenance/authority checked before execution.
- Safe HTTP tests cover private/loopback/link-local/cloud metadata redirects, credentials, byte caps, content type, and proxy/DNS-rebinding assumptions where feasible.
- Parser/extractor paths have limits or documented TODOs with tests when feasible.

## Test criteria

At minimum, tests should cover these attack chains:

1. Hostile PDF/text/webpage asks Hermes to run shell; terminal gate blocks.
2. Hostile download asks Hermes to send secrets; outbound/secret transmission gate blocks.
3. Hostile download supplies a recipient/path/URL argument; side-effecting action requires trusted scoped authorization.
4. Tool result from an unknown extraction-like tool is fenced/tainted by default.
5. Memory item derived from hostile content remains tainted on recall and cannot authorize action.
6. Cron output or scheduled prompt containing hostile instructions remains evidence-only.
7. Skill/plugin content containing hostile instructions cannot install/execute/write memory/send messages without trusted grant.
8. Newly registered tool lacking metadata fails drift check or fails closed for side effects.

## Completion criteria

The final output should include:

- patch files or branch/diff;
- updated docs;
- updated verifier/CI;
- test run output or precise explanation for tests not run;
- residual risk register;
- maintainer commands for rebase and verification.
