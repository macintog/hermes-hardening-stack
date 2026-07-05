# Hermes safe fetch + context safety hardening

This directory documents the current hardening payload in:

- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/*.patch`
- `scripts/verify-hermes-safe-fetch-context-payload.sh`

Related docs:

- `EVIDENCE_LEDGER_ADOPTION.md` — completed evidence-ledger adoption decisions, implemented surface coverage, and retained image/media validation guidance.
- `OPEN_HARDENING_BACKLOG.md` — current unresolved follow-up work distilled from the pre-continuity audit and later local-work changes.
- `SECURITY_MODEL.md` — hostile-content threat model and invariants.
- `SURFACE_MAP.md` and `HARDENING_SURFACE_INVENTORY.md` — covered surfaces and rebase audit map.

## Review scope

This payload documents the current hardening behavior and verification entry points. The primary verifier parses `manifest.yaml`, applies the `series` fragments to a temporary Hermes worktree, runs every manifest `payload.required_tests` target, and runs the public-sample prompt-injection checks unless `--apply-only` is selected.

This public tree intentionally excludes local QA event stores, raw Docker logs, regression-triage internals, and security-finding scratch records. `OPEN_HARDENING_BACKLOG.md` is the public summary of durable follow-up status.

Verifier-applied Hermes worktrees are temporary proof surfaces. Keep one only for active inspection, then remove it with `scripts/cleanup-hermes-verifier-worktrees --remove --force` after logs, summaries, QA records, or the patch repo commit preserve the evidence.

Payload fragments represent final-state deltas by target file. A fragment may cover an atomic target group only when splitting it would make the payload incoherent; otherwise use one target file per patch.

## Current invariants

### 1. Safe HTTP download boundary

Remote byte ingress must go through a reviewed safe-fetch path or an equivalent call-site policy.

Required behavior:
- validate initial URL before fetch
- validate every redirect before following it
- block private, loopback, link-local, metadata, and malformed targets
- enforce caller-owned byte caps
- prevent credential/header leakage on unsafe redirects
- redact signed URLs, credentials, cookies, tokens, and raw query material in logs/errors

### 2. Context safety boundary

Text promoted from external, recalled, cron, skill, gateway, browser, extraction, or tool-result surfaces is evidence, not authority.

Required behavior:
- scan/render promoted risky text through shared context-safety helpers
- preserve structured findings and provenance labels
- escape spoofed fences/markup
- default model-visible string tool results to untrusted evidence unless explicitly exempted as trusted internal control output

### 3. Artifact provenance and action authority boundary

Side effects require trusted scoped authority.

Required behavior:
- preserve or re-establish evidence-only provenance across fetch, extraction, cache/temp artifacts, summaries, prompt promotion, and tool decisions
- block evidence-only attempts to authorize file writes, terminal execution, secret reads/transmission, outbound messages, memory/cron writes, skill/plugin execution, browser credentialed actions, config changes, and unknown side effects
- treat missing provenance as evidence-only for side-effect decisions

The action path is a three-layer funnel:

1. Provenance gate: classify content origin before it enters model-visible context. Trusted local skills and internal control output can carry trusted local policy. External, recalled, gateway, browser, extraction, and unknown-origin text remains evidence-only.
2. Promotion gate: render evidence-only content through context-safety fences. Do not fence trusted local skill/control output, and do not treat documented fence examples inside that trusted JSON as live taint.
3. Action-authority gate: evaluate proposed side effects using trusted user intent plus trusted local policy context as authority, while prior evidence-only context remains a blocking or confirmation signal. Routine safe repo work can pass through `trusted_local_work`; network, sudo, secrets, publish, destructive commands, and untrusted-parameterized targets still fail closed.

### Terminal command scanning and Tirith

Tirith is a terminal command-content scanner, not the hostile-content authority boundary. After a terminal action is otherwise authorized, upstream Hermes can scan the concrete command string for risks such as homoglyph URLs, `curl | sh`, terminal/Unicode injection, suspicious exfiltration, and supply-chain patterns. This is useful defense in depth, but it cannot decide whether a command came from trusted user intent or from evidence-only text.

This payload keeps provenance and action authority as the source of truth: evidence-only content cannot authorize terminal execution or supply concrete command targets. Do not rely on Tirith for non-terminal tools, model-visible context promotion, safe fetching, yolo/approvals-off behavior, fail-open scanner outages, container backends, or non-interactive paths where upstream command guards may be skipped.

### 4. Skill load execution boundary

Skill text without explicit trusted local authority is evidence-only.

Required behavior:
- missing `loaded_skill["authority"]` defaults to evidence-only/untrusted
- inline shell expansion runs only for explicit `trusted_by_local_policy`
- external/community/plugin/unknown skill content must be fenced/rendered as data before it can influence action decisions

## Development authority lease

The payload includes an explicit development-only lease so hardening work can continue without weakening production behavior. It is disabled unless `HERMES_DEV_AUTHORITY=1` and `HERMES_DEV_AUTHORITY_ROOT` names an absolute existing scoped repository root. The root must either be a marked Hermes hardening payload repo containing `AGENTS.md` and `patches/hermes-safe-fetch-context/manifest.yaml`, or sit under an absolute existing `HERMES_DEV_AUTHORITY_SAFE_ROOT`. Generic roots, filesystem roots, missing paths, relative paths, malformed enable values, and out-of-safe-root values are ignored.

Recommended local invocation:

```bash
HERMES_DEV_AUTHORITY=1 \
HERMES_DEV_AUTHORITY_ROOT=<patch-repo> \
HERMES_DEV_AUTHORITY_TMP_PREFIX=/tmp/hermes-dev- \
HERMES_DEV_AUTHORITY_ALLOW_COMMIT=0 \
HERMES_DEV_AUTHORITY_ALLOW_NETWORK=0 \
HERMES_DEV_AUTHORITY_ALLOW_SUDO=0 \
hermes --yolo chat \
  --toolsets terminal,file,todo,skills,delegation \
  -q 'Development authority lease:
Work only in <patch-repo>.
You are authorized to run repo-local terminal commands, read files, edit files, patch files, create temporary files, and run tests only for this repository and verifier-created temp worktrees.
Do not push. Do not commit. Do not tag. Do not use sudo. Do not perform network fetches. Do not modify files outside the repo except /tmp/hermes-dev-* or verifier-created temp worktrees. Preserve unrelated work.
Continue the hardening work and report when finished or intractably blocked.'
```

The lease allows local inspection, repo-scoped edits, local tests, and verifier temp worktrees under `/tmp/hermes-safe-fetch-context-verify-*` or a scoped `HERMES_DEV_AUTHORITY_TMP_PREFIX`. A custom temp prefix must be absolute, live under a real system temp parent, and use a `hermes-dev-` basename prefix. It still denies push, tag, reset/clean, sudo, network commands, environment dumps, secret-like paths, broad/generic roots, broad temp prefixes, and actions parameterized by evidence-only untrusted content. Untrusted prompt/content text cannot enable or reconfigure the lease; only the process environment is consulted. Remove the `DevelopmentAuthority` block and `tests/security/test_development_authority.py` before shipping this payload as production hardening, unless maintainers explicitly sign off on retaining it as local-only development tooling.
