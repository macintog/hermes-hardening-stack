#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: qualify-hermes-patch-docker.sh [options] [HERMES_CHECKOUT]

Applies the hardening payload to a clean Hermes worktree, then runs Hermes
upstream's own test recipe inside a Docker container.

Default:
  - apply payload to a temporary clean Hermes worktree
  - build the CI-style base test image if needed
  - prepare or reuse the dependency-hashed image with a named uv cache volume
  - refresh the mounted Hermes editable install without reinstalling dependencies
  - install the wrapper-owned pytest runner dependency available for -n auto overrides
  - run upstream unit tests:
      python -m pytest tests/ -q --ignore=tests/integration --ignore=tests/e2e --ignore=tests/gateway/test_session.py --ignore=tests/hermes_cli/test_setup_model_provider.py --tb=short -ra

Options:
  --targeted-payload-tests   Run this repo's verifier fully before upstream Docker tests.
                             Without this, the verifier runs in apply-only mode.
  --e2e                      Also run upstream tests/e2e after unit tests.
  --image-smoke              Also build the patched Hermes production image and run --help.
  --keep-worktree            Keep the applied Hermes worktree after the run.
  --prepare-only             Prepare the dependency-hashed image, then exit before pytest.
  --no-prepared-image        Legacy mode: install .[all,dev] inside every test container.
  --skip-image-build         Reuse an existing base test image.
  --skip-prepared-image-build
                             Require the prepared dependency image to already exist.
  --image NAME               Base test image tag. Default: hermes-agent-upstream-test:py311
  --prepared-image NAME      Prepared dependency image tag.
                             Default: <base-image>-<UTC YYYYMMDD>-<dependency hash>-prepared
  --prepared-lock-dir DIR    Host directory for prepared-image lock directories.
                             Default: $TMPDIR/hermes-upstream-test-image-locks
  --run-label LABEL          Stable label for the pytest container. Reusing the
                             label lets an interrupted wrapper reattach instead
                             of starting a duplicate full-suite container.
  --prepared-image-retention-days DAYS
                             Prune Hermes prepared dependency images older than DAYS.
                             Default: 2.
  --no-prune-prepared-images Disable automatic prepared-image pruning.
  --prune-prepared-images-only
                             Prune old prepared images, then exit before applying payload.
  --uv-cache-volume NAME     Docker volume used for uv downloads/build cache.
                             Default: hermes-upstream-uv-cache
  --tty                      Allocate Docker TTY for narrow interactive/debug runs.
  --base-ref REF             Base ref passed to payload verifier through HERMES_BASE_REF.
  --pytest-args ARGS         Override upstream unit pytest args.
  --print-plan               Print the resolved wrapper plan as compact JSON, then exit.
  -h, --help                 Show this help.

Environment:
  HERMES_CHECKOUT            Existing clean Hermes checkout. Defaults to the positional arg,
                             then <hermes-checkout>.
  HERMES_TEST_DOCKER_SOCKET  Docker socket to mount. Defaults to /var/run/docker.sock when present.
  HERMES_TEST_IMAGE_STAMP    Prepared-image date stamp. Defaults to UTC YYYYMMDD.
  HERMES_TEST_PREPARED_IMAGE Prepared dependency image tag.
  HERMES_TEST_PREPARED_LOCK_DIR
                             Host directory for prepared-image lock directories.
  HERMES_TEST_PREPARED_IMAGE_RETENTION_DAYS
                             Prepared dependency image retention window. Defaults to 2.
  HERMES_TEST_PRUNE_PREPARED_IMAGES=0
                             Disable automatic prepared-image pruning.
  HERMES_TEST_UV_CACHE_VOLUME
                             Docker volume used for uv downloads/build cache.
  HERMES_TEST_DOCKER_TTY=1   Same as --tty.
  HERMES_DOCKER_QA_RUN_LABEL Same as --run-label.
  HERMES_TEST_ALLOW_PREPARED_IMAGE_HASH_MISMATCH=1
                             Allow a facts-backed prepared image whose legacy
                             dependency label differs from the current wrapper
                             hash. Repo QA harness use only.
  KEEP_WORKTREE              Same as --keep-worktree when set to 1.
