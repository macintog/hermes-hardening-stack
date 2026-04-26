# Subagent 09: patch-stack integrity and rebase validation

You are a downstream patch-stack maintenance subagent. Your task is to ensure the hardening work is preserved as an executable, refreshable, rebase-safe patch stack.

## Modes

The master thread may ask you to run in either:

1. `audit-only` mode before implementation
2. `refresh` mode after implementation

## Source locations

Patch-stack repo:

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
```

Hermes checkout:

```bash
cd ~/.hermes/hermes-agent
```

Patch stack:

```text
$patch_repo/patches/hermes-safe-fetch-context/series
$patch_repo/patches/hermes-safe-fetch-context/*.patch
$patch_repo/patches/hermes-safe-fetch-context/base.ref
```

Docs:

```text
$patch_repo/docs/customizations/hermes-safe-fetch-context/
```

## Audit-only tasks

1. Read `series` and list all patches.
2. Verify docs consistently describe all patches.
3. Verify `REBASE_PLAYBOOK.md` does not say “both patches” if the series contains more than two patches.
4. Verify `0002-safe-http-gateway-download-hardening.patch` carries `tools/safe_http.py` and `tests/tools/test_safe_http.py` unless those are now upstream and explicitly documented as upstream-owned.
5. Verify customization-maintenance-tool files, if any, are not accidentally assigned to the safe-fetch patch.
6. Verify `base.ref` exists and is parseable.
7. Attempt a clean apply check in a scratch worktree when possible:

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

Report blockers before implementation proceeds.

## Refresh tasks

After all security work and tests pass:

1. Determine upstream base and hardening tip:

```bash
base=$(git merge-base HEAD origin/main)
tip=$(git rev-parse HEAD)
```

2. Regenerate patch files by logical ownership. Do not mix unrelated tests into wrong patches.

Suggested ownership after expanded hardening:

### Patch 0001: context safety and promotion hardening

Likely files:

```text
agent/context_safety.py
agent/prompt_builder.py
agent/memory_manager.py
cron/scheduler.py
tools/cronjob_tools.py
tools/skills_tool.py
plus context-promotion tests
```

### Patch 0002: safe HTTP and remote-byte ingress hardening

Likely files:

```text
tools/safe_http.py
tests/tools/test_safe_http.py
gateway/platforms/* relevant safe-fetch files
tools/web_tools.py if migrated
tools/skills_hub.py if migrated
plus fetch-surface tests
```

### Patch 0003: customization maintenance tool

Likely files:

```text
tools/customization_tool.py
tests/tools/test_customization_tool.py
toolsets.py if needed
```

### New patch if needed: provenance/action-authority hardening

If the new provenance/action-authority work is large, prefer creating a new ordered patch rather than hiding it inside unrelated patches. Possible name:

```text
0004-provenance-action-authority-hardening.patch
```

Owned files might include:

```text
agent/context_provenance.py
agent/action_authority.py
relevant dispatcher/tool metadata files
tests/security/test_artifact_provenance.py
tests/security/test_action_authority.py
tests/security/test_prompt_injection_containment.py
```

3. Update `series` if a new patch is created.
4. Update `base.ref`:

```bash
printf 'base=%s\ntip=%s\n' "$base" "$tip" > "$patch_repo/patches/hermes-safe-fetch-context/base.ref"
```

5. Update docs:

```text
PATCH_STACK.md
REBASE_PLAYBOOK.md
SURFACE_MAP.md
SECURITY_MODEL.md
IMPLEMENTATION_PLAN.md
MASTER_THREAD_PROMPT.md
```

6. Add or update a clean verification script if useful:

```text
scripts/verify_hardening_patch_stack.sh
```

or place it in the patch repo under:

```text
docs/customizations/hermes-safe-fetch-context/verify_patch_stack.sh
```

## Required validation

Patch apply check:

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

If feasible, also apply and run targeted tests in the scratch worktree.

## Acceptance criteria

- Every patch in `series` exists.
- Every owned file is in the correct patch.
- `tools/safe_http.py` and its tests are carried or explicitly upstream-owned.
- Provenance/action-authority work is carried in the patch stack.
- Docs reflect actual patch count and ownership.
- Clean upstream worktree can check-apply the stack.
- Verification commands are documented.
