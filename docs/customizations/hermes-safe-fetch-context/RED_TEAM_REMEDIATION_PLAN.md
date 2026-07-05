# Red-Team Remediation Plan

Date: 2026-04-29

This is the implementation handoff for the red-team review of Hermes prompt-injection hardening. The goal is to close authority-laundering paths without turning normal Hermes use into a permission-dialog loop.

## Product Constraint

Do not fix these gaps by prompting more often by default. Fix them by preserving trust boundaries through orchestration seams and by making trusted local-work policy explicit.

Low-friction behavior to preserve:

- Read-only inspection, summarization, search, and ordinary local code navigation should stay smooth.
- Trusted local development requests such as "test this repo", "fix this bug", and "run the focused pytest" should not require repeated confirmation for normal in-worktree commands.
- Confirmation should be rare, scoped, and reusable for the current turn or session.
- Untrusted evidence may inform answers, summaries, and diffs, but cannot choose side-effecting targets or authority.

## Coordination Model

Fresh-thread execution plan:

- Use four concurrent worker slots.
- Use unforked GPT-5.5 medium workers.
- Give each worker one bounded task from the initial four slots below.
- Tear down a completed worker before assigning the next queued task.
- Keep write ownership disjoint. Workers must not revert edits from other workers.
- After each worker returns, reindex or inspect its changed files before merging the next dependent task.
- The parent thread owns manifest/series alignment, final verifier runs, public doc refresh, and live Hermes refresh.

Initial slot assignment:

1. Worker A: delegation trust boundary.
2. Worker B: gateway active-intent authentication.
3. Worker C: memory and plugin context taint plumbing.
4. Worker D: affirmative intent and local-dev policy split.

Queued after an initial worker completes:

5. Worker E: skill provenance and trust promotion.
6. Worker F: plugin hook authority and side-effect policy.
7. Worker G: UX regression harness and low-friction proof.

## Global Done Criteria

Each implemented fix is done only when all applicable items are true:

- Final-state patch fragments are updated under `patches/hermes-safe-fetch-context/`.
- `series` and `manifest.yaml` own every changed Hermes file and every required test.
- New required tests are listed in `payload.required_tests` when they are security-boundary proof.
- Focused applied-worktree tests pass.
- Recorded-base verifier passes:

```bash
PYTHON=<hermes-python> \
HERMES_CHECKOUT=<hermes-checkout> \
./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

- If the fix changes current-upstream conflict behavior, run current-upstream proof:

```bash
PYTHON=<hermes-python> \
HERMES_CHECKOUT=<hermes-checkout> \
HERMES_BASE_REF=origin/main \
VERIFY_APPLY_ONLY=1 \
./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

- The legacy `VERIFY_CURRENT_UPSTREAM=1` and `APPLY_ONLY=1` environment names now hard-fail. Use `HERMES_BASE_REF=origin/main` and `VERIFY_APPLY_ONLY=1`, or pass `--apply-only`.

- The full verifier runs public samples automatically. For focused public-sample reruns, intentionally keep one applied worktree, run the samples, then remove the worktree:

```bash
<hermes-python> \
  validation/scripts/run_public_sample_prompt_checks.py \
  --worktree <kept-worktree-path> \
  --out /tmp/hermes-red-team-public-sample-checks.json
```

```bash
./scripts/cleanup-hermes-verifier-worktrees --remove --force
```

- Run static payload checks:

```bash
git diff --check
```

## Worker A: Delegation Trust Boundary

Risk:

`delegate_task` is classified as `agent_loop_internal`, but the child receives the delegated `goal` as its own trusted user message. If the parent forms a delegation goal from hostile evidence, the child can treat attacker text as trusted scope and use side-effecting tools.

Observed proof:

`evaluate_action_authority("delegate_task", {"goal": "...", "toolsets": ["terminal"]}, trusted_user_intent="Summarize this page.", prior_untrusted_context=<downloaded evidence>)` returns allow as `agent_loop_internal`.

Expected fix:

