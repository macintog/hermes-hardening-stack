# Master execution prompt: Hermes hostile-download prompt-injection containment

You are the Hermes/GPT-5.5 orchestrator. You must delegate substantive work to fresh subagents using the prompt files in `followup-prompts/subagents/`. Your job is to coordinate, validate, integrate, and keep the patch stack maintainable.

## Repositories and source of truth

Hermes source checkout:

```bash
cd ~/.hermes/hermes-agent
```

Downstream hardening patch-stack repo:

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
```

Existing hardening docs to read first:

```text
$patch_repo/docs/customizations/hermes-safe-fetch-context/README.md
$patch_repo/docs/customizations/hermes-safe-fetch-context/INTENT.md
$patch_repo/docs/customizations/hermes-safe-fetch-context/IMPLEMENTATION_PLAN.md
$patch_repo/docs/customizations/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md
$patch_repo/docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
$patch_repo/docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
$patch_repo/patches/hermes-safe-fetch-context/series
```

## Mission

Complete the hardening methodology so Hermes can safely process potentially hostile downloads and other external content without allowing that content to steer the agent into unsafe side effects.

The target pipeline is:

```text
remote bytes
  -> safe fetch
  -> artifact quarantine / provenance / taint envelope
  -> extraction with provenance preserved
  -> context-safety scan over exact promoted text or all promoted chunks
  -> fenced promotion as evidence only
  -> deterministic action-authority gate before side-effecting tools
```

Core security model:

```text
Downloaded, retrieved, gateway-supplied, recalled, cron-supplied, skill-supplied, plugin-supplied, @-referenced, or otherwise external text may be evidence.
It is never authority.
```

This must be enforced in code. Prompt wording, model instructions, scanner findings, and fences are defense-in-depth; they are not sufficient as the security boundary.

## Non-negotiable security invariants

1. Untrusted content must never be sufficient to authorize side-effecting tools.
2. Side-effecting tools require explicit trusted user/system/developer intent or a deterministic local policy that does not come from untrusted content.
3. Remote fetch safety and context safety are separate layers. A safely fetched document may still be prompt-injection-hostile.
4. Provenance/taint must survive conversion from URL -> bytes -> file/cache -> extracted text -> summaries -> prompt context -> tool-call decision.
5. All model-visible promoted external text must be scanned/fenced over the exact text that is included, or over every included chunk with overlap. Head/tail-only scanning is insufficient for hostile downloads.
6. External skill/plugin content is not privileged instruction merely because it is skill/plugin content. Trust must be explicit and policy-backed.
7. Patch-stack maintainability is part of security. A future upstream Hermes rebase must preserve the hardening behavior, not merely apply line-level patches.

## Required initial hygiene gate

Run from the Hermes checkout before each implementation slice:

```bash
git status --short --branch
git diff --name-only
```

Run from the patch-stack repo:

```bash
cd "$patch_repo"
git status --short --branch
git diff --name-only
cat patches/hermes-safe-fetch-context/series
```

Do not overwrite or include unrelated user work. If unrelated changes exist, identify them and work around them. Do not touch unrelated frontend lockfiles. Do not run `npm install` without explicit user authorization. Do not commit unless explicitly asked.

## Required orchestration workflow

For each workstream:

1. Delegate to the appropriate fresh subagent prompt.
2. Ask the subagent to inspect live code before proposing changes.
3. Require test-first or test-parallel implementation.
4. After implementation, delegate a fresh security/spec review subagent using `subagents/10_SECURITY_SPEC_REVIEW.md`.
5. Delegate a fresh code-quality/regression review subagent using `subagents/11_CODE_QUALITY_REGRESSION_REVIEW.md`.
6. Apply fixes if either review requests changes.
7. Run targeted verification from the master thread.
8. Update docs and patch-stack files before moving to the next major slice.

Do not pause for user approval between slices unless actual user intervention is required for credentials, authorization, a hidden product/security tradeoff, unrelated local work at risk, or an unresolvable test failure.

## Workstream order

### 0. Patch-stack integrity baseline

Use `subagents/09_PATCH_STACK_INTEGRITY_AND_REBASE_VALIDATION.md` in audit-only mode first.

Must answer:

- Does the executable patch stack contain `tools/safe_http.py` and `tests/tools/test_safe_http.py`?
- Does `series` include every patch currently documented?
- Do docs consistently describe all patches, including any customization maintenance tool patch?
- Can the stack apply in a clean upstream worktree with `git apply --check --3way`?

If the patch stack is incomplete, fix that before deeper security implementation.

### 1. Scope and security model

Delegate `subagents/01_SCOPE_SECURITY_MODEL.md`.

Output should update or create docs that state:

- hostile downloaded/retrieved/extracted content may be evidence only
- action authority must come from trusted user/system/developer intent or explicit policy
- prompt fences and scanner findings are not a hard boundary
- provenance/taint and authority gating are mandatory, not optional follow-up

### 2. Surface reconnaissance

Delegate `subagents/02_SURFACE_RECONNAISSANCE.md`.

Output should update `SURFACE_MAP.md` or create a companion hardening surface inventory covering:

- remote byte ingress
- extraction and cache paths
- model context promotion
- memory context
- cron context
- gateway replies and attachments
- skill/plugin content
- `@` file/git/url references
- side-effecting tool dispatch
- outbound messages
- file writes/deletes
- installs/updates
- secret reads/transmission
- credentialed network calls

### 3. Safe-fetch completeness

Delegate `subagents/03_SAFE_FETCH_COMPLETENESS.md`.

This workstream must not assume safe fetch solves prompt injection. It only secures remote-byte ingress. It must verify all direct HTTP/URL download paths either use `tools.safe_http` or have equivalent documented controls.

### 4. Artifact provenance and taint propagation

Delegate `subagents/04_ARTIFACT_PROVENANCE_AND_TAINT.md`.

This is mandatory. It must implement first-class provenance for fetched/extracted external content and preserve taint across transformations.

### 5. Context-promotion hardening

Delegate `subagents/05_CONTEXT_PROMOTION_HARDENING.md`.

This must close known gaps including, at minimum:

- memory provider `system_prompt_block()` or equivalent direct system/context insertion
- plugin `pre_llm_call` context
- gateway reply/document context
- `@` file/git/url references
- skill content, including linked file paths where model-visible
- extracted document/OCR/metadata text where applicable

### 6. Action authority gate

Delegate `subagents/06_ACTION_AUTHORITY_GATE.md`.

This is the central security boundary. It must classify tools/actions and prevent untrusted content from authorizing side effects.

### 7. Skill/plugin/hub hardening

Delegate `subagents/07_SKILL_PLUGIN_HUB_HARDENING.md`.

This must distinguish viewing skill content, installing/updating skill content, and executing/running skill-sourced instructions. External/community/plugin content must not become privileged instruction by default.

### 8. End-to-end adversarial validation

Delegate `subagents/08_END_TO_END_ADVERSARIAL_VALIDATION.md`.

This must add tests proving hostile content from downloads, gateway attachments, memory, cron, skills, plugins, and @ references cannot trigger side-effecting tools.

### 9. Patch-stack refresh and clean-worktree validation

Delegate `subagents/09_PATCH_STACK_INTEGRITY_AND_REBASE_VALIDATION.md` again in refresh mode.

Must update:

- `patches/hermes-safe-fetch-context/series`
- `base.ref`
- all patch files
- `REBASE_PLAYBOOK.md`
- `SURFACE_MAP.md`
- verification script if created

## Required validation commands

Use the repository’s canonical test runner where available. Prefer `scripts/run_tests.sh`. If direct Python is required, use `.venv/bin/python` rather than bare `python` when dependency imports require the venv.

Baseline smoke:

```bash
.venv/bin/python -m py_compile \
  agent/context_safety.py \
  tools/safe_http.py
