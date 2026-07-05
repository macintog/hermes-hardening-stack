# Hermes SFW package guard

Current-base local hardening payload for routing Hermes-owned package-manager
subprocesses through the operator-account Socket Firewall package shim.

Base: `23021be26e66e26e1b9893eda2dc943849ede03d`

Apply from a clean current Hermes checkout:

```bash
while read -r fragment; do
  [ -z "$fragment" ] && continue
  git apply --3way "$HOME/.config/hermes-agent-patches/patches/hermes-sfw-package-guard/$fragment"
done < "$HOME/.config/hermes-agent-patches/patches/hermes-sfw-package-guard/series"
```

Focused validation:

```bash
<hermes-python> -m pytest \
  tests/test_hermes_constants.py \
  tests/hermes_cli/test_managed_uv.py \
  tests/hermes_cli/test_web_ui_build.py \
  tests/hermes_cli/test_uv_tool_update.py \
  tests/hermes_cli/test_update_autostash.py -q
```