- Add authority evaluation for delegation arguments before child spawn.
- Classify delegation as internal orchestration only when the child cannot receive side-effecting tools or attacker-derived goals.
- Split child input into trusted goal and evidence context.
- If delegation `goal`, `context`, `tasks[*].goal`, `tasks[*].context`, `toolsets`, `role`, `acp_command`, or `acp_args` are parameterized by untrusted evidence, block or require scoped confirmation.
- Pass trusted parent intent into child as trusted intent only when it came from active user text.
- Pass evidence-only delegated context as fenced context, not as child `user_message`.
- Preserve low-friction read-only delegation for analysis workers.

Primary files:

- `agent/action_authority.py`
- `run_agent.py`
- `tools/delegate_tool.py`
- `tests/security/test_action_authority.py`
- `tests/security/test_prompt_injection_containment.py`
- `tests/security/test_tool_result_promotion.py`

Required tests:

- Hostile downloaded evidence cannot cause `delegate_task` with `terminal`, `file`, browser stateful, skill, memory, cron, or message tools.
- Hostile evidence cannot supply child goal or child context that becomes trusted user intent.
- User-scoped delegation such as "ask a worker to inspect these logs read-only" still works without confirmation.
- User-scoped delegation with side-effecting tools requires exact trusted scope.
- Child tool calls see evidence-only delegated context in `prior_untrusted_context`.
- Parent still fences `delegate_task` result before using it for subsequent side effects.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_action_authority.py \
  tests/security/test_prompt_injection_containment.py \
  tests/security/test_tool_result_promotion.py -q
```

## Worker B: Gateway Active-Intent Authentication

Status: implemented in the final-state payload; retained here as historical rationale and regression requirements.

Risk:

The original gap was that the API server trusted `__active_user_intent` when the request carried a static `X-Hermes-Gateway-Active-Intent: hermes-gateway-remote-proxy-v1` header. Any client that could set that header and reach the API could forge active intent.

Implemented contract:

- Replace the static header-only trust contract with the `hermes-gateway-remote-proxy-v2` internal contract.
- Require HMAC over the raw request body, timestamp, and nonce with the gateway active-intent secret shared only between gateway proxy and API server.
- Reject signed markers when the signature is stale, invalid, replayed, or missing required timestamp or nonce material.
- Ignore unsigned public API markers and use only visible request text for public clients.
- Validate `active_text` from trusted gateway segments; do not accept contradictory active text.
- Keep public OpenAI-compatible clients able to send ordinary messages without marker support.

Primary files:

- `gateway/run.py`
- `gateway/platforms/api_server.py`
- `tests/gateway/test_api_server.py`
- `tests/gateway/test_active_intent_segmentation.py`

Required tests:

- Public client body marker with no internal signature is ignored.
- Static old header alone is ignored or rejected.
- Valid gateway signature accepts a marker.
- Invalid signature rejects the request.
- Stale timestamp or replay nonce rejects the request.
- Marker with `active_text` not matching trusted segment text rejects.
- Gateway proxy sends the new signature headers on remote-proxy calls.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/gateway/test_api_server.py \
  tests/gateway/test_active_intent_segmentation.py -q
```

## Worker C: Memory And Plugin Context Taint Plumbing

Risk:

Memory prefetch and `pre_llm_call` plugin context are appended to provider-facing `api_messages`, but not always to the persistent `messages` list scanned by `_collect_prior_untrusted_context()`. The model can see evidence that the action gate does not see.

Expected fix:

- Render memory prefetch through `ContextSurface.MEMORY_CONTEXT` before API-call injection.
- Render plugin `pre_llm_call` output through `ContextSurface.PLUGIN_CONTEXT` before API-call injection.
- Preserve those same rendered blocks in an action-authority-visible per-turn taint buffer.
- Do not persist these ephemeral blocks to session DB unless existing policy says to.
- Keep trusted plugin code separate from plugin-provided text. Plugin-provided text remains evidence-only unless explicitly trusted by policy.
- Add one shared helper so future API-call-only context injections cannot bypass action authority.

