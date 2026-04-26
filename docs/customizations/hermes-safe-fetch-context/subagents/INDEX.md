# Hermes Safe Fetch + Context Promotion Subagent Index

This directory contains one prompt file per subagent role for the Hermes safe-fetch and context-promotion hardening project.

Source docs:
- Recommendation: `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- Master thread prompt: `/Users/ryand/playground/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md`
- Delegation matrix: `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`
- Prior related project: `/Users/ryand/playground/hermes-content-safety/`

## Prompt files

First-wave reconnaissance:
1. `01-plan-and-task-graph.md`
2. `02-fetch-surface-recon.md`
3. `03-context-promotion-recon.md`
4. `04-test-inventory.md`

Safe-fetch implementation wave:
5. `05-safe-http-design-spec.md`
6. `06-implement-safe-http-slice.md`
7. `07-migrate-one-fetch-caller.md`

Context-promotion implementation wave:
8. `08-context-safety-design-spec.md`
9. `09-implement-context-safety-slice.md`

Review prompts:
10. `10-security-spec-review.md`
11. `11-code-quality-regression-review.md`

## Recommended orchestration

First-wave reconnaissance and the core context-promotion slices are complete. For the next session, use the master-thread orchestration rule in `MASTER_THREAD_PROMPT.md`:
- delegate all substantive implementation and review work to fresh subagents.
- proceed through remaining safe_fetch caller migrations one slice at a time.
- stop only if actual user intervention is required.
- do not commit unless explicitly asked.

Remaining implementation work should use these existing prompt roles:
- implementation subagent: adapt `07-migrate-one-fetch-caller.md` per caller/platform.
- security/spec review: `10-security-spec-review.md`.
- code-quality/regression review: `11-code-quality-regression-review.md`.

Recommended remaining caller order:
1. Feishu remote document download.
2. Slack file downloads.
3. QQBot media download paths.
4. Mattermost inbound file / URL-as-file paths.
5. Telegram fallback image download.
6. Discord fallback image/animation/attachment downloads.
7. Shared base media cache helpers only after narrower migrations prove the API.

Use these prompts as self-contained task briefs. Each file is written so it can be pasted directly into `delegate_task` or used as a fresh subagent session prompt.
