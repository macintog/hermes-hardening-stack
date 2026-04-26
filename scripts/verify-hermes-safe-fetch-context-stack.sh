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

echo "Checking manifest/series/doc consistency"
playbook_file="$patch_repo/docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md"
python - "$stack_dir" "$series_file" "$playbook_file" "$script_dir/verify-hermes-safe-fetch-context-stack.sh" <<'PY'
from pathlib import Path
import re
import sys

stack_dir = Path(sys.argv[1])
series_file = Path(sys.argv[2])
playbook_file = Path(sys.argv[3])
verifier_file = Path(sys.argv[4])
manifest_file = stack_dir / "manifest.yaml"
if not manifest_file.exists():
    raise SystemExit(f"ERROR: missing manifest: {manifest_file}")
series = [line.strip() for line in series_file.read_text().splitlines() if line.strip() and not line.lstrip().startswith("#")]
manifest_text = manifest_file.read_text()

patch_blocks: list[dict[str, object]] = []
current: dict[str, object] | None = None
section: str | None = None
for raw in manifest_text.splitlines():
    if match := re.match(r"^  - file: (\S+\.patch)\s*$", raw):
        current = {"file": match.group(1), "owns": [], "required_tests": []}
        patch_blocks.append(current)
        section = None
        continue
    if current is None:
        continue
    if re.match(r"^    owns:\s*$", raw):
        section = "owns"
        continue
    if re.match(r"^    required_tests:\s*$", raw):
        section = "required_tests"
        continue
    if re.match(r"^    [a-zA-Z_]+:\s*$", raw):
        section = None
        continue
    if section in {"owns", "required_tests"}:
        if match := re.match(r"^      - (.+?)\s*$", raw):
            current[section].append(match.group(1))

REQUIRED_PATCHES = [
    "0001-context-safety-core.patch",
    "0002-safe-http-gateway-download-hardening.patch",
    "0003-customization-maintenance-tool.patch",
    "0004-provenance-action-authority-hardening.patch",
    "0005-tool-result-promotion-action-registry.patch",
]
manifest_patches = [str(block["file"]) for block in patch_blocks]
if series != manifest_patches:
    raise SystemExit(
        "ERROR: series/manifest patch order mismatch\n"
        f"series={series}\nmanifest={manifest_patches}"
    )
if series[:len(REQUIRED_PATCHES)] != REQUIRED_PATCHES:
    raise SystemExit(
        "ERROR: mandatory patch prefix changed; do not drop or reorder required hardening phases\n"
        f"expected_prefix={REQUIRED_PATCHES}\nactual={series}"
    )
for patch_name in series:
    patch_path = stack_dir / patch_name
    if not patch_path.exists():
        raise SystemExit(f"ERROR: series patch missing on disk: {patch_path}")
    if patch_path.stat().st_size == 0:
        raise SystemExit(f"ERROR: series patch is empty: {patch_path}")

required_phase_tuples = [
    ("context_promotion_scanning_and_fencing", "0001-context-safety-core.patch"),
    ("safe_fetch_remote_byte_ingress", "0002-safe-http-gateway-download-hardening.patch"),
    ("patch_stack_integrity_tooling", "0003-customization-maintenance-tool.patch"),
    ("artifact_quarantine_provenance_and_taint", "0004-provenance-action-authority-hardening.patch"),
    ("action_authority_regression_tests", "0004-provenance-action-authority-hardening.patch"),
    ("registry_action_classification", "0005-tool-result-promotion-action-registry.patch"),
    ("tool_result_promotion_policy", "0005-tool-result-promotion-action-registry.patch"),
]
phase_blocks: list[dict[str, str]] = []
current_phase: dict[str, str] | None = None
in_required_phases = False
for raw in manifest_text.splitlines():
    if raw == "required_phases:":
        in_required_phases = True
        continue
    if in_required_phases and raw and not raw.startswith("  "):
        in_required_phases = False
    if not in_required_phases:
        continue
    if match := re.match(r"^  - name: (\S+)\s*$", raw):
        current_phase = {"name": match.group(1)}
        phase_blocks.append(current_phase)
        continue
    if current_phase is not None:
        if match := re.match(r"^    patch: (\S+\.patch)\s*$", raw):
            current_phase["patch"] = match.group(1)
        elif match := re.match(r"^    mandatory: (true|false)\s*$", raw):
            current_phase["mandatory"] = match.group(1)