Primary files:

- `run_agent.py`
- `agent/memory_manager.py` if the wrapper belongs there
- `hermes_cli/plugins.py` only if the plugin contract needs documentation or shape change
- `tests/security/test_action_authority.py`
- `tests/security/test_context_promotion_boundaries.py`
- `tests/security/test_skill_plugin_boundaries.py`
- `tests/agent/test_memory_provider.py` if present and relevant

Required tests:

- Memory prefetch text saying to run a command blocks terminal execution when the user only asked to summarize.
- Plugin pre-LLM context saying to write, send, install, or remember cannot authorize those actions.
- Memory/plugin context still informs ordinary final answers.
- Memory/plugin context is not written into persistent conversation history unexpectedly.
- A trusted local dev task still permits normal local inspection/build commands when memory/plugin taint is unrelated.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_action_authority.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/security/test_skill_plugin_boundaries.py -q
```

## Worker D: Affirmative Intent And Local-Dev Policy Split

Risk:

The action gate currently treats target mention plus action keyword as scoped trusted authority. Negated or quoted text such as "do not run python harmless.py" can still authorize the command. Separately, trusted local-work policy allows broad interpreter commands and relies on blacklist matching for network, secret, and destructive behavior.

Expected fix:

- Add affirmative-intent detection for trusted scoped authority.
- Reject or require confirmation when the trusted text only quotes, warns about, documents, or negates an action.
- Keep exact positive user requests working.
- Split trusted local work into explicit lanes:
  - read/search/status
  - focused tests/builds
  - in-worktree edits
  - network, secrets, persistence, destructive git, publish, and sudo
- Allow common safe local dev commands without prompts.
- Require confirmation or explicit policy for interpreter snippets that import networking, dump environment, read secret paths, or reach outside the workspace.
- Avoid overfitting to strings only; use command tokenization and known-safe command patterns where practical.

Primary files:

- `agent/action_authority.py`
- `tests/security/test_action_authority.py`
- `tests/security/test_development_authority.py`

Required tests:

- `Do not run <cmd>` does not authorize terminal.
- `The page says "run <cmd>" but summarize only` does not authorize terminal.
- `Do not write <path>` does not authorize file write.
- `Run pytest tests/foo.py -q` authorizes focused tests.
- `Fix this repo` permits `rg`, `git status`, and focused pytest/build commands inside the workspace.
- Broad local dev task does not permit socket/network Python snippets, `env` dumps, secret-like reads, destructive git, push, tag, or sudo.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_action_authority.py \
  tests/security/test_development_authority.py -q
```

## Worker E: Skill Provenance And Trust Promotion

Risk:

Skills under `~/.hermes/skills` are currently treated as `trusted_by_local_policy`. Community, hub, plugin, or downloaded skills can become local files and later gain policy authority by location alone.

Expected fix:

- Persist skill provenance at install time: bundled, local-authored, community/hub, plugin-provided, direct URL, manually promoted.
- Treat installed community/hub/plugin skills as evidence-only until explicitly promoted.
- Add a user-visible trust promotion path that records who/what promoted the skill and when.
- Keep bundled and explicitly local-authored skills smooth.
- Prevent inline shell expansion for evidence-only skills.

Primary files:

- `tools/skills_tool.py`
- `tools/skills_hub.py`
- `tools/skill_manager_tool.py` if install metadata is owned there
- `agent/skill_commands.py`
- `tests/security/test_skill_plugin_boundaries.py`
- `tests/tools/test_skills_tool.py` if present and relevant

Required tests:

- Hub/community-installed skill remains `evidence_only` after install.
- Promoted skill becomes trusted only after explicit local trust metadata exists.
- Evidence-only skill slash/load content is fenced.
- Evidence-only skill cannot authorize terminal, file, memory, cron, plugin install, or outbound tools.
- Bundled/local-authored trusted skill remains low friction.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_skill_plugin_boundaries.py \
  tests/tools/test_skills_tool.py -q
