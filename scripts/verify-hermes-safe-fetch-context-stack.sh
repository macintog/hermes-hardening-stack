#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: verify-hermes-safe-fetch-context-stack.sh [HERMES_CHECKOUT]

Applies every patch listed in patches/hermes-safe-fetch-context/series to a clean
Hermes worktree, then runs syntax/import smoke checks and targeted tests.

Arguments / environment:
  HERMES_CHECKOUT   Existing Hermes git checkout to use as the clean base.
                    Defaults to $HERMES_CHECKOUT, then current directory when it
                    looks like a Hermes checkout.
  HERMES_BASE_REF   Base ref for the temporary worktree. Defaults to origin/main.
  KEEP_WORKTREE=1   Keep the temporary worktree for debugging.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
patch_repo=$(cd -- "$script_dir/.." && pwd)
stack_dir="$patch_repo/patches/hermes-safe-fetch-context"
series_file="$stack_dir/series"

if [[ ! -f "$series_file" ]]; then
  echo "ERROR: missing series file: $series_file" >&2
  exit 1
fi

checkout=${1:-${HERMES_CHECKOUT:-}}
if [[ -z "$checkout" ]]; then
  if [[ -d .git && -d agent && -d tools && -d gateway ]]; then
    checkout=$PWD
  else
    echo "ERROR: pass a Hermes checkout path or set HERMES_CHECKOUT" >&2
    usage >&2
    exit 1
  fi
fi

checkout=$(cd -- "$checkout" && pwd)
base_ref=${HERMES_BASE_REF:-origin/main}
worktree=${TMPDIR:-/tmp}/hermes-safe-fetch-context-verify-$$
cleanup() {
  if [[ "${KEEP_WORKTREE:-0}" != "1" ]]; then
    git -C "$checkout" worktree remove --force "$worktree" >/dev/null 2>&1 || true
  else
    echo "Keeping verification worktree: $worktree"
  fi
}
trap cleanup EXIT

git -C "$checkout" rev-parse --verify "$base_ref^{commit}" >/dev/null

echo "Creating clean verification worktree from $base_ref"
git -C "$checkout" worktree add --detach "$worktree" "$base_ref" >/dev/null

echo "Applying patch stack from $series_file"
while IFS= read -r patch || [[ -n "$patch" ]]; do
  [[ -z "$patch" || "$patch" =~ ^[[:space:]]*# ]] && continue
  echo "  applying $patch"
  git -C "$worktree" apply --3way "$stack_dir/$patch"
done < "$series_file"

cd "$worktree"
python_bin=${PYTHON:-python}

echo "Running py_compile smoke checks"
"$python_bin" -m py_compile \
  agent/context_safety.py \
  tools/safe_http.py \
  tools/customization_tool.py

echo "Running import smoke checks"
"$python_bin" - <<'PY'
import importlib
for module in (
    "agent.context_safety",
    "tools.safe_http",
    "tools.customization_tool",
):
    importlib.import_module(module)
print("imports ok")
PY

echo "Running targeted tests"
"$python_bin" -m pytest -o 'addopts=' -q \
  tests/agent/test_context_safety.py \
  tests/tools/test_safe_http.py \
  tests/tools/test_customization_tool.py \
  tests/agent/test_memory_provider.py \
  tests/agent/test_prompt_builder.py \
  tests/cron/test_cron_context_from.py \
  tests/cron/test_cron_script.py \
  tests/tools/test_cronjob_tools.py \
  tests/tools/test_skills_tool.py \
  tests/gateway/test_base_media_cache_safe_http.py \
  tests/gateway/test_discord_attachment_download.py \
  tests/gateway/test_feishu.py \
  tests/gateway/test_mattermost.py \
  tests/gateway/test_media_download_retry.py \
  tests/gateway/test_qqbot.py \
  tests/gateway/test_slack.py \
  tests/gateway/test_telegram_safe_image_download.py

echo "Patch stack verification passed"
