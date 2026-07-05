#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: verify-hermes-safe-fetch-context-payload.sh [--archive-mode] [--apply-only] [HERMES_CHECKOUT]

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
  --archive-mode     Verify an extracted copy of this payload repo without .git
                    metadata. Replaces tracked-file checks with file presence checks.
  --apply-only       Stop after validating payload inputs and applying the series.
                    Also available as VERIFY_APPLY_ONLY=1.
USAGE
}

archive_mode=${HERMES_PAYLOAD_ARCHIVE_MODE:-0}
apply_only=${VERIFY_APPLY_ONLY:-0}
checkout_arg=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --archive-mode)
      archive_mode=1
      shift
      ;;
    --apply-only)
      apply_only=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$checkout_arg" ]]; then
        echo "ERROR: multiple Hermes checkout paths provided: $checkout_arg and $1" >&2
        usage >&2
        exit 1
      fi
      checkout_arg=$1
      shift
      ;;
  esac
done
if [[ $# -gt 0 ]]; then
  if [[ -n "$checkout_arg" || $# -gt 1 ]]; then
    echo "ERROR: multiple Hermes checkout paths provided" >&2
    usage >&2
    exit 1
  fi
  checkout_arg=$1
fi

if [[ "$archive_mode" != "0" && "$archive_mode" != "1" ]]; then
  echo "ERROR: HERMES_PAYLOAD_ARCHIVE_MODE must be 0 or 1" >&2
  exit 1
fi
if [[ "$apply_only" != "0" && "$apply_only" != "1" ]]; then
  echo "ERROR: VERIFY_APPLY_ONLY must be 0 or 1" >&2
  exit 1
fi
if [[ -n "${VERIFY_CURRENT_UPSTREAM:-}" || -n "${APPLY_ONLY:-}" ]]; then
  echo "ERROR: stale verifier environment variables detected." >&2
  echo "Use HERMES_BASE_REF=origin/main and VERIFY_APPLY_ONLY=1, or pass --apply-only." >&2
  exit 1
fi

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

checkout=${checkout_arg:-${HERMES_CHECKOUT:-}}
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

select_python() {
  local root=$1
  if [[ -n "${PYTHON:-}" ]]; then
    printf '%s\n' "$PYTHON"
  elif [[ -x "$root/venv/bin/python" ]]; then
    printf '%s\n' "$root/venv/bin/python"
  elif [[ -x "$root/.venv/bin/python" ]]; then
    printf '%s\n' "$root/.venv/bin/python"
  elif [[ -x "$HOME/.hermes/hermes-agent/venv/bin/python" ]]; then
    printf '%s\n' "$HOME/.hermes/hermes-agent/venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  else
    command -v python
  fi
}

python_bin=$(select_python "$checkout")
manifest_meta_file=${TMPDIR:-/tmp}/hermes-safe-fetch-context-manifest-$$.json
public_sample_out=${PUBLIC_SAMPLE_OUT:-${TMPDIR:-/tmp}/hermes-safe-fetch-context-public-samples-$$.json}
public_sample_status=not_run
summary_emitted=0

base_ref_meta=$("$python_bin" - "$base_ref_file" "$series_file" "$payload_dir" <<'PY'
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
recorded_base_ref=$(printf '%s\n' "$base_ref_meta" | sed -n '1p')
active_base_ref=$base_ref
worktree=${TMPDIR:-/tmp}/hermes-safe-fetch-context-verify-$$
cleanup() {
  rm -f "$manifest_meta_file"
  if [[ -n "${worktree:-}" && -d "$worktree" && "${KEEP_WORKTREE:-0}" != "1" ]]; then
    git -C "$checkout" worktree remove --force "$worktree" >/dev/null 2>&1 || true
  elif [[ -n "${worktree:-}" && -d "$worktree" ]]; then
    echo "Keeping verification worktree: $worktree"
  fi
}
emit_summary() {
  local status=$1
  if [[ "$summary_emitted" == "1" ]]; then
    return
  fi
  summary_emitted=1
  "$python_bin" - "$status" "$recorded_base_ref" "$active_base_ref" "${recorded_base_commit:-}" "${active_base_commit:-}" "${current_upstream_ref:-}" "${current_upstream_commit:-}" "${series_count:-}" "${required_test_count:-}" "$public_sample_status" "$public_sample_out" "$worktree" "${KEEP_WORKTREE:-0}" "$archive_mode" "$apply_only" <<'PY'
import json
import sys

(
    status,
    recorded_base_ref,
    active_base_ref,
    recorded_base_commit,
    active_base_commit,
    current_upstream_ref,
    current_upstream_commit,
    series_count,
    required_test_count,
    public_sample_status,
    public_sample_out,
    worktree,
    keep_worktree,
    archive_mode,
    apply_only,
) = sys.argv[1:]
summary = {
    "status": status,
    "recorded_base_ref": recorded_base_ref,
    "active_base_ref": active_base_ref,
    "public_sample_status": public_sample_status,
    "archive_mode": archive_mode == "1",
    "apply_only": apply_only == "1",
}
if recorded_base_commit:
    summary["recorded_base_commit"] = recorded_base_commit
if active_base_commit:
    summary["active_base_commit"] = active_base_commit
if current_upstream_ref:
    summary["current_upstream_ref"] = current_upstream_ref
if current_upstream_commit:
    summary["current_upstream_commit"] = current_upstream_commit
if series_count:
    summary["series_count"] = int(series_count)
if required_test_count:
    summary["required_test_count"] = int(required_test_count)
if public_sample_status not in {"not_run", "skipped_apply_only"}:
    summary["public_sample_out"] = public_sample_out
if keep_worktree == "1":
    summary["kept_worktree_path"] = worktree
print("VERIFIER_SUMMARY_JSON " + json.dumps(summary, sort_keys=True, separators=(",", ":")))
PY
}
on_exit() {
  local status=$?
  if [[ "$status" -ne 0 ]]; then
    public_sample_status=${public_sample_status:-failed_before_public_samples}
    emit_summary failed
  fi
  cleanup
}
trap on_exit EXIT

git -C "$checkout" rev-parse --verify "$base_ref^{commit}" >/dev/null
active_base_commit=$(git -C "$checkout" rev-parse --verify "$base_ref^{commit}")
recorded_base_commit=$(git -C "$checkout" rev-parse --verify "$recorded_base_ref^{commit}")
current_upstream_ref=${HERMES_CURRENT_UPSTREAM_REF:-origin/main}
if git -C "$checkout" rev-parse --verify "$current_upstream_ref^{commit}" >/dev/null 2>&1; then
  current_upstream_commit=$(git -C "$checkout" rev-parse --verify "$current_upstream_ref^{commit}")
else
  current_upstream_ref=""
  current_upstream_commit=""
fi
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
"$python_bin" - "$payload_dir" "$series_file" "$manifest_meta_file" <<'PY'
from pathlib import Path
import json
import sys

payload_dir = Path(sys.argv[1])
series_file = Path(sys.argv[2])
manifest_meta_file = Path(sys.argv[3])
manifest_file = payload_dir / "manifest.yaml"
if not manifest_file.exists():
    raise SystemExit(f"ERROR: missing manifest: {manifest_file}")

def load_manifest(path: Path):
    text = path.read_text(errors="replace")
    try:
        import yaml  # type: ignore
    except ImportError:
        return load_manifest_fallback(text, path)
    data = yaml.safe_load(text)
    if not isinstance(data, dict):
        raise SystemExit(f"ERROR: manifest root must be a mapping: {path}")
    return data

def load_manifest_fallback(text: str, path: Path):
    data: dict[str, object] = {}
    current_top = ""
    current_payload_list = ""
    for line_no, raw in enumerate(text.splitlines(), 1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if ":" not in stripped:
            if indent == 2 and current_top == "payload" and current_payload_list and stripped.startswith("- "):
                payload = data.setdefault("payload", {})
                if not isinstance(payload, dict):
                    raise SystemExit(f"ERROR: manifest payload must be a mapping at {path}:{line_no}")
                target = payload.setdefault(current_payload_list, [])
                if not isinstance(target, list):
                    raise SystemExit(f"ERROR: manifest payload.{current_payload_list} must be a list at {path}:{line_no}")
                target.append(stripped[2:].strip().strip("'\""))
                continue
            raise SystemExit(f"ERROR: unsupported manifest scalar at {path}:{line_no}")
        key, value = [part.strip() for part in stripped.split(":", 1)]
        if indent == 0:
            current_top = key
            current_payload_list = ""
            data[key] = value.strip("'\"") if value else {}
            continue
        if indent == 2 and current_top == "payload":
            payload = data.setdefault("payload", {})
            if not isinstance(payload, dict):
                raise SystemExit(f"ERROR: manifest payload must be a mapping at {path}:{line_no}")
            payload[key] = value.strip("'\"") if value else []
            current_payload_list = key if not value else ""
            continue
        if indent == 2 and current_top:
            container = data.setdefault(current_top, {})
            if isinstance(container, dict):
                container[key] = value.strip("'\"") if value else {}
            continue
        raise SystemExit(f"ERROR: unsupported manifest indentation at {path}:{line_no}")
    return data

manifest = load_manifest(manifest_file)
payload = manifest.get("payload")
if not isinstance(payload, dict):
    raise SystemExit("ERROR: manifest payload must be a mapping")
owns = payload.get("owns")
required_tests = payload.get("required_tests")
if not isinstance(owns, list) or not all(isinstance(path, str) for path in owns):
    raise SystemExit("ERROR: manifest payload.owns must be a list of strings")
if not isinstance(required_tests, list) or not all(isinstance(path, str) for path in required_tests):
    raise SystemExit("ERROR: manifest payload.required_tests must be a list of strings")

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
manifest_meta_file.write_text(json.dumps({
    "owns": owns,
    "required_tests": required_tests,
    "series": series,
    "series_count": len(series),
    "required_test_count": len(required_tests),
}, sort_keys=True) + "\n")
print("hardening payload inputs ok; manifest/series consistency ok")
PY
series_count=$("$python_bin" -c 'import json,sys; print(json.load(open(sys.argv[1]))["series_count"])' "$manifest_meta_file")
required_test_count=$("$python_bin" -c 'import json,sys; print(json.load(open(sys.argv[1]))["required_test_count"])' "$manifest_meta_file")

echo "Checking patch targets against $base_ref"
"$python_bin" "$script_dir/check-new-file-targets-against-base.py" \
  "$checkout" \
  "$payload_dir" \
  --base-ref "$base_ref"

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
if [[ "$archive_mode" == "1" ]]; then
  missing_archive_paths=()
  for path in "${tracked_paths[@]}"; do
    if [[ ! -f "$patch_repo/$path" ]]; then
      missing_archive_paths+=("$path")
    fi
  done
  if [[ ${#missing_archive_paths[@]} -gt 0 ]]; then
    echo "ERROR: archive-mode payload files missing: ${missing_archive_paths[*]}" >&2
    exit 1
  fi
else
  git -C "$patch_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "ERROR: payload repo has no Git metadata; rerun with --archive-mode for extracted copies" >&2
    exit 1
  }
  git -C "$patch_repo" ls-files --error-unmatch "${tracked_paths[@]}" >/dev/null
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: verification worktree is not clean before patch apply" >&2
  git status --short >&2
  exit 1
fi

series_display="patches/hermes-safe-fetch-context/series"
echo "Applying hardening payload from $series_display"
apply_args=(--3way)
payload_conflict_mode_reason=""
if [[ "$active_base_commit" != "$recorded_base_commit" ]]; then
  payload_conflict_mode_reason="active base differs from recorded base"
elif [[ "$active_base_commit" == "$recorded_base_commit" ]]; then
  payload_conflict_mode_reason="active base is recorded payload base"
elif [[ -n "$current_upstream_commit" && "$active_base_commit" == "$current_upstream_commit" ]]; then
  payload_conflict_mode_reason="active base is current upstream"
fi
if [[ -n "$payload_conflict_mode_reason" ]]; then
  apply_args+=(--theirs)
  echo "Using payload-side apply mode ($payload_conflict_mode_reason): preserve hardening changes during three-way conflicts"
fi
while IFS= read -r patch || [[ -n "$patch" ]]; do
  [[ -z "$patch" || "$patch" =~ ^[[:space:]]*# ]] && continue
  echo "  applying $patch"
  git apply "${apply_args[@]}" "$payload_dir/$patch"
done < "$series_file"

if [[ "$apply_only" == "1" ]]; then
  public_sample_status=skipped_apply_only
  echo "Hardening payload apply-only verification passed"
  emit_summary passed
  exit 0
fi

echo "Running py_compile smoke checks"
"$python_bin" - "$manifest_meta_file" <<'PY'
from pathlib import Path
import json
import py_compile
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
paths: list[str] = []
for path in manifest["owns"]:
    if path.endswith(".py") and path not in paths:
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

echo "Running action-authority contract checks"
"$python_bin" "$patch_repo/validation/scripts/check_action_authority_contracts.py" --worktree "$worktree"

echo "Running targeted tests"
required_tests=()
while IFS= read -r required_test; do
  required_tests+=("$required_test")
done < <("$python_bin" - "$manifest_meta_file" <<'PY'
import json
from pathlib import Path
import sys

required_tests = json.loads(Path(sys.argv[1]).read_text())["required_tests"]

if not required_tests:
    raise SystemExit("ERROR: manifest payload.required_tests is empty")
for path in required_tests:
    print(path)
PY
)
"$python_bin" -m pytest -o 'addopts=' -q \
  -W "ignore:.*asyncio.get_event_loop_policy.*deprecated.*:DeprecationWarning" \
  -W "ignore::DeprecationWarning:tests.conftest" \
  "${required_tests[@]}"

echo "Running strict evidence-ledger validation tests"
HERMES_REQUIRE_EVIDENCE_LEDGER=strict "$python_bin" -m pytest -o 'addopts=' -q \
  tests/security/test_evidence_ledger_surface_matrix.py

echo "Running public-sample prompt-injection checks"
if "$python_bin" "$patch_repo/validation/scripts/run_public_sample_prompt_checks.py" \
  --worktree "$worktree" \
  --out "$public_sample_out"; then
  public_sample_status=passed
else
  public_sample_status=failed
  echo "ERROR: public-sample prompt-injection checks failed" >&2
  exit 1
fi

echo "Hardening payload verification passed"
emit_summary passed
