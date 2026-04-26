# Patch refresh commands template

Adjust paths based on final patch strategy. Do not drop any patch listed in `series`.

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
base=$(git merge-base HEAD origin/main)
tip=$(git rev-parse HEAD)

# Regenerate existing topical patches or add a new patch as chosen by integration.
# Example for a new 0006:
git diff --binary "$base" "$tip" -- \
  agent/artifact_provenance.py \
  agent/action_authority.py \
  agent/context_safety.py \
  model_tools.py \
  run_agent.py \
  tests/security/test_structured_taint_authority.py \
  tests/security/test_hostile_download_e2e.py \
  tests/security/test_persistence_taint.py \
  tests/security/test_tool_registry_security_metadata.py \
  > "$patch_repo/patches/hermes-safe-fetch-context/0006-structured-taint-authority-e2e-hardening.patch"

# Refresh series exactly to the final patch order.
cat > "$patch_repo/patches/hermes-safe-fetch-context/series" <<'SERIES'
0001-context-safety-core.patch
0002-safe-http-gateway-download-hardening.patch
0003-customization-maintenance-tool.patch
0004-provenance-action-authority-hardening.patch
0005-tool-result-promotion-action-registry.patch
0006-structured-taint-authority-e2e-hardening.patch
SERIES

printf 'base=%s\ntip=%s\n' "$base" "$tip" > "$patch_repo/patches/hermes-safe-fetch-context/base.ref"
```

If the integration refreshes existing patches instead of adding 0006, update this template accordingly and ensure the playbook contains the final commands.
