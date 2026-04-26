# Hermes Safe Fetch + Context Promotion Delegation Matrix

This file captures the recommended subagent split for the master thread.

Source docs:
- Recommendation: `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- Master thread prompt: `/Users/ryand/playground/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md`
- Prompt files: `/Users/ryand/playground/hermes-safe-fetch-context/subagents/`
- Prior related project: `/Users/ryand/playground/hermes-content-safety/`

## Track A: Plan and task graph
Prompt file: `subagents/01-plan-and-task-graph.md`
Goal: Convert the recommendation into an execution graph with ordered tasks and dependencies.
Outputs:
- concise task list
- dependencies
- exact files likely touched
- implementation phases
- smallest safe first slice
- likely test commands

## Track B: Fetch surface reconnaissance
Prompt file: `subagents/02-fetch-surface-recon.md`
Goal: Inspect Hermes for remote fetch/download surfaces and identify the safest first migration target.
Outputs:
- list of fetch surfaces by risk
- exact file paths/functions
- which already use `is_safe_url`
- which lack redirect revalidation or byte caps
- recommended first caller to migrate

## Track C: Context promotion reconnaissance
Prompt file: `subagents/03-context-promotion-recon.md`
Goal: Inspect prompt-context promotion surfaces and existing content-safety/fencing behavior.
Outputs:
- exact promotion surfaces
- existing scanner/fence modules
- gaps in cron/memory/skill/gateway context promotion
- recommended first context-safety slice

## Track D: Test inventory
Prompt file: `subagents/04-test-inventory.md`
Goal: Identify existing test patterns and best locations for safe_http/context_safety tests.
Outputs:
- current relevant test files
- canonical test runner commands
- mock HTTP strategies already used in repo
- smallest test files to create/modify
- import/dependency pitfalls

## Track E: Safe HTTP design spec
Prompt file: `subagents/05-safe-http-design-spec.md`
Goal: Produce a concrete API and test plan for `tools/safe_http.py`.
Outputs:
- proposed dataclasses/exceptions/functions
- redirect and credential-bound behavior
- byte/content-type handling
- exact first tests
- compatibility constraints for callers

## Track F: Safe HTTP implementation slice
Prompt file: `subagents/06-implement-safe-http-slice.md`
Goal: Implement `tools/safe_http.py` and targeted tests after Track E is approved.
Outputs:
- `tools/safe_http.py`
- `tests/tools/test_safe_http.py`
- passing targeted tests
- no caller migrations unless explicitly included

## Track G: One fetch caller migration
Prompt file: `subagents/07-migrate-one-fetch-caller.md`
Goal: Migrate exactly one remote-download caller to `safe_http` with tests.
Outputs:
- one caller updated, preferably WeCom or Feishu based on recon
- targeted regression tests
- caller-facing behavior unchanged
- redirect/private-target behavior covered

## Track H: Context safety design spec
Prompt file: `subagents/08-context-safety-design-spec.md`
Goal: Design `agent/context_safety.py` as a higher-level promotion/fencing wrapper informed by the prior content-safety work.
Outputs:
- proposed source surfaces/verdicts
- API shape
- fence format
- integration points
- first test set

## Track I: Context safety implementation slice
Prompt file: `subagents/09-implement-context-safety-slice.md`
Goal: Implement the first `agent/context_safety.py` slice and wire one low-risk promotion surface if approved.
Outputs:
- `agent/context_safety.py`
- tests
- optional one-surface wiring, preserving existing behavior

## Track J: Security/spec review
Prompt file: `subagents/10-security-spec-review.md`
Goal: Review implemented changes for SSRF bypasses, prompt-injection risks, false positives, and spec compliance.
Outputs:
- PASS/REQUEST_CHANGES
- specific security issues
- false-positive concerns
- missing tests

## Track K: Code quality/regression review
Prompt file: `subagents/11-code-quality-regression-review.md`
Goal: Review implementation quality, maintainability, and regression risk.
Outputs:
- APPROVED/REQUEST_CHANGES
- code quality issues
- compatibility concerns
- recommended test commands

## Recommended orchestration

First wave, parallel:
1. Track A: plan/task graph
2. Track B: fetch surface recon
3. Track C: context promotion recon
4. Track D: test inventory

Then synthesize:
5. Write/update `IMPLEMENTATION_PLAN.md` from the first wave.

Safe-fetch implementation wave:
6. Track E: safe HTTP design spec
7. Track F: safe HTTP implementation slice
8. Track J: security/spec review
9. Track K: code quality/regression review
10. Track G: one caller migration
11. Track J/K reviews again

Context-promotion wave:
12. Track H: context safety design spec
13. Track I: context safety implementation slice
14. Track J/K reviews again

Hard rule:
- Do not run implementation tracks in parallel if they touch the same files.
- Do not migrate multiple callers in the first fetch slice.
- Do not wire every context surface in the first context slice.
