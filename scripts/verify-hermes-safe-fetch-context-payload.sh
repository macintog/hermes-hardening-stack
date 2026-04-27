#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: verify-hermes-safe-fetch-context-payload.sh [HERMES_CHECKOUT]

Applies the hardening payload fragments listed in patches/hermes-safe-fetch-context/series to a clean
Hermes worktree, then runs syntax/import smoke checks and targeted tests.

Arguments / environment:
  HERMES_CHECKOUT   Existing Hermes git checkout to use as the clean base.
                    Defaults to $HERMES_CHECKOUT, then current directory when it
                    looks like a Hermes checkout.
  HERMES_BASE_REF   Base ref for the temporary worktree. Defaults to the
                    base= SHA in patches/hermes-safe-fetch-context/base.ref.
                    Set HERMES_BASE_REF=origin/main to verify against upstream main.
                    If base.ref contains tip=, tip must be the patched Hermes
                    commit used to generate the packaged payload and must not equal base
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
payload_dir="$patch_repo/patches/hermes-safe-fetch-context"
series_file="$payload_dir/series"
base_ref_file="$payload_dir/base.ref"

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

base_ref_meta=$(python - "$base_ref_file" "$series_file" "$payload_dir" <<'PY'
from pathlib import Path
import sys
base_ref_file = Path(sys.argv[1])
series_file = Path(sys.argv[2])
payload_dir = Path(sys.argv[3])
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
nonempty = [name for name in series if (payload_dir / name).exists() and (payload_dir / name).stat().st_size > 0]
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

echo "Checking hardening payload inputs"
python - "$payload_dir" "$series_file" <<'PY'
from pathlib import Path
import sys
import re

payload_dir = Path(sys.argv[1])
series_file = Path(sys.argv[2])
manifest_file = payload_dir / "manifest.yaml"
if not manifest_file.exists():
    raise SystemExit(f"ERROR: missing manifest: {manifest_file}")
series = [line.strip() for line in series_file.read_text().splitlines() if line.strip() and not line.lstrip().startswith("#")]
if not series:
    raise SystemExit("ERROR: series file is empty")
missing = [name for name in series if not (payload_dir / name).exists()]
empty = [name for name in series if (payload_dir / name).exists() and (payload_dir / name).stat().st_size == 0]
if missing:
    raise SystemExit(f"ERROR: series payload fragment missing on disk: {missing}")
if empty:
    raise SystemExit(f"ERROR: series payload fragment is empty: {empty}")
for name in series:
    text = (payload_dir / name).read_text(errors="replace")
    targets = []
    for line in text.splitlines():
        if line.startswith("diff --git "):
            parts = line.split()
            if len(parts) >= 4 and parts[2].startswith("a/") and parts[3].startswith("b/"):
                a = parts[2][2:]
                b = parts[3][2:]
                target = b if b != "/dev/null" else a
                targets.append(target)
    unique_targets = sorted(set(targets))
    if len(unique_targets) != 1:
        raise SystemExit(f"ERROR: payload fragment must touch exactly one target file: {name} -> {unique_targets}")
manifest_text = manifest_file.read_text(errors="replace")
owns = []
required_tests = []
section = None
for raw in manifest_text.splitlines():
    if re.match(r"^  owns:\s*$", raw):
        section = "owns"
        continue
    if re.match(r"^  required_tests:\s*$", raw):
        section = "required_tests"
        continue
    if re.match(r"^  [A-Za-z_]+:\s*$", raw) or re.match(r"^[A-Za-z_]+:\s*$", raw):
        section = None
        continue
    match = re.match(r"^  - (.+?)\s*$", raw)
    if match and section == "owns":
        owns.append(match.group(1))
    elif match and section == "required_tests":
        required_tests.append(match.group(1))

expected_series = [path.replace("/", "__") + ".patch" for path in owns]
missing_from_series = sorted(set(expected_series) - set(series))
extra_in_series = sorted(set(series) - set(expected_series))
if missing_from_series or extra_in_series:
    raise SystemExit(
        "ERROR: manifest owns/series drift: "
        f"missing_from_series={missing_from_series} extra_in_series={extra_in_series}"
    )
missing_required_tests = sorted(set(required_tests) - set(owns))
if missing_required_tests:
    raise SystemExit(f"ERROR: manifest required_tests not listed in owns: {missing_required_tests}")
print("hardening payload inputs ok; manifest/series consistency ok")
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
echo "Applying hardening payload from $series_display"
while IFS= read -r patch || [[ -n "$patch" ]]; do
  [[ -z "$patch" || "$patch" =~ ^[[:space:]]*# ]] && continue
  echo "  applying $patch"
  git apply --3way "$payload_dir/$patch"
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
"$python_bin" - "$payload_dir/manifest.yaml" <<'PY'
from pathlib import Path
import py_compile
import re
import sys

manifest = Path(sys.argv[1]).read_text()
paths: list[str] = []
current_section = None
for raw in manifest.splitlines():
    if re.match(r"^  owns:\s*$", raw):
        current_section = "owns"
        continue
    if re.match(r"^  [a-zA-Z_]+:\s*$", raw):
        current_section = None
        continue
    if current_section == "owns":
        match = re.match(r"^  - (.+?\.py)\s*$", raw)
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

echo "Running static security drift guards"
"$python_bin" - <<'PY'
from pathlib import Path
import ast
import re


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


aa = Path("agent/action_authority.py").read_text(errors="replace")
if re.search(r"if\s+trusted_text\s*:\s*\n\s*return\s+ActionAuthorityResult\(AuthorityDecision\.ALLOW", aa):
    fail("broad trusted-text allow path reintroduced in agent/action_authority.py")
if "read-only network target or transmitted data came from evidence-only untrusted context" not in aa:
    fail("read-only network fetch provenance/egress guard text missing")

tree = ast.parse(aa, filename="agent/action_authority.py")
classified = set()
exemptions = set()
for node in tree.body:
    names = set()
    value = None
    if isinstance(node, ast.Assign):
        names = {target.id for target in node.targets if isinstance(target, ast.Name)}
        value = node.value
    elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
        names = {node.target.id}
        value = node.value
    if "_TOOL_ACTION_CLASSES" in names and isinstance(value, ast.Dict):
        classified = {key.value for key in value.keys if isinstance(key, ast.Constant) and isinstance(key.value, str)}
    if "EXPLICIT_TOOL_EXEMPTIONS" in names and isinstance(value, ast.Dict):
        exemptions = {key.value for key in value.keys if isinstance(key, ast.Constant) and isinstance(key.value, str)}
if not classified:
    fail("could not statically read _TOOL_ACTION_CLASSES")
if "unclassified_dynamic_tool" in classified | exemptions:
    fail("dummy unclassified tool fixture was accidentally classified/exempted")

cs = Path("agent/context_safety.py").read_text(errors="replace")
if "render_model_visible_tool_result" not in cs or "EXPLICIT_TOOL_EXEMPTIONS" not in cs:
    fail("tool-result fencing/exemption alignment helper missing")
dispatch_text = Path("run_agent.py").read_text(errors="replace")
if "render_model_visible_tool_result" not in dispatch_text or "evaluate_action_authority" not in dispatch_text:
    fail("agent tool dispatch no longer invokes action gate and tool-result fencing")
if "instruction_override" not in cs or "prompt_disclosure" not in cs or "encoded_instruction_like_text" not in cs:
    fail("scanner quality regression coverage for public prompt-injection misses is missing")
print("static security drift guards ok")
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
  tests/gateway/test_reply_to_injection.py \
  tests/gateway/test_stt_config.py \
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
  tests/security/test_prompt_injection_public_corpus.py \
  tests/security/test_tool_result_promotion.py

echo "Hardening payload verification passed"
