# Rebase playbook

Use this when updating Hermes while preserving the customization.

## Safety rules

- Do not treat line conflicts as the main problem. Treat intent drift as the main problem.
- Keep the patch stack small and ordered.
- Prefer adapting call sites to new upstream helpers if Hermes adds equivalent functionality.
- Do not run `npm install` unless explicitly authorized. If frontend lockfiles change unexpectedly, inspect and revert unless the task required them.

## Patch stack location

Canonical local repo:

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
```

Hermes config also records this path at `customizations.hermes_agent_patches`.

- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/0001-context-safety-core.patch`
- `patches/hermes-safe-fetch-context/0002-safe-http-gateway-download-hardening.patch`
- `patches/hermes-safe-fetch-context/0003-customization-maintenance-tool.patch`
- `patches/hermes-safe-fetch-context/0004-provenance-action-authority-hardening.patch`
- `patches/hermes-safe-fetch-context/manifest.yaml`

## Normal update workflow

From the Hermes checkout root:

```bash
git status --short --branch
```

Make sure unrelated local work is either committed, stashed, or intentionally ignored.

Fetch upstream Hermes:

```bash
git fetch origin main
```

Create a scratch branch from upstream:

```bash
git switch -c customizations/reapply-safe-fetch-context origin/main
```

Apply patches in order:

```bash
while read -r patch; do
  [ -z "$patch" ] && continue
  git apply --3way "$patch_repo/patches/hermes-safe-fetch-context/$patch"
done < "$patch_repo/patches/hermes-safe-fetch-context/series"
```

If a patch fails:

```bash
git status --short
git diff --check
```

Then use `SURFACE_MAP.md` to locate the new upstream surface and manually preserve the behavior.

## Verification commands

Fast syntax/import smoke:

```bash
python -m py_compile \
  agent/context_references.py \
  agent/context_safety.py \
  agent/memory_manager.py \
  agent/prompt_builder.py \
  cron/scheduler.py \
  tools/cronjob_tools.py \
  tools/skills_tool.py \
  tools/safe_http.py \
  gateway/platforms/base.py \
  gateway/platforms/bluebubbles.py \
  gateway/platforms/discord.py \
  gateway/platforms/feishu.py \
  gateway/platforms/mattermost.py \
  gateway/platforms/qqbot/adapter.py \
  gateway/platforms/slack.py \
  gateway/platforms/telegram.py \
  gateway/platforms/wecom.py \
  tools/skills_hub.py \
  tools/customization_tool.py \
  toolsets.py \
  agent/action_authority.py \
  agent/artifact_provenance.py \
  model_tools.py \
  run_agent.py
```

The clean-base verification script compiles every Python path listed under `owns:` in `manifest.yaml`, including tests, so it is stricter than this hand-run smoke command.

Targeted test set:

```bash
python -m pytest -o 'addopts=' -q \
  tests/agent/test_context_safety.py \
  tests/tools/test_safe_http.py \
  tests/agent/test_memory_provider.py \
  tests/agent/test_prompt_builder.py \
  tests/cron/test_cron_context_from.py \
  tests/cron/test_cron_script.py \
  tests/tools/test_cronjob_tools.py \
  tests/tools/test_skills_tool.py \
  tests/tools/test_customization_tool.py \
  tests/gateway/test_base_media_cache_safe_http.py \
  tests/gateway/test_discord_attachment_download.py \
  tests/gateway/test_feishu.py \
  tests/gateway/test_mattermost.py \
  tests/gateway/test_media_download_retry.py \
  tests/gateway/test_qqbot.py \
  tests/gateway/test_slack.py \
  tests/gateway/test_telegram_safe_image_download.py \
  tests/gateway/test_wecom.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/security/test_safe_fetch_surfaces.py \
  tests/security/test_skill_plugin_boundaries.py \
  tests/security/test_artifact_provenance.py \
  tests/security/test_action_authority.py \
  tests/security/test_prompt_injection_containment.py
```

Clean-base stack verification:

```bash
"$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" "$PWD"
```

By default this uses the `base=` SHA in `patches/hermes-safe-fetch-context/base.ref`. To verify against current upstream main instead, run:

```bash
HERMES_BASE_REF=origin/main "$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" "$PWD"
```

Fuller confidence check if time allows:

```bash
python -m pytest -o 'addopts=' -q tests/agent tests/tools tests/cron tests/gateway
```

## Refreshing the patch stack after a successful rebase

After conflicts are resolved and tests pass, refresh the patches from the new upstream base.

Set variables:

```bash
base=$(git merge-base HEAD origin/main)
tip=$(git rev-parse HEAD)
```

Regenerate patch 0001 (context safety and promotion):