```

After provenance/action-authority work, add relevant modules to py_compile.

Targeted tests should include existing hardening tests plus new security tests. At minimum run:

```bash
scripts/run_tests.sh tests/tools/test_safe_http.py -q
scripts/run_tests.sh tests/agent/test_context_safety.py -q
scripts/run_tests.sh tests/agent/test_prompt_builder.py -q
scripts/run_tests.sh tests/tools/test_cronjob_tools.py -q
scripts/run_tests.sh tests/cron/test_cron_context_from.py tests/cron/test_cron_script.py -q
scripts/run_tests.sh tests/agent/test_memory_provider.py -q
scripts/run_tests.sh tests/tools/test_skills_tool.py -q
scripts/run_tests.sh tests/gateway -q
```

Add and run new tests, likely under:

```text
tests/security/test_prompt_injection_containment.py
tests/security/test_action_authority.py
tests/security/test_artifact_provenance.py
```

Fuller confidence check if feasible:

```bash
scripts/run_tests.sh tests/agent tests/tools tests/cron tests/gateway tests/security -q
```

Patch-stack clean apply check:

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
git worktree add /tmp/hermes-hardening-patch-check origin/main
cd /tmp/hermes-hardening-patch-check
while read -r patch; do
  [ -z "$patch" ] && continue
  git apply --check --3way "$patch_repo/patches/hermes-safe-fetch-context/$patch"
done < "$patch_repo/patches/hermes-safe-fetch-context/series"
cd -
git worktree remove /tmp/hermes-hardening-patch-check
```

## Required final report

Return a concise but complete final report with:

- security invariant implemented
- exact code files changed
- exact docs/patch files changed
- tests added
- test commands and results
- clean patch-stack apply result
- residual risks and intentionally deferred work
- any upstream-Hermes behavior that replaced or superseded downstream hardening