USAGE
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
patch_repo=$(cd -- "$script_dir/.." && pwd)
dockerfile="$patch_repo/docker/hermes-upstream-test/Dockerfile"

checkout_arg=""
run_targeted=0
run_e2e=0
run_image_smoke=0
keep_worktree=${KEEP_WORKTREE:-0}
prepare_only=0
use_prepared_image=1
skip_image_build=0
skip_prepared_image_build=0
prune_prepared_images=${HERMES_TEST_PRUNE_PREPARED_IMAGES:-1}
prepared_image_retention_days=${HERMES_TEST_PREPARED_IMAGE_RETENTION_DAYS:-2}
prune_prepared_images_only=0
docker_tty=${HERMES_TEST_DOCKER_TTY:-0}
allow_prepared_image_hash_mismatch=${HERMES_TEST_ALLOW_PREPARED_IMAGE_HASH_MISMATCH:-0}
print_plan=0
image_tag="hermes-agent-upstream-test:py311"
prepared_image_tag=${HERMES_TEST_PREPARED_IMAGE:-}
image_stamp=${HERMES_TEST_IMAGE_STAMP:-$(date -u +%Y%m%d)}
prepared_lock_dir=${HERMES_TEST_PREPARED_LOCK_DIR:-${TMPDIR:-/tmp}/hermes-upstream-test-image-locks}
uv_cache_volume=${HERMES_TEST_UV_CACHE_VOLUME:-hermes-upstream-uv-cache}
run_label=${HERMES_DOCKER_QA_RUN_LABEL:-}
base_ref=""
pytest_args=(tests/ -q --ignore=tests/integration --ignore=tests/e2e --ignore=tests/gateway/test_session.py --ignore=tests/hermes_cli/test_setup_model_provider.py --tb=short -ra)
wrapper_test_dependencies=(pytest-xdist==3.8.0)

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --targeted-payload-tests)
      run_targeted=1
      shift
      ;;
    --e2e)
      run_e2e=1
      shift
      ;;
    --image-smoke)
      run_image_smoke=1
      shift
      ;;
    --keep-worktree)
      keep_worktree=1
      shift
      ;;
    --prepare-only)
      prepare_only=1
      shift
      ;;
    --no-prepared-image)
      use_prepared_image=0
      shift
      ;;
    --skip-image-build)
      skip_image_build=1
      shift
      ;;
    --skip-prepared-image-build)
      skip_prepared_image_build=1
      shift
      ;;
    --image)
      image_tag=${2:?ERROR: --image requires a tag}
      shift 2
      ;;
    --prepared-image)
      prepared_image_tag=${2:?ERROR: --prepared-image requires a tag}
      shift 2
      ;;
    --prepared-lock-dir)
      prepared_lock_dir=${2:?ERROR: --prepared-lock-dir requires a directory path}
      shift 2
      ;;
    --prepared-image-retention-days)
      prepared_image_retention_days=${2:?ERROR: --prepared-image-retention-days requires a day count}
      shift 2
      ;;
    --no-prune-prepared-images)
      prune_prepared_images=0
      shift
      ;;
    --prune-prepared-images-only)
      prune_prepared_images_only=1
      shift
      ;;
    --uv-cache-volume)
      uv_cache_volume=${2:?ERROR: --uv-cache-volume requires a Docker volume name}
      shift 2
      ;;
    --run-label)
      run_label=${2:?ERROR: --run-label requires a label}
      shift 2
      ;;
    --tty)
      docker_tty=1
      shift
      ;;
    --base-ref)
      base_ref=${2:?ERROR: --base-ref requires a ref}
      shift 2
      ;;
    --pytest-args)
      IFS=' ' read -r -a pytest_args <<< "${2:?ERROR: --pytest-args requires an argument string}"
      shift 2
      ;;
    --print-plan)
      print_plan=1
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
    exit 1
  fi
  checkout_arg=$1