```bash
git diff --binary "$base" "$tip" -- \
  agent/context_references.py \
  agent/context_safety.py \
  agent/memory_manager.py \
  agent/prompt_builder.py \
  cron/scheduler.py \
  tools/cronjob_tools.py \
  tools/skills_tool.py \
  tests/agent/test_context_safety.py \
  tests/agent/test_memory_provider.py \
  tests/agent/test_prompt_builder.py \
  tests/cron/test_cron_context_from.py \
  tests/cron/test_cron_script.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/tools/test_cronjob_tools.py \
  tests/tools/test_skills_tool.py \
  > "$patch_repo/patches/hermes-safe-fetch-context/0001-context-safety-core.patch"
```

Regenerate patch 0002 (safe HTTP and remote-byte ingress):

```bash
git diff --binary "$base" "$tip" -- \
  tools/safe_http.py \
  gateway/platforms/base.py \
  gateway/platforms/bluebubbles.py \
  gateway/platforms/discord.py \
  gateway/platforms/feishu.py \
  gateway/platforms/mattermost.py \
  gateway/platforms/qqbot/adapter.py \
  gateway/platforms/slack.py \
  gateway/platforms/telegram.py \
  gateway/platforms/wecom.py \
  tools/skills_hub.py \
  tests/tools/test_safe_http.py \
  tests/gateway/test_base_media_cache_safe_http.py \
  tests/gateway/test_discord_attachment_download.py \
  tests/gateway/test_feishu.py \
  tests/gateway/test_mattermost.py \
  tests/gateway/test_media_download_retry.py \
  tests/gateway/test_qqbot.py \
  tests/gateway/test_slack.py \
  tests/gateway/test_telegram_safe_image_download.py \
  tests/gateway/test_wecom.py \
  tests/security/test_safe_fetch_surfaces.py \
  tests/security/test_skill_plugin_boundaries.py \
  > "$patch_repo/patches/hermes-safe-fetch-context/0002-safe-http-gateway-download-hardening.patch"
```

Regenerate patch 0003 (customization maintenance tool):

```bash
git diff --binary "$base" "$tip" -- \
  tools/customization_tool.py \
  tests/tools/test_customization_tool.py \
  toolsets.py \
  > "$patch_repo/patches/hermes-safe-fetch-context/0003-customization-maintenance-tool.patch"
```

Regenerate patch 0004 (provenance/action-authority hardening):

```bash
git diff --binary "$base" "$tip" -- \
  agent/action_authority.py \
  agent/artifact_provenance.py \
  model_tools.py \
  run_agent.py \
  HARDENING_SURFACE_INVENTORY.md \
  tests/security/test_action_authority.py \
  tests/security/test_artifact_provenance.py \
  tests/security/test_prompt_injection_containment.py \
  > "$patch_repo/patches/hermes-safe-fetch-context/0004-provenance-action-authority-hardening.patch"
```

Refresh `series` and `base.ref`:

```bash
printf '%s\n' \
  0001-context-safety-core.patch \
  0002-safe-http-gateway-download-hardening.patch \
  0003-customization-maintenance-tool.patch \
  0004-provenance-action-authority-hardening.patch \
  > "$patch_repo/patches/hermes-safe-fetch-context/series"
# Only write tip= after committing the patched Hermes tree; omit tip= for working-tree generated stacks.
printf 'base=%s\ntip=%s\n' "$base" "$tip" > "$patch_repo/patches/hermes-safe-fetch-context/base.ref"
```

Check patch applicability against a clean upstream worktree before trusting the refresh:

```bash
git worktree add /tmp/hermes-patch-check origin/main
cd /tmp/hermes-patch-check
while read -r patch; do
  [ -z "$patch" ] && continue
  git apply --check --3way "$OLDPWD/patches/hermes-safe-fetch-context/$patch"
done < "$OLDPWD/patches/hermes-safe-fetch-context/series"
cd "$OLDPWD"
git worktree remove /tmp/hermes-patch-check
```

## Conflict triage checklist

For each conflict, answer:

1. Did upstream add an equivalent safe HTTP or context-safety helper?
   - If yes, prefer upstream helper if it preserves the required behavior.
   - Keep missing tests from this patch stack if upstream lacks coverage.

2. Did the platform adapter change its download path?
   - Find the new URL-fetching function.
   - Preserve auth headers.
   - Preserve redirect validation.
   - Preserve byte cap.
   - Preserve URL redaction.

3. Did prompt/memory/cron/skill context rendering change?
   - Find the new promotion boundary.
   - Preserve structured findings.
   - Preserve untrusted rendering or blocking behavior.

4. Did tests fail because behavior changed intentionally upstream?
   - Update tests only after confirming the new behavior still satisfies `INTENT.md`.

## Done criteria

A rebase is done when:
- all patches apply or have been intentionally refreshed
- `SURFACE_MAP.md` still matches the live code surfaces
- targeted tests pass, or failures are documented with root cause
- patch stack applies cleanly in a fresh upstream worktree
- docs mention any important upstream replacement or retired custom surface


## base.ref provenance invariant

`base.ref` must always contain `base=<clean upstream commit>`. `tip=`, when present, must be the actual patched Hermes commit used to generate the current stack. Do not write `tip=` for uncommitted/path-limited working-tree captures. The verifier fails when `base == tip` and the series contains non-empty patches.