phase_map = {phase.get("name"): phase for phase in phase_blocks}
missing_phases = []
for name, patch_name in required_phase_tuples:
    phase = phase_map.get(name)
    if not phase or phase.get("patch") != patch_name or phase.get("mandatory") != "true":
        missing_phases.append({"name": name, "patch": patch_name, "mandatory": "true", "actual": phase})
if missing_phases:
    raise SystemExit(f"ERROR: manifest missing mandatory required phase mappings: {missing_phases}")

for block in patch_blocks:
    patch_name = str(block["file"])
    patch_path = stack_dir / patch_name
    patch_text = patch_path.read_text(errors="replace")
    diff_paths = set(re.findall(r"^diff --git a/(.*?) b/", patch_text, flags=re.MULTILINE))
    owned_paths = list(block["owns"])
    missing_owned = [path for path in owned_paths if path not in diff_paths]
    if missing_owned:
        raise SystemExit(
            f"ERROR: manifest owns paths missing from {patch_name} diff headers: {missing_owned}"
        )
def dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result

def extract_section(text: str, heading: str, next_heading_level: int = 2) -> str:
    pattern = re.compile(rf"^{'#' * next_heading_level} {re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"ERROR: playbook missing heading: {'#' * next_heading_level} {heading}")
    start = match.end()
    next_match = re.search(rf"^{'#' * next_heading_level} ", text[start:], flags=re.MULTILINE)
    end = start + next_match.start() if next_match else len(text)
    return text[start:end]

def extract_fenced_block_after(text: str, marker: str) -> str:
    marker_index = text.find(marker)
    if marker_index < 0:
        raise SystemExit(f"ERROR: playbook missing marker: {marker}")
    fence = re.search(r"```[^\n]*\n(.*?)\n```", text[marker_index:], flags=re.DOTALL)
    if not fence:
        raise SystemExit(f"ERROR: playbook missing fenced block after marker: {marker}")
    return fence.group(1)

def compare_ordered(label: str, expected: list[str], actual: list[str]) -> None:
    if expected != actual:
        raise SystemExit(
            f"ERROR: {label} does not match series\n"
            f"expected={expected}\nactual={actual}\n"
            f"missing={[item for item in expected if item not in actual]}\n"
            f"extra={[item for item in actual if item not in expected]}"
        )

def compare_sets(label: str, expected: list[str], actual: list[str]) -> None:
    expected_set = set(expected)
    actual_set = set(actual)
    if expected_set != actual_set:
        raise SystemExit(
            f"ERROR: {label} does not match manifest required_tests\n"
            f"missing={sorted(expected_set - actual_set)}\n"
            f"extra={sorted(actual_set - expected_set)}"
        )

if not playbook_file.exists():
    raise SystemExit(f"ERROR: missing playbook: {playbook_file}")
playbook_text = playbook_file.read_text()
patch_location_section = extract_section(playbook_text, "Patch stack location")
playbook_patch_list = dedupe(re.findall(r"patches/hermes-safe-fetch-context/(\S+\.patch)`?", patch_location_section))
compare_ordered("playbook patch stack location", series, playbook_patch_list)

refresh_block = extract_fenced_block_after(playbook_text, "Refresh `series` and `base.ref`:")
refresh_series = re.findall(r"^\s*(\d{4}-\S+\.patch)\s*\\\\?$", refresh_block, flags=re.MULTILINE)
compare_ordered("playbook refresh series block", series, refresh_series)

manifest_required_tests = dedupe(
    test
    for block in patch_blocks
    for test in list(block["required_tests"])
)
playbook_tests_block = extract_fenced_block_after(playbook_text, "Targeted test set:")
playbook_tests = dedupe(re.findall(r"tests/[\w./-]+\.py(?:::[\w.\[\]-]+)?", playbook_tests_block))
playbook_tests = dedupe([test.split("::", 1)[0] for test in playbook_tests])
compare_sets("playbook targeted tests", manifest_required_tests, playbook_tests)

verifier_text = verifier_file.read_text()
verifier_tests_match = re.search(
    r"echo \"Running targeted tests\"\n(?P<cmd>.*?tests/security/test_tool_result_promotion\.py)",
    verifier_text,
    flags=re.DOTALL,
)
if not verifier_tests_match:
    raise SystemExit("ERROR: verifier targeted test command missing or does not include tests/security/test_tool_result_promotion.py")
verifier_tests = dedupe(re.findall(r"tests/[\w./-]+\.py", verifier_tests_match.group("cmd")))
compare_sets("verifier targeted tests", manifest_required_tests, verifier_tests)

print("manifest/series/doc consistency ok")
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