fi

case "$prepared_image_retention_days" in
  ''|*[!0-9]*)
    echo "ERROR: prepared image retention days must be a non-negative integer: $prepared_image_retention_days" >&2
    exit 1
    ;;
esac
emit_plan() {
  python3 - "$checkout_arg" "$image_tag" "$prepared_image_tag" "$image_stamp" "$prepared_lock_dir" "$uv_cache_volume" "$run_label" "$base_ref" "$docker_tty" "$use_prepared_image" "$prepare_only" "$allow_prepared_image_hash_mismatch" "${pytest_args[@]}" -- "${wrapper_test_dependencies[@]}" <<'PY'
import json
import sys

separator = sys.argv.index("--")
(
    checkout_arg,
    image_tag,
    prepared_image_tag,
    image_stamp,
    prepared_lock_dir,
    uv_cache_volume,
    run_label,
    base_ref,
    docker_tty,
    use_prepared_image,
    prepare_only,
    allow_prepared_image_hash_mismatch,
) = sys.argv[1:13]
pytest_args = sys.argv[13:separator]
wrapper_test_dependencies = sys.argv[separator + 1:]
payload = {
    "checkout_arg": checkout_arg,
    "docker_tty": docker_tty == "1",
    "image_stamp": image_stamp,
    "image_tag": image_tag,
    "allow_prepared_image_hash_mismatch": allow_prepared_image_hash_mismatch == "1",
    "prepare_only": prepare_only == "1",
    "prepared_lock_dir": prepared_lock_dir,
    "pytest_args": pytest_args,
    "run_label": run_label,
    "use_prepared_image": use_prepared_image == "1",
    "uv_cache_volume": uv_cache_volume,
    "wrapper_test_dependencies": wrapper_test_dependencies,
}
if base_ref:
    payload["base_ref"] = base_ref
if prepared_image_tag:
    payload["prepared_image_tag"] = prepared_image_tag
print("HERMES_DOCKER_QA_PLAN_JSON " + json.dumps(payload, sort_keys=True, separators=(",", ":")))
PY
}

if [[ "$print_plan" == "1" ]]; then
  emit_plan
  exit 0
fi

checkout=${checkout_arg:-${HERMES_CHECKOUT:-<hermes-checkout>}}
checkout=$(cd -- "$checkout" && pwd)

command -v docker >/dev/null 2>&1 || {
  echo "ERROR: docker CLI not found" >&2
  exit 1
}
docker version >/dev/null

if [[ ! -f "$dockerfile" ]]; then
  echo "ERROR: missing test Dockerfile: $dockerfile" >&2
  exit 1
fi

image_exists() {
  docker image inspect "$1" >/dev/null 2>&1
}

image_id() {
  docker image inspect --format '{{.Id}}' "$1" 2>/dev/null || true
}

image_label() {
  docker image inspect --format "{{ index .Config.Labels \"$2\" }}" "$1" 2>/dev/null || true
}

image_created_epoch() {
  local created
  created=$(docker image inspect --format '{{.Created}}' "$1" 2>/dev/null || true)
  python3 - "$created" <<'PY'
from datetime import datetime, timezone
import sys

value = sys.argv[1].strip()
if not value:
    print(0)
    raise SystemExit(0)
if value.endswith("Z"):
    value = value[:-1] + "+00:00"
if "." in value:
    head, tail = value.split(".", 1)
    offset = ""
    for marker in ("+", "-"):
        if marker in tail:
            fraction, offset = tail.split(marker, 1)
            offset = marker + offset
            break
    else:
        fraction = tail
    value = f"{head}.{fraction[:6]}{offset}"
try:
    parsed = datetime.fromisoformat(value)
except ValueError:
    print(0)
    raise SystemExit(0)
if parsed.tzinfo is None:
    parsed = parsed.replace(tzinfo=timezone.utc)
print(int(parsed.timestamp()))
PY
}

