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
  HERMES_BASE_REF   Base ref for the temporary worktree. Defaults to the
                    base= SHA in patches/hermes-safe-fetch-context/base.ref.
                    Set HERMES_BASE_REF=origin/main to verify against upstream main.
                    If base.ref contains tip=, tip must be the patched Hermes
                    commit used to generate the stack and must not equal base
                    when the series contains non-empty patches.
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
base_ref_file="$stack_dir/base.ref"

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
if [[ ! -f "$base_ref_file" ]]; then
  echo "ERROR: missing base.ref file: $base_ref_file" >&2
  exit 1
fi

base_ref_meta=$(python - "$base_ref_file" "$series_file" "$stack_dir" <<'PY'
from pathlib import Path
import sys
base_ref_file = Path(sys.argv[1])
series_file = Path(sys.argv[2])
stack_dir = Path(sys.argv[3])
meta = {}
for line in base_ref_file.read_text().splitlines():
    if not line.strip() or line.lstrip().startswith('#') or '=' not in line:
        continue
    key, value = line.split('=', 1)
    meta[key.strip()] = value.strip()
base_ref = meta.get('base')
tip_ref = meta.get('tip')
if not base_ref:
    raise SystemExit("ERROR: base.ref does not contain a base= value")
series = [line.strip() for line in series_file.read_text().splitlines() if line.strip() and not line.lstrip().startswith('#')]
nonempty = [name for name in series if (stack_dir / name).exists() and (stack_dir / name).stat().st_size > 0]
if tip_ref and tip_ref == base_ref and nonempty:
    raise SystemExit("ERROR: base.ref has base == tip but series contains non-empty patches; tip must be the patched Hermes commit or be removed/renamed")
print(base_ref)
print(tip_ref or "")
PY
)
base_ref=$(printf '%s
' "$base_ref_meta" | sed -n '1p')
tip_ref=$(printf '%s
' "$base_ref_meta" | sed -n '2p')

if [[ -n "${HERMES_BASE_REF:-}" ]]; then
  base_ref=$HERMES_BASE_REF
fi
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
if [[ -n "$tip_ref" ]]; then
  git -C "$checkout" rev-parse --verify "$tip_ref^{commit}" >/dev/null
  git -C "$checkout" merge-base --is-ancestor "$base_ref" "$tip_ref" || {
    echo "ERROR: base.ref tip is not descended from base" >&2
    exit 1
  }
fi

echo "Creating clean verification worktree from $base_ref"
git -C "$checkout" worktree add --detach "$worktree" "$base_ref" >/dev/null

echo "Checking patch stack inputs"
python - "$stack_dir" "$series_file" <<'PY'
from pathlib import Path
import sys

stack_dir = Path(sys.argv[1])
series_file = Path(sys.argv[2])
manifest_file = stack_dir / "manifest.yaml"
if not manifest_file.exists():
    raise SystemExit(f"ERROR: missing manifest: {manifest_file}")
series = [line.strip() for line in series_file.read_text().splitlines() if line.strip() and not line.lstrip().startswith("#")]
if not series:
    raise SystemExit("ERROR: series file is empty")
missing = [name for name in series if not (stack_dir / name).exists()]
empty = [name for name in series if (stack_dir / name).exists() and (stack_dir / name).stat().st_size == 0]
if missing:
    raise SystemExit(f"ERROR: series patch missing on disk: {missing}")
if empty:
    raise SystemExit(f"ERROR: series patch is empty: {empty}")
print("patch stack inputs ok")
PY

cd "$worktree"

echo "Verifying all series patch files are tracked"
tracked_paths=(
  "patches/hermes-safe-fetch-context/base.ref"
  "patches/hermes-safe-fetch-context/series"
  "patches/hermes-safe-fetch-context/manifest.yaml"
)
while IFS= read -r patch || [[ -n "$patch" ]]; do
  [[ -z "$patch" || "$patch" =~ ^[[:space:]]*# ]] && continue
  tracked_paths+=("patches/hermes-safe-fetch-context/$patch")
done < "$series_file"
git -C "$patch_repo" ls-files --error-unmatch "${tracked_paths[@]}" >/dev/null

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: verification worktree is not clean before patch apply" >&2
  git status --short >&2
  exit 1
fi

series_display="patches/hermes-safe-fetch-context/series"
echo "Applying patch stack from $series_display"
while IFS= read -r patch || [[ -n "$patch" ]]; do
  [[ -z "$patch" || "$patch" =~ ^[[:space:]]*# ]] && continue
  echo "  applying $patch"
  git apply --3way "$stack_dir/$patch"
done < "$series_file"
if [[ -n "${PYTHON:-}" ]]; then
  python_bin=$PYTHON
elif [[ -x "$worktree/.venv/bin/python" ]]; then
  python_bin="$worktree/.venv/bin/python"
elif [[ -x "$worktree/venv/bin/python" ]]; then
  python_bin="$worktree/venv/bin/python"
elif [[ -x "$checkout/.venv/bin/python" ]]; then
  python_bin="$checkout/.venv/bin/python"
elif [[ -x "$checkout/venv/bin/python" ]]; then
  python_bin="$checkout/venv/bin/python"
elif [[ -x "$HOME/.hermes/hermes-agent/venv/bin/python" ]]; then
  python_bin="$HOME/.hermes/hermes-agent/venv/bin/python"
else
  python_bin=python
fi

echo "Running py_compile smoke checks"
"$python_bin" - "$stack_dir/manifest.yaml" <<'PY'
from pathlib import Path
import py_compile
import re
import sys

manifest = Path(sys.argv[1]).read_text()
paths: list[str] = []
current_section = None
for raw in manifest.splitlines():
    if re.match(r"^    owns:\s*$", raw):
        current_section = "owns"
        continue
    if re.match(r"^    [a-zA-Z_]+:\s*$", raw):
        current_section = None
        continue
    if current_section == "owns":
        match = re.match(r"^      - (.+?\.py)\s*$", raw)
        if match:
            path = match.group(1)
            if path not in paths:
                paths.append(path)

missing = [path for path in paths if not Path(path).exists()]
if missing:
    raise SystemExit(f"ERROR: py_compile paths missing after patch apply: {missing}")
for path in paths:
    py_compile.compile(path, doraise=True)
print(f"py_compile ok ({len(paths)} files)")
PY

echo "Running import smoke checks"
"$python_bin" - <<'PY'
import importlib
for module in (
    "agent.context_safety",
    "agent.artifact_provenance",
    "agent.action_authority",
    "tools.safe_http",
    "tools.customization_tool",
):
    importlib.import_module(module)
print("imports ok")
PY

echo "Running targeted tests"
"$python_bin" -m pytest -o 'addopts=' -q \
  -W "ignore:.*asyncio.get_event_loop_policy.*deprecated.*:DeprecationWarning" \
  -W "ignore::DeprecationWarning:tests.conftest" \
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
  tests/gateway/test_telegram_safe_image_download.py \
  tests/gateway/test_wecom.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/security/test_safe_fetch_surfaces.py \
  tests/security/test_skill_plugin_boundaries.py \
  tests/security/test_artifact_provenance.py \
  tests/security/test_action_authority.py \
  tests/security/test_prompt_injection_containment.py \
  tests/security/test_tool_result_promotion.py

echo "Patch stack verification passed"
