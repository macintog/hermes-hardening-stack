# Public validation lane

This directory holds no-login validation material for Hermes hostile-content hardening. It is intentionally separate from the executable patch payload under `patches/hermes-safe-fetch-context/`.

## Purpose

Use public, benign, inert examples to verify that browser, web, media, extraction, and skill-content paths treat external content as evidence, not authority.

Core invariant:

> Public/tool-sourced content may be read, quoted, summarized, or classified as evidence. It must not change the trusted task, authorize a tool action, reveal system/developer context, write memory, write files, send messages, execute commands, or mark the task complete.

## Current role

Keep this folder focused on:

- validation harnesses that run against an applied patched Hermes worktree
- public no-login target/source inventories
- fixture schemas and inert seed fixtures
- dated run evidence under `runs/`

Do not use this folder as a rolling checkpoint or diary. Current execution focus belongs in `../CHECKPOINT.md`; unresolved hardening follow-ups belong in `../docs/customizations/hermes-safe-fetch-context/OPEN_HARDENING_BACKLOG.md`.

## Files

- `ONLINE_TOOL_PATH_TEST_OUTLINE.md`: no-login tool-path outline and guardrails.
- `docker-upstream-methodology.md`: Docker upstream qualification method for exact clean-versus-patched breakage inventory.
- `regression-triage/`: durable queue, rubric, status, and maintainer-rationale lane for patched-only upstream test regressions.
- `sources.md`: public source families and fixture usage policy.
- `targets.md`: stable public URLs for browser/web validation.
- `test-matrix.md`: matrix from Hermes paths to fixture families and expected behavior.
- `fixtures/fixture-schema.json`: JSON schema for curated fixtures.
- `fixtures/seed-fixtures.jsonl`: inert seed examples.
- `fixtures/tui-redteam/`: synthetic inert RT01-RT10 fixtures for direct stock-vs-patched Hermes TUI red-team checks.
- `scripts/run_public_sample_prompt_checks.py`: deterministic prompt/context checks against public samples plus low-friction UX authority regressions.
- `runs/`: dated browser smoke and public-sample prompt-check evidence.

## How to run public-sample checks

The full payload verifier runs these checks automatically. For focused reruns, run against an intentionally kept applied Hermes worktree, not against this payload repo:

```bash
<hermes-python> \
  validation/scripts/run_public_sample_prompt_checks.py \
  --worktree <kept-worktree-path> \
  --out /tmp/hermes-public-sample-checks.json
```

Remove the kept verifier worktree after the focused evidence is captured:

```bash
./scripts/cleanup-hermes-verifier-worktrees --remove --force
```

The report includes `results` for public prompt-injection samples and `ux_regressions` for deterministic authority checks covering common allowed workflows and evidence-derived negative cases.

## Guardrails

- Prefer Chrome/browser-driven discovery during research.
- Avoid paid/API-backed web search or extraction unless explicitly authorized.
- Do not operate logged-in/private pages.
- Do not submit forms, close tabs, or perform browser side effects unless explicitly asked.
- Do not use account-backed integrations in first-pass public validation.
- Do not add malware-generation, credential-theft, jailbreak, toxicity, or exploit-development fixture corpora.
- Prefer transformed/minimal examples with source-family attribution unless license compatibility is clear.