prune_old_prepared_images() {
  if [[ "$prune_prepared_images" == "0" ]]; then
    return
  fi

  local retention_seconds
  retention_seconds=$(( prepared_image_retention_days * 86400 ))
  local now_epoch
  now_epoch=$(date +%s)
  local cutoff_epoch=$(( now_epoch - retention_seconds ))
  local pruned=0
  local inspected=0
  local image_ref

  echo "Pruning Hermes prepared dependency images older than ${prepared_image_retention_days} day(s)"
  while IFS= read -r image_ref; do
    [[ -n "$image_ref" ]] || continue
    [[ "$image_ref" != "<none>:<none>" ]] || continue
    inspected=$(( inspected + 1 ))

    local title
    title=$(image_label "$image_ref" "org.opencontainers.image.title")
    [[ "$title" == "hermes-agent-upstream-test-prepared" ]] || continue

    local created_epoch
    created_epoch=$(image_created_epoch "$image_ref")
    [[ "$created_epoch" =~ ^[0-9]+$ ]] || created_epoch=0
    if [[ "$created_epoch" == "0" || "$created_epoch" -ge "$cutoff_epoch" ]]; then
      continue
    fi

    local image_id
    image_id=$(image_id "$image_ref")
    echo "Removing old Hermes prepared dependency image: $image_ref ${image_id:+($image_id)}"
    if docker image rm "$image_ref" >/dev/null; then
      pruned=$(( pruned + 1 ))
    else
      echo "WARNING: failed to remove old Hermes prepared dependency image: $image_ref" >&2
    fi
  done < <(docker image ls --format '{{.Repository}}:{{.Tag}}' --filter label=org.opencontainers.image.title=hermes-agent-upstream-test-prepared | sort -u)

  echo "Prepared-image prune inspected $inspected image tag(s), removed $pruned"
}

path_mtime() {
  python3 - "$1" <<'PY'
import os
import sys

try:
    print(int(os.stat(sys.argv[1]).st_mtime))
except OSError:
    print(0)
PY
}

container_slug() {
  python3 - "$1" <<'PY'
import re
import sys

value = sys.argv[1].strip()
value = re.sub(r"[^A-Za-z0-9_.-]+", "-", value).strip("-_.")
if not value:
    value = "run"
print(value[:96])
PY
}

container_exit_code() {
  docker inspect --format '{{.State.ExitCode}}' "$1" 2>/dev/null || echo 125
}

follow_existing_test_container() {
  local container_name=$1
  local status
  status=$(docker inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || true)
  if [[ -z "$status" ]]; then
    return 2
  fi

  echo "Found existing Hermes Docker QA container: $container_name status=$status"
  if [[ "$status" == "running" || "$status" == "restarting" ]]; then
    echo "Following existing Hermes Docker QA container instead of starting a duplicate: $container_name"
    docker logs --tail 0 -f "$container_name" &
    local logs_pid=$!
    local wait_output
    local wait_status
    set +e
    wait_output=$(docker wait "$container_name")
    wait_status=$?
    set -e
    kill "$logs_pid" >/dev/null 2>&1 || true
    wait "$logs_pid" >/dev/null 2>&1 || true
    if [[ "$wait_status" -ne 0 ]]; then
      return "$wait_status"
    fi
    local exit_code
    exit_code=$(printf '%s\n' "$wait_output" | tail -n 1)
    [[ "$exit_code" =~ ^[0-9]+$ ]] || exit_code=125
    docker rm "$container_name" >/dev/null 2>&1 || true
    return "$exit_code"
  fi

  docker logs "$container_name" || true
  local exit_code
  exit_code=$(container_exit_code "$container_name")
  [[ "$exit_code" =~ ^[0-9]+$ ]] || exit_code=125
  docker rm "$container_name" >/dev/null 2>&1 || true
  return "$exit_code"
}

prune_old_prepared_images
if [[ "$prune_prepared_images_only" == "1" ]]; then
  echo "Prepared-image prune only; skipping payload apply and tests"
  exit 0
fi

