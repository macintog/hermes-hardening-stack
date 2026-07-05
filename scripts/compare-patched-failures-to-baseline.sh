#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: compare-patched-failures-to-baseline.sh [options] PATCHED_FAILED_NODES [PATCHED_FAILED_NODES...]

Compares patched Docker pytest failed-node lists against the current clean
Hermes baseline.

Pass four accepted Docker pass files to compute the monotonic gate:
  stable patched-only failures = patched failed-in-4-of-4 minus clean failed-in-4-of-4
and red-flag instability:
  patched failed-in-1/2/3-of-4 minus clean union-failed-nodes

Passing one file is allowed for legacy union discovery only; it cannot produce
a monotonic gate decision or red-flag instability set.

Options:
  --baseline-dir DIR  Baseline directory. Defaults to the current four-pass clean baseline.
  --out-dir DIR       Output directory. Defaults to a timestamped directory under /tmp.
  -h, --help          Show this help.

Inputs may be either exact node ids or pytest summary lines starting with
"FAILED <node-id> - ...".
USAGE
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
baseline_dir="$repo_root/validation/runs/2026-04-30-clean-baseline-20260430T000228Z"
out_dir=""
input=""
inputs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline-dir)
      baseline_dir=${2:?ERROR: --baseline-dir requires a directory}
      shift 2
      ;;
    --out-dir)
      out_dir=${2:?ERROR: --out-dir requires a directory}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      inputs+=("$1")
      shift
      ;;
  esac
done