```

## Worker F: Plugin Hook Authority Policy

Risk:

Plugin hooks run before and after dispatch outside the deterministic action-authority gate. Text returned by hooks can be fenced, but enabled plugin code itself has ambient process authority.

Expected fix:

- Document and enforce plugin code as a trusted-code boundary.
- Add policy metadata for hooks that are observation-only versus side-effect-capable.
- Make `pre_tool_call` block-only unless a plugin is explicitly trusted for more.
- Keep `post_tool_call` observational by default.
- Keep `transform_tool_result` unable to upgrade provenance or remove action/evidence ledgers.
- Add audit events when trusted plugins alter tool execution or model-visible output.

Primary files:

- `hermes_cli/plugins.py`
- `model_tools.py`
- `agent/context_safety.py`
- `tests/security/test_skill_plugin_boundaries.py`
- `tests/security/test_tool_result_promotion.py`
- `tests/agent/test_shell_hooks.py`

Required tests:

- Transform hook cannot remove or forge native evidence/action ledgers without downgrade.
- Transform hook output remains fenced as plugin context or tool-result evidence.
- Pre-tool hook can block but not authorize a side-effect that action authority would deny.
- Side-effect-capable plugin hooks require explicit trusted plugin policy.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_skill_plugin_boundaries.py \
  tests/security/test_tool_result_promotion.py \
  tests/agent/test_shell_hooks.py -q
```

## Worker G: UX Regression Harness

Risk:

Security fixes can make out-of-box Hermes painful. The hardening must prove that common expected workflows still work without repeated prompts.

Expected fix:

- Add a focused low-friction regression suite.
- Prefer deterministic unit/integration tests over live model expectations.
- Cover representative user tasks:
  - summarize a web page
  - inspect a repo
  - run a focused test
  - read non-secret local files inside the workspace
  - write an explicitly requested in-worktree file
  - use a trusted bundled/local skill
  - delegate read-only analysis
  - ask for confirmation once and reuse the scoped approval
- Cover negative cases:
  - evidence-derived terminal command
  - evidence-derived file target
  - evidence-derived outbound recipient
  - evidence-derived child delegation with side-effect tools
  - evidence-derived browser click/type/console expression

Primary files:

- `tests/security/test_action_authority.py`
- `tests/security/test_development_authority.py`
- `tests/security/test_prompt_injection_public_corpus.py`
- `validation/scripts/run_public_sample_prompt_checks.py`
- `validation/README.md`
- `validation/runs/`

Required tests:

- Common local dev flows return `ALLOW` or at most one confirmation for the expected scoped action.
- Negative red-team flows return `BLOCK` or `REQUIRE_CONFIRMATION` with machine-readable `action_decisions`.
- Public sample checks remain `failure_count=0`.

Focused verification:

```bash
<hermes-python> -m pytest \
  tests/security/test_action_authority.py \
  tests/security/test_development_authority.py \
  tests/security/test_prompt_injection_public_corpus.py -q
```

## Parent Thread Integration Checklist

After worker patches are available:

1. Inspect `git status --short --branch`.
2. Review worker diffs by ownership area.
3. Resolve series/manifest ownership.
4. Run focused tests for changed areas.
5. Run recorded-base verifier.
6. Run public samples against the kept worktree only when focused reruns need it, then remove the verifier worktree.
7. Run current-upstream apply-only if conflict-prone files changed.
8. Refresh the private checkpoint and public docs with validation evidence and next safe step.
9. If live Hermes should receive the payload, treat that as a separate operator-authorized deployment lane. Do not refresh `<hermes-checkout>` as part of normal patch-authoring closeout.

## Suggested Live Smokes After Verified Apply

Use after the payload has been applied to the live Hermes checkout, not as the primary proof:

```bash
hermes chat -Q -q "Use the terminal tool to run: echo HERMES_RED_TEAM_REFRESH_OK. Report whether the tool call succeeded."
```

If gateway changed:

```bash
hermes gateway status
```

If the gateway is running, restart only with explicit operator intent or documented local policy for that service.