verifier_args=()
if [[ "$run_targeted" != "1" ]]; then
  verifier_args+=(--apply-only)
fi
verifier_env=(KEEP_WORKTREE=1)
if [[ -n "$base_ref" ]]; then
  verifier_env+=(HERMES_BASE_REF="$base_ref")
fi

verifier_log=${TMPDIR:-/tmp}/hermes-qualify-apply-$$.log
echo "Applying payload to clean Hermes worktree from $checkout"
if [[ ${#verifier_args[@]} -gt 0 ]]; then
  env "${verifier_env[@]}" "$patch_repo/scripts/verify-hermes-safe-fetch-context-payload.sh" "${verifier_args[@]}" "$checkout" | tee "$verifier_log"
else
  env "${verifier_env[@]}" "$patch_repo/scripts/verify-hermes-safe-fetch-context-payload.sh" "$checkout" | tee "$verifier_log"
fi

worktree=$(
  python3 - "$verifier_log" <<'PY'
import json
import sys
from pathlib import Path

for line in Path(sys.argv[1]).read_text(errors="replace").splitlines():
    if line.startswith("VERIFIER_SUMMARY_JSON "):
        summary = json.loads(line.split(" ", 1)[1])
        path = summary.get("kept_worktree_path")
        if path:
            print(path)
            raise SystemExit(0)
raise SystemExit("ERROR: verifier did not report kept_worktree_path")
PY
)

cleanup() {
  rm -f "$verifier_log"
  if [[ "$keep_worktree" != "1" && -n "${worktree:-}" && -d "${worktree:-}" ]]; then
    git -C "$checkout" worktree remove --force "$worktree" >/dev/null 2>&1 || true
  elif [[ -n "${worktree:-}" && -d "${worktree:-}" ]]; then
    echo "Keeping applied Hermes worktree: $worktree"
  fi
}
trap cleanup EXIT

dependency_hash() {
  python3 - "$worktree" "$image_tag" "$dockerfile" "${wrapper_test_dependencies[@]}" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
base_image = sys.argv[2]
infrastructure_paths = [Path(sys.argv[3])]
hasher = hashlib.sha256()
hasher.update(f"base_image\0{base_image}\0".encode())
for relative in ("pyproject.toml", "uv.lock"):
    path = root / relative
    hasher.update(f"path\0{relative}\0".encode())
    if path.exists():
        hasher.update(path.read_bytes())
    else:
        hasher.update(b"<missing>")
for path in infrastructure_paths:
    hasher.update(f"infrastructure_path\0{path}\0".encode())
    if path.exists():
        hasher.update(path.read_bytes())
    else:
        hasher.update(b"<missing>")
for dependency in sys.argv[4:]:
    hasher.update(f"wrapper_test_dependency\0{dependency}\0".encode())
print(hasher.hexdigest()[:16])
PY
}

prepared_dependency_hash=$(dependency_hash)
if [[ -z "$prepared_image_tag" ]]; then
  prepared_image_tag="${image_tag}-${image_stamp}-${prepared_dependency_hash}-prepared"
fi

prepared_image_is_current() {
  if ! image_exists "$prepared_image_tag"; then
    return 1
  fi
  local existing_dependency_hash
  existing_dependency_hash=$(image_label "$prepared_image_tag" "hermes.test.dependency_hash")
  [[ "$existing_dependency_hash" == "$prepared_dependency_hash" ]]
}

if [[ "$skip_image_build" != "1" ]]; then
  if [[ "$use_prepared_image" == "1" ]] && prepared_image_is_current; then
    echo "Reusing existing prepared dependency image; skipping base image build: $prepared_image_tag"
  else
    echo "Building Hermes upstream test image: $image_tag"
    DOCKER_BUILDKIT=1 docker build --pull -t "$image_tag" -f "$dockerfile" "$patch_repo/docker/hermes-upstream-test"
  fi
fi

base_docker_args=(run --rm)
if [[ "$docker_tty" == "1" ]]; then
  if [[ -t 0 ]]; then
    base_docker_args=(run -it --rm)
  else
    base_docker_args=(run -t --rm)
  fi
fi
base_docker_args+=(
  -v "$worktree:/workspace"
  -w /workspace
  -v "$uv_cache_volume:/uv-cache"
  -e TERM=dumb
  -e CI=1
  -e DOCKER_BUILDKIT=1
  -e COMPOSE_DOCKER_CLI_BUILD=1
  -e TZ=UTC
  -e LANG=C.UTF-8
  -e LC_ALL=C.UTF-8
  -e PYTHONHASHSEED=0
  -e UV_CACHE_DIR=/uv-cache
  -e UV_LINK_MODE=copy
  -e OPENROUTER_API_KEY=
  -e OPENAI_API_KEY=
  -e NOUS_API_KEY=
)

docker_socket=${HERMES_TEST_DOCKER_SOCKET:-}
if [[ -z "$docker_socket" && -S /var/run/docker.sock ]]; then
  docker_socket=/var/run/docker.sock
fi
if [[ -n "$docker_socket" ]]; then
  base_docker_args+=(-v "$docker_socket:/var/run/docker.sock")
fi

prepare_dependency_image() {
  local existing_dependency_hash=""
  if image_exists "$prepared_image_tag"; then
    existing_dependency_hash=$(image_label "$prepared_image_tag" "hermes.test.dependency_hash")
    if [[ "$existing_dependency_hash" != "$prepared_dependency_hash" ]]; then
      if [[ "$allow_prepared_image_hash_mismatch" == "1" ]]; then
        echo "Reusing facts-backed prepared Hermes dependency image despite legacy dependency label mismatch: $prepared_image_tag"
        echo "       current wrapper hash $prepared_dependency_hash, image label $existing_dependency_hash"
        return
      fi
      if [[ "$skip_prepared_image_build" == "1" ]]; then
        echo "ERROR: prepared dependency image has stale dependency hash: $prepared_image_tag" >&2
        echo "       expected $prepared_dependency_hash, found $existing_dependency_hash" >&2
        exit 1
      fi
      echo "Prepared dependency image has stale dependency hash; rebuilding tag: $prepared_image_tag"
    else
      echo "Reusing prepared Hermes dependency image: $prepared_image_tag"
      return
    fi
  elif [[ "$skip_prepared_image_build" == "1" ]]; then
    echo "ERROR: prepared dependency image does not exist: $prepared_image_tag" >&2
    exit 1
  fi

  mkdir -p "$prepared_lock_dir"
  local lock_key
  lock_key=$(printf '%s' "$prepared_image_tag" | tr -c 'A-Za-z0-9_.-' '_')
  local lock_path="$prepared_lock_dir/$lock_key.lock"
  local lock_acquired=0
  local lock_wait_start
  lock_wait_start=$(date +%s)
  while ! mkdir "$lock_path" 2>/dev/null; do
    if image_exists "$prepared_image_tag"; then
      existing_dependency_hash=$(image_label "$prepared_image_tag" "hermes.test.dependency_hash")
      if [[ "$existing_dependency_hash" == "$prepared_dependency_hash" ]]; then
        echo "Reusing prepared Hermes dependency image after lock wait: $prepared_image_tag"
        return
      fi
      if [[ "$allow_prepared_image_hash_mismatch" == "1" ]]; then
        echo "Reusing facts-backed prepared Hermes dependency image after lock wait despite legacy dependency label mismatch: $prepared_image_tag"
        echo "       current wrapper hash $prepared_dependency_hash, image label $existing_dependency_hash"
        return
      fi
      if [[ "$skip_prepared_image_build" == "1" ]]; then
        echo "ERROR: prepared dependency image has stale dependency hash after lock wait: $prepared_image_tag" >&2
        echo "       expected $prepared_dependency_hash, found $existing_dependency_hash" >&2
        exit 1
      fi
    fi
    local lock_age=0
    if [[ -d "$lock_path" ]]; then
      lock_age=$(( $(date +%s) - $(path_mtime "$lock_path") ))
    fi
    if [[ "$lock_age" -gt 7200 ]]; then
      echo "Removing stale prepared-image lock: $lock_path" >&2
      rm -rf "$lock_path"
      continue
    fi
    if [[ $(( $(date +%s) - lock_wait_start )) -gt 7200 ]]; then
      echo "ERROR: timed out waiting for prepared-image lock: $lock_path" >&2
      exit 1
    fi
    echo "Waiting for prepared-image lock: $lock_path"
    sleep 10
  done
  lock_acquired=1

  release_prepare_lock() {
    if [[ "$lock_acquired" == "1" ]]; then
      rm -rf "$lock_path"
      lock_acquired=0
    fi
  }

  if image_exists "$prepared_image_tag"; then
    existing_dependency_hash=$(image_label "$prepared_image_tag" "hermes.test.dependency_hash")
    if [[ "$existing_dependency_hash" == "$prepared_dependency_hash" ]]; then
      echo "Reusing prepared Hermes dependency image after acquiring lock: $prepared_image_tag"
      release_prepare_lock
      return
    fi
    if [[ "$allow_prepared_image_hash_mismatch" == "1" ]]; then
      echo "Reusing facts-backed prepared Hermes dependency image after acquiring lock despite legacy dependency label mismatch: $prepared_image_tag"
      echo "       current wrapper hash $prepared_dependency_hash, image label $existing_dependency_hash"
      release_prepare_lock
      return
    fi
    echo "Prepared dependency image has stale dependency hash after acquiring lock; rebuilding tag: $prepared_image_tag"
  fi

  local container_name="hermes-upstream-test-prep-$$"
  local prepare_docker_args=()
  local arg
  for arg in "${base_docker_args[@]}"; do
    if [[ "$arg" != "--rm" ]]; then
      prepare_docker_args+=("$arg")
    fi
  done
  echo "Preparing Hermes dependency image: $prepared_image_tag"
  printf -v wrapper_test_dependency_command '%q ' "${wrapper_test_dependencies[@]}"
  docker rm -f "$container_name" >/dev/null 2>&1 || true
  if ! docker "${prepare_docker_args[@]}" --name "$container_name" "$image_tag" bash -lc "
set -euo pipefail
uv venv /opt/hermes-test-venv --python 3.11
source /opt/hermes-test-venv/bin/activate
uv pip install -e '.[all,dev]'
uv pip install $wrapper_test_dependency_command
uv pip install --no-deps -e .
"; then
    docker rm -f "$container_name" >/dev/null 2>&1 || true
    release_prepare_lock
    echo "ERROR: failed to prepare Hermes dependency image: $prepared_image_tag" >&2
    exit 1
  fi
  if ! docker commit \
    --change "LABEL org.opencontainers.image.title=hermes-agent-upstream-test-prepared" \
    --change "LABEL hermes.test.base_image=$image_tag" \
    --change "LABEL hermes.test.prepared_stamp=$image_stamp" \
    --change "LABEL hermes.test.dependency_hash=$prepared_dependency_hash" \
    --change "ENV HERMES_TEST_PREPARED_IMAGE=1" \
    "$container_name" "$prepared_image_tag" >/dev/null; then
    docker rm -f "$container_name" >/dev/null 2>&1 || true
    release_prepare_lock
    echo "ERROR: failed to commit Hermes dependency image: $prepared_image_tag" >&2
    exit 1
  fi
  if ! docker rm "$container_name" >/dev/null; then
    release_prepare_lock
    echo "ERROR: failed to remove prepared-image container: $container_name" >&2
    exit 1
  fi
  release_prepare_lock
  echo "Prepared Hermes dependency image ready: $prepared_image_tag"
}

if [[ "$use_prepared_image" == "1" ]]; then
  prepare_dependency_image
  prepared_image_id=$(image_id "$prepared_image_tag")
  echo "Prepared dependency hash: $prepared_dependency_hash"
  if [[ -n "$prepared_image_id" ]]; then
    echo "Prepared dependency image id: $prepared_image_id"
  fi
  if [[ "$prepare_only" == "1" ]]; then
    echo "Prepared dependency image only; skipping pytest: $prepared_image_tag"
    exit 0
  fi
elif [[ "$prepare_only" == "1" ]]; then
  echo "ERROR: --prepare-only requires prepared images; remove --no-prepared-image" >&2
  exit 1
fi

run_in_test_image() {
  local phase=$1
  local test_command=$2
  local runtime_image=$image_tag
  if [[ "$use_prepared_image" == "1" ]]; then
    runtime_image=$prepared_image_tag
  fi

  local label=${run_label:-pid-$$}
  local container_name
  container_name="hermes-upstream-test-$(container_slug "$label")-$(container_slug "$phase")"
  local runtime_docker_args=()
  local arg
  for arg in "${base_docker_args[@]}"; do
    if [[ "$arg" != "--rm" ]]; then
      runtime_docker_args+=("$arg")
    fi
  done

  if docker container inspect "$container_name" >/dev/null 2>&1; then
    follow_existing_test_container "$container_name"
    return $?
  fi

  echo "HERMES_DOCKER_QA_CONTAINER $container_name"
  set +e
  docker "${runtime_docker_args[@]}" --name "$container_name" "$runtime_image" bash -lc "$test_command"
  local status=$?
  set -e
  if [[ "$status" == "125" ]] && docker container inspect "$container_name" >/dev/null 2>&1; then
    follow_existing_test_container "$container_name"
    return $?
  fi
  docker rm "$container_name" >/dev/null 2>&1 || true
  return "$status"
}

install_for_test_command() {
  printf -v wrapper_test_dependency_command '%q ' "${wrapper_test_dependencies[@]}"
  if [[ "$use_prepared_image" == "1" ]]; then
    cat <<'SH'
source /opt/hermes-test-venv/bin/activate
uv pip install --no-deps -e .
SH
  else
    cat <<SH
uv venv .venv --python 3.11
source .venv/bin/activate
uv pip install -e '.[all,dev]'
uv pip install $wrapper_test_dependency_command
SH
  fi
}

echo "Running upstream unit tests in Docker against patched worktree: $worktree"
if [[ "$use_prepared_image" == "1" ]]; then
  echo "Using prepared dependency image: $prepared_image_tag"
  echo "Using prepared dependency hash: $prepared_dependency_hash"
  if [[ -n "${prepared_image_id:-}" ]]; then
    echo "Using prepared dependency image id: $prepared_image_id"
  fi
else
  echo "Using legacy per-run dependency install in base image: $image_tag"
fi
echo "Using uv cache volume: $uv_cache_volume"
printf -v pytest_command '%q ' "${pytest_args[@]}"
run_in_test_image unit "
set -euo pipefail
$(install_for_test_command)
python -m pytest $pytest_command
"

if [[ "$run_e2e" == "1" ]]; then
  echo "Running upstream e2e tests in Docker"
  run_in_test_image e2e "
set -euo pipefail
$(install_for_test_command)
python -m pytest tests/e2e/ -v --tb=short
"
fi

if [[ "$run_image_smoke" == "1" ]]; then
  smoke_image="hermes-agent-patched:qualify"
  smoke_home=${TMPDIR:-/tmp}/hermes-image-smoke-$$
  mkdir -p "$smoke_home"
  echo "Building patched Hermes production image: $smoke_image"
  DOCKER_BUILDKIT=1 docker build -t "$smoke_image" "$worktree"
  echo "Running patched Hermes production image smoke"
  docker run --rm -v "$smoke_home:/opt/data" "$smoke_image" --help >/dev/null
  rm -rf "$smoke_home"
fi

echo "Hermes patch Docker qualification passed"
if [[ "$keep_worktree" == "1" ]]; then
  echo "Applied worktree kept: $worktree"
else
  echo "Applied worktree was temporary; pass --keep-worktree to inspect it after the run"
fi