if [[ ${#inputs[@]} -eq 0 ]]; then
  usage >&2
  exit 1
fi

for input in "${inputs[@]}"; do
  if [[ ! -f "$input" ]]; then
    echo "ERROR: input file not found: $input" >&2
    exit 1
  fi
done

stable="$baseline_dir/failed-in-4-of-4.txt"
if [[ ! -f "$stable" ]]; then
  stable="$baseline_dir/known-bad-stable.txt"
fi
fringe="$baseline_dir/known-bad-fringe.txt"
clean_union="$baseline_dir/union-failed-nodes.txt"

if [[ ! -f "$stable" ]]; then
  echo "ERROR: missing stable baseline file: $stable" >&2
  exit 1
fi

if [[ ! -f "$fringe" ]]; then
  echo "ERROR: missing fringe baseline file: $fringe" >&2
  exit 1
fi

if [[ ! -f "$clean_union" ]]; then
  echo "ERROR: missing clean union baseline file: $clean_union" >&2
  exit 1
fi

if [[ -z "$out_dir" ]]; then
  out_dir="${TMPDIR:-/tmp}/hermes-regression-compare-$(date -u +%Y%m%dT%H%M%SZ)"
fi

mkdir -p "$out_dir"

normalized="$out_dir/patched-failed-nodes.normalized.txt"
minus_stable="$out_dir/patched-minus-known-bad-stable.txt"
stable_overlap="$out_dir/patched-overlap-known-bad-stable.txt"
fringe_overlap="$out_dir/patched-overlap-known-bad-fringe.txt"
regression_candidates="$out_dir/patched-regression-candidates-excluding-fringe.txt"
stable_patched_only="$out_dir/stable-patched-only-failures.txt"
stable_frequency="$out_dir/patched-failed-in-4-of-4.txt"
unstable_patched_only="$out_dir/unstable-patched-only-failures.txt"
red_flag_instability="$out_dir/red-flag-instability-clean-pass-to-patched-partial-fail.txt"

normalize_file() {
  sed -E \
    -e 's/^FAILED[[:space:]]+//' \
    -e 's/[[:space:]]-[[:space:]].*$//' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//' \
    "$1" | awk 'NF { print }' | sort -u
}

pass_files=()
idx=0
for input in "${inputs[@]}"; do
  idx=$((idx + 1))
  pass_file="$out_dir/pass-${idx}.normalized.txt"
  normalize_file "$input" > "$pass_file"
  pass_files+=("$pass_file")
done

cat "${pass_files[@]}" | sort -u > "$normalized"

if [[ ${#inputs[@]} -eq 4 ]]; then
  counts_file="$out_dir/patched-frequency-counts.txt"
  cat "${pass_files[@]}" | sort | uniq -c | awk '{ count=$1; $1=""; sub(/^[[:space:]]+/, ""); print count "\t" $0 }' > "$counts_file"
  for n in 1 2 3 4; do
    awk -F '\t' -v n="$n" '$1 == n { print $2 }' "$counts_file" > "$out_dir/patched-failed-in-${n}-of-4.txt"
  done
else
  : > "$stable_frequency"
fi

comm -23 "$normalized" <(sort -u "$stable") > "$minus_stable"
comm -12 "$normalized" <(sort -u "$stable") > "$stable_overlap"
comm -12 "$normalized" <(sort -u "$fringe") > "$fringe_overlap"
comm -23 "$minus_stable" <(sort -u "$fringe") > "$regression_candidates"

if [[ ${#inputs[@]} -eq 4 ]]; then
  comm -23 "$stable_frequency" <(sort -u "$stable") > "$stable_patched_only"
  {
    cat "$out_dir/patched-failed-in-1-of-4.txt"
    cat "$out_dir/patched-failed-in-2-of-4.txt"
    cat "$out_dir/patched-failed-in-3-of-4.txt"
  } | sort -u | comm -23 - <(sort -u "$stable") > "$unstable_patched_only"
  comm -23 "$unstable_patched_only" <(sort -u "$clean_union") > "$red_flag_instability"
else
  : > "$stable_patched_only"
  : > "$unstable_patched_only"
  : > "$red_flag_instability"
fi

summary="$out_dir/summary.txt"
{
  echo "inputs=${inputs[*]}"
  echo "baseline_dir=$baseline_dir"
  echo "normalized=$normalized"
  echo "pass_count=${#inputs[@]}"
  echo "patched_failed_count=$(wc -l < "$normalized" | tr -d ' ')"
  echo "known_bad_stable_overlap=$(wc -l < "$stable_overlap" | tr -d ' ')"
  echo "known_bad_fringe_overlap=$(wc -l < "$fringe_overlap" | tr -d ' ')"
  echo "patched_minus_known_bad_stable=$(wc -l < "$minus_stable" | tr -d ' ')"
  echo "regression_candidates_excluding_fringe=$(wc -l < "$regression_candidates" | tr -d ' ')"
  if [[ ${#inputs[@]} -eq 4 ]]; then
    echo "patched_failed_in_1_of_4=$(wc -l < "$out_dir/patched-failed-in-1-of-4.txt" | tr -d ' ')"
    echo "patched_failed_in_2_of_4=$(wc -l < "$out_dir/patched-failed-in-2-of-4.txt" | tr -d ' ')"
    echo "patched_failed_in_3_of_4=$(wc -l < "$out_dir/patched-failed-in-3-of-4.txt" | tr -d ' ')"
    echo "patched_failed_in_4_of_4=$(wc -l < "$stable_frequency" | tr -d ' ')"
    echo "stable_patched_only_failures=$(wc -l < "$stable_patched_only" | tr -d ' ')"
    echo "unstable_patched_only_failures=$(wc -l < "$unstable_patched_only" | tr -d ' ')"
    echo "red_flag_instability_clean_pass_to_patched_partial_fail=$(wc -l < "$red_flag_instability" | tr -d ' ')"
    echo "monotonic_gate_input=$stable_patched_only"
    echo "red_flag_instability_input=$red_flag_instability"
  else
    echo "monotonic_gate_input=not_available_without_four_pass_files"
    echo "red_flag_instability_input=not_available_without_four_pass_files"
  fi
  echo "out_dir=$out_dir"
} > "$summary"

cat "$summary"
