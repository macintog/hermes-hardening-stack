# Docker upstream qualification methodology

Purpose: find the exact Hermes breakages introduced by the hardening payload during broad qualification sweeps. Counts, green or red summaries, and dashboard color are only navigation aids. The durable evidence is the node-id-level difference between a clean unpatched Hermes baseline and the same Hermes tree with the payload applied.

Hermes upstream tests live in `https://github.com/NousResearch/hermes-agent`. Use the local checkout at `<hermes-checkout>` for piecemeal analysis and focused verification.

There are two Docker lanes. Keep them separate:

- Public Hermes Docker baseline: the normal upstream Docker CI path. Use this when the question is "does this match how public Hermes tests Docker?"
- Downstream broad payload comparator: this repo's heavier clean-vs-patched full-suite inventory path. Use this only when the question is "which upstream unit tests did the hardening payload break?"

Do not substitute the downstream broad comparator for the public Hermes Docker baseline.

## Public Hermes Docker baseline, ready to run

This is the exact normal Docker-testing baseline used by public Hermes CI as of local upstream `origin/main` `19d4174454624a1ca91bc47b8f2a7ae8c3b4b5d3`.

Authority surfaces:

- `<hermes-checkout>/.github/workflows/docker.yml`: builds the Docker image for the matrix platform, loads it into the local daemon as `nousresearch/hermes-agent:test`, sets `HERMES_TEST_IMAGE` to that tag, blanks live API keys, then runs `scripts/run_tests.sh tests/docker/ --file-timeout 600`.
- `<hermes-checkout>/tests/docker/conftest.py`: when `HERMES_TEST_IMAGE` is set, `built_image` returns that prebuilt image tag instead of rebuilding `hermes-agent-harness:latest`.
- `<hermes-checkout>/scripts/run_tests.sh`: the normal test runner. It runs the per-file isolated `run_tests_parallel.py` harness in a clean environment.

Local ready-to-go command from a clean public Hermes checkout:

```bash
cd <hermes-checkout>
docker buildx build --load \
  --platform linux/$(uname -m | sed 's/x86_64/amd64/; s/arm64/arm64/') \
  --build-arg HERMES_GIT_SHA="$(git rev-parse HEAD)" \
  -t nousresearch/hermes-agent:test \
  .
uv python install 3.11
uv sync --locked --python 3.11 --extra dev
HERMES_TEST_IMAGE=nousresearch/hermes-agent:test \
OPENROUTER_API_KEY= \
OPENAI_API_KEY= \
NOUS_API_KEY= \
scripts/run_tests.sh tests/docker/ --file-timeout 600
```

For exact GitHub matrix parity, run that build/test pair once with `--platform linux/amd64` and once with `--platform linux/arm64` on hosts or builders that support both platforms. The public workflow's Docker test command is the same in both matrix legs.

If the image is already built and loaded under `nousresearch/hermes-agent:test`, rerun only:

```bash
cd <hermes-checkout>
HERMES_TEST_IMAGE=nousresearch/hermes-agent:test \
OPENROUTER_API_KEY= \
OPENAI_API_KEY= \
NOUS_API_KEY= \
scripts/run_tests.sh tests/docker/ --file-timeout 600
```

This baseline is Docker-specific. It does not run `pytest tests/` and it does not use this repo's broad Docker comparator.

## Mechanism-Level Learning

The active-user-intent correction showed why Docker belongs in the judgment loop. Focused local pytest sampled three failing rows and protected the positive propagation invariant, but the full Docker matrix revealed the real impact: one mechanism-level compatibility fix removed all 39 active-user-intent failures. That was a 13x queue collapse from the focused slice.

Use focused proof to understand a failure mechanism. Use Docker to learn whether that mechanism-level explanation generalizes across the upstream suite. A full matrix can close more work than the local slice proves, or reveal new candidates that the slice could not see. Both outcomes are useful evidence.

## Core comparison rule

Compare by exact pytest node id first, then by failure frequency across the four passes, then by failure reason.

Keep the words precise. A failure is contract-relative: a clean or patched run can fail the expected behavior. A regression is comparator-relative: patched is worse than clean, or introduces a failure clean did not have. A patched failure is ours to triage, but it is not automatically a regression when clean also fails or when patched is intentionally stricter with accepted security rationale.

For human-facing status, lead with breakage. The plain-language phrase is "Docker test cases our changes broke" or "test cases still broken by the payload." The technical set name "stable patched-only" is only the calculation label for those broken tests after subtracting clean-baseline failures; do not use it as the main status phrase because it can hide the fact that our patch is breaking tests.

For every run wave, preserve:

- raw Docker log
- pytest terminal summary
- normalized failed node ids
- failed node ids with the first reported reason
- command line, Docker image tag and image id
- Hermes base commit
- payload verifier summary, including `series_count` and `required_test_count`
- start/end times and wall time

Derived counts are valid only after the exact node-id sets are written down. A statement like "20 overlap" must be backed by the actual 20 node ids.

## Monotonic improvement rule

The broad Docker lifecycle pursues monotonic improvement in stable testcases, not in union size.

Use the four worker passes as a stability filter:

- If a node id fails in all four accepted passes, it is a stable failure for that wave.
- If a node id fails in one, two, or three accepted passes, it is unstable evidence. Track it by frequency, but do not call it a stable broken testcase unless focused proof or a later four-pass wave makes it stable.
- If that unstable node id passed all four clean baseline runs, it is a red-flag instability. Red flag means "do not handwave": keep it visible, compare it across later accepted waves, and escalate it to focused proof if it persists, grows in frequency, or touches the changed surface.
- Subtract the clean baseline's `failed-in-4-of-4.txt` from the patched wave's 4/4 set. The result is the Docker test cases our changes broke. In calculation tables this is the stable patched-only failure set.

The primary progress number for a patched Docker wave is:

```text
Docker test cases our changes broke = patched failed-in-4-of-4 - clean failed-in-4-of-4
```

Every Docker qualification pass note must compare that set to the previous accepted wave:

```text
previous broken Docker test cases: <N>
current broken Docker test cases: <N>
newly broken test cases: <exact ids>
fixed broken test cases: <exact ids>
red-flag instability node ids: <exact ids that clean-passed 4/4 and patched-failed 1/4-3/4>
decision: improved | neutral | failed_monotonic_gate
```

Interpretation:

- `improved`: fewer Docker test cases are broken by our changes, with no unexplained newly broken stable additions.
- `neutral`: the broken-test count is unchanged. This is acceptable only when the pass was a validation/checkpoint run or when the target was not a stable 4/4 broken test.
- `failed_monotonic_gate`: more Docker test cases are broken by our changes. Stop new cluster work. The next task is to explain, reclassify, revert, or fix the newly broken node ids.

Do not use union deltas as the monotonic gate. A node that appears once in four runs is not equivalent to a node that fails in all four. When discussing union changes, state the frequency bucket and whether the node clean-passed 4/4.

## Downstream broad payload comparator

This is not the public Hermes Docker baseline. Use the reduced no-TTY matrix only for broad upstream clean-vs-patched payload comparison. Morning readiness pins the day's Docker comparator: fetch upstream once, choose that base commit for the day, warm the prepared dependency image once, then fan out the four clean baseline passes. Hermes may move again during the day; do not chase intraday churn for ordinary Docker QA. Compare later same-day patched Docker runs against the active daily baseline unless the operator explicitly asks to rebaseline.

The default broad-wave posture is one-shot after the morning preflight: use `scripts/codex-hermes-docker-qa doctor` and `scripts/codex-hermes-docker-qa prepare` to prove the local authority surface and prepared image, then launch worker passes through the wrapper with the proven prepared image and avoid repeating dependency downloads. If the dependency image is cold outside morning readiness, the harness prepares it once and the rest wait on the wrapper lock; if it already exists, all workers reuse it. Every pass still uses a fresh applied worktree.

From Codex, run the harness authority checks under local authority at the first attempt. Docker socket access, `.codex/qa/index.sqlite` writes, loopback binds, and verifier temp-worktree writes are known seatbelt sandbox blockers. The harness reports `local_authority_required` if it is accidentally run in the sandbox, but the normal lane should not spend a probe on that.

Morning harness-owned warmup:

```bash
./scripts/codex-hermes-docker-qa doctor
./scripts/codex-hermes-docker-qa prepare --base-ref <morning-base-commit>
./scripts/codex-hermes-docker-qa facts
./scripts/codex-hermes-docker-qa clean-baseline-plan --queue-file /tmp/hermes-docker-clean-baseline-queue.json
./scripts/codex-hermes-docker-qa clean-baseline-finalize --run-dir validation/runs/<clean-baseline-run-id>
./scripts/codex-hermes-docker-qa worker-command
./scripts/codex-hermes-docker-qa worker-plan --plan-kind shard --queue-file /tmp/hermes-docker-shard-queue.json
./scripts/codex-hermes-docker-qa worker-plan --plan-kind repeat --queue-file /tmp/hermes-docker-repeat-queue.json
```

If the morning baseline is the payload-recorded `base.ref`, omit `--base-ref` from `prepare` too. If the morning baseline is a fetched upstream commit, pass that commit to `prepare` once. Do not pass `origin/main` or a newer commit to later `worker-command` or `worker-plan` calls just because Hermes moved; those commands must reuse the facts baseline.

The prepared image is tagged `hermes-agent-upstream-test:py311-YYYYMMDD-DEPHASH-prepared` by default. `DEPHASH` is computed from the applied worktree's `pyproject.toml`, `uv.lock`, base image tag, test Dockerfile, and wrapper-owned test-runner dependencies such as `pytest-xdist`, and the image receives a matching `hermes.test.dependency_hash` label. It is valid cache state, not result evidence. It captures dependency install filesystem state before pytest starts; harness or wrapper command-runner edits do not change dependency filesystem state and must not force a new prepared image. Do not checkpoint or resume a live pytest/xdist container after `bringing up nodes`.

`prepare` writes `.codex/qa/current-docker-prepared-image.json` by default. That facts file is the current pass authority for `prepared_image`, `dependency_hash`, `image_id`, archive mode, `prepared_base_ref`, and the Docker QA source fingerprint. Worker commands generated from facts always pin the immutable prepared baseline with `--base-ref <prepared_base_ref>` and a stable `--run-label`, even if the local Hermes checkout or `origin/main` has moved since warmup. A supplied `--base-ref` must match the facts baseline exactly; otherwise the harness stops with `ATTENTION: prepared_image_base_mismatch` before launching a Docker worker. To intentionally rebaseline, run `prepare --base-ref <new-base>` and then regenerate workers from the new facts without passing `--base-ref`.

The source fingerprint covers the harness script, low-level Docker wrapper, test Dockerfile, `series`, `manifest.yaml`, `base.ref`, any current-upstream marker file, and every patch fragment named by `series`. `facts`, `worker-command`, `worker-plan`, and facts-backed `smoke` reject facts without a current matching dependency-affecting fingerprint and print the rerun-prepare command. Control-plane-only harness or wrapper edits and current-upstream marker churn are allowed to reuse the prepared image because they do not change the dependency filesystem captured by the image. Facts-backed worker commands pass `HERMES_TEST_ALLOW_PREPARED_IMAGE_HASH_MISMATCH=1` only after the harness has accepted the facts file and exact Docker image ID; the raw wrapper still rejects dependency-label mismatches by default. Worker commands should be generated from the facts file with `worker-command`, `worker-plan --plan-kind shard`, or `worker-plan --plan-kind repeat` instead of hand-copying a prior tag. The generated command's run label names the pytest container; rerunning that same command after an interruption reattaches to the existing container instead of starting a duplicate. Use `prepare --archive-mode` or `HERMES_PAYLOAD_ARCHIVE_MODE=1 ./scripts/codex-hermes-docker-qa prepare` when the active dirty payload requires archive mode, then reuse the same facts file for workers. Run `prepare`, `worker-command`, and `worker-plan` from the same repo path; copied snapshots need their own prepare/facts cycle and must not reuse live-repo facts.

`clean-baseline-plan` is the first-class same-day stock baseline path after `prepare`. By default it prints four monolithic repeat passes of the approved broad Docker fixture against the same `prepared_image`, `image_id`, `dependency_hash`, and `prepared_base_ref` in the facts file, plus a `suggested_run_id`, `baseline_id`, `fixture`, `repeat_count`, per-pass container names, and recording metadata. Formal baselines need those repeat observations for stable/fringe failure buckets; use a smaller `--repeat-count` only for an explicitly provisional smoke. Use `--run-suffix <short-label>` when a corrective rerun needs a distinct run and baseline identity from an invalid or superseded record. Concurrency is separate: run up to as many worker-owned passes at once as machine headroom allows. Run the planned clean workers before patched comparison when the QA brief has no current same-day baseline for the facts date, base, image, and fixture shape. After workers finish, run `./scripts/codex-hermes-docker-qa clean-baseline-finalize --run-dir <run-dir>`. It writes `pass-N.failed-node-ids.txt`, stable/fringe bucket files, frequency and pass summaries, whitespace-normalization mappings, and `SUMMARY.md`, then emits the exact `codex-qa ingest run` and `codex-qa baseline establish` commands for that run directory. Those QA events, not `worker-plan`, are what make the same-day clean comparator visible to `codex-qa brief`.

`worker-plan --plan-kind shard` is a discovery-only scheduling plan: four disjoint avenues for locating where breakage lives. Shard outputs are not full-suite observations, are not comparable baselines, and must not be used to certify quality or close a Docker gate. `worker-plan --plan-kind repeat` is a stability plan: four full-pass runs over the same default upstream pytest scope. Use repeat runs, not shard outputs, to compute failed-in-1/2/3/4-of-4 buckets. Passing `--queue-file <path>` writes compact JSON with `max_parallel_workers=4`, facts path, source fingerprint, prepared image info, and pending items containing label, run label, plan kind, pytest args, command, and status.

Wrapper command shape for worker waves:

```bash
./scripts/qualify-hermes-patch-docker.sh \
  --skip-image-build \
  --base-ref <prepared_base_ref_from_facts> \
  --run-label <facts-backed-run-label> \
  <hermes-checkout>
```

Do not add `--skip-prepared-image-build` by hand. Generate broad worker commands from the current facts file so `--skip-prepared-image-build --prepared-image <prepared_image>` stays tied to the prepared tag, dependency hash, and image id proven for this pass. If no current facts file exists, omit `--skip-prepared-image-build` and let the wrapper prepare or wait under the lock.

Per-pass Docker command shape:

```bash
docker run --name "$CONTAINER" \
  -v "$WORKTREE:/workspace" \
  -w /workspace \
  -v hermes-upstream-uv-cache:/uv-cache \
  -e TERM=dumb \
  -e CI=1 \
  -e TZ=UTC \
  -e LANG=C.UTF-8 \
  -e LC_ALL=C.UTF-8 \
  -e PYTHONHASHSEED=0 \
  -e UV_CACHE_DIR=/uv-cache \
  -e UV_LINK_MODE=copy \
  -e OPENROUTER_API_KEY= \
  -e OPENAI_API_KEY= \
  -e NOUS_API_KEY= \
  hermes-agent-upstream-test:py311-YYYYMMDD-DEPHASH-prepared \
  bash -lc 'set -euo pipefail; source /opt/hermes-test-venv/bin/activate; uv pip install --no-deps -e .; python -m pytest tests/ -q --ignore=tests/integration --ignore=tests/e2e --ignore=tests/gateway/test_session.py --ignore=tests/hermes_cli/test_setup_model_provider.py --tb=short -ra'
```

Do not use anonymous `docker run --rm` for broad passes. The generated wrapper command uses the stable run label to name the container, and `clean-baseline-plan` emits per-pass container names. If a worker is interrupted, preserve logs from the named container or rerun the same generated command so it follows the existing container; do not launch an anonymous duplicate full pass. Do not use Docker `-t` or `-i` for the broad matrix. Do not use `--maxfail` for inventory runs. The goal is a complete failure inventory, not an early stop. If the prepared image path itself is broken and the run must proceed, the fallback is the old in-container install command with the same uv cache volume mounted; record that fallback explicitly because timing and dependency churn are no longer apples-to-apples with prepared-image runs.

The wrapper uses a host-side lock directory, `$TMPDIR/hermes-upstream-test-image-locks` by default, when preparing an image. Cold concurrent workers wait on that lock and recheck the image hash after the first worker commits the image.

## Parallel run cadence

Docker preflight, prepared-image proof, and narrow smoke are harness-owned through `scripts/codex-hermes-docker-qa`. Broad matrix Docker runs are worker-owned. The main thread must not run ad hoc broad Docker containers directly.

For every broad Docker container run outside the harness, spawn exactly one unforked worker with `agent_type="worker"`, `fork_context=false`, `model="gpt-5.5"`, and `reasoning_effort="medium"`. That worker owns the Docker command, raw log, summary extraction, and cleanup for that one run. The main thread owns scope, sequencing, comparison, documentation, and repo edits.

On the current workstation, a real wave may still run multiple Docker matrix runs with staggered kickoffs when the user asks for concurrency, but each run needs its own worker and its own applied worktree and log paths. Use 12 seconds between kickoffs unless the user specifies another cadence.

Worker rules:

- one worker owns one Docker run from kickoff through cleanup and report
- the worker must be launched unforked as GPT-5.5 with medium reasoning effort
- the worker prompt must state the payload Git posture: normal tracked-payload mode, or `HERMES_PAYLOAD_ARCHIVE_MODE=1` when `series` includes intentional untracked fragments in the current dirty payload
- create a fresh payload-applied Hermes worktree with apply-only verification
- never share a worktree between workers
- use the morning-readiness prepared image facts file when the exact tag/hash/id were recorded for the active daily baseline; otherwise use the wrapper's prepare-or-wait path and omit `--skip-prepared-image-build`
- keep up to four worker-owned Docker runs active from the applicable plan when the machine has headroom; refill freed slots with remaining or follow-up runs before waiting idly
- compute 4/4 stability buckets only from `worker-plan --plan-kind repeat`, `clean-baseline-plan`, or equivalent repeated full-pass runs, not from disjoint shard output
- write raw logs and extracted summaries before cleanup
- remove the worker's applied worktree only after extraction succeeds
- if a wrapper trap is interrupted, run `./scripts/codex-hermes-docker-qa cleanup-worktrees --force` from the patch repo before closeout
- do not edit payload repo files from workers
- do not push, commit, reset, clean, tag, delete refs, or contact remotes from workers
- treat nonzero pytest exit as expected evidence when failures are present, not as an infrastructure failure by itself
- report the exact command shape used, including whether Docker TTY was disabled
- keep full logs even when the summary extraction succeeds

The stagger matters because worktree creation, virtualenv setup, and package install all create short bursts of disk and CPU pressure. The stagger is not part of the security result; it is run hygiene.

## Focused verification outside Docker

Do not use Docker for ordinary one-node, one-file, or one-cluster analysis. For focused clean-vs-patched proof, run pytest directly in a local clean Hermes worktree and a local payload-applied worktree, using the checkout's Python environment.

Use this lane when:

- inspecting a patched-only failure mechanism
- proving a small correction
- checking a representative node id or narrow test file
- comparing clean versus patched behavior for upstream tests already present in the Hermes repository

Keep the same evidence discipline as Docker sweeps: exact pytest node ids, command line, base commit, payload commit or applied-worktree summary, first failure reason, and log path. Store durable notes under `validation/regression-triage/` when they affect the queue.

## Worker orchestration contract

Use `scripts/codex-hermes-docker-qa` for Docker authority preflight, prepared-image proof, and narrow smoke. Use workers for bounded broad Docker execution. The main thread owns methodology, comparison, repo edits, staging, commits, and final interpretation. If a broad Docker command is needed, the main thread prepares the exact task packet and delegates the run to the one-run Docker worker instead of invoking `docker` locally.

Each worker prompt should include:

- repo root and Hermes checkout path
- branch posture: validation only, no repo edits, preserve unrelated dirt
- authority posture: start `codex-qa`, Docker harness, payload verifier, and focused applied-tree pytest surfaces under local authority when they need generated QA-index writes, Docker socket access, loopback socket binds, or verifier temp-worktree writes; do not run a sandbox probe first
- harness posture: cite the `scripts/codex-hermes-docker-qa doctor` and `prepare` result when reusing local authority and prepared-image proof
- payload verification posture: use normal tracked-file verification only when every `series` fragment is tracked; use `HERMES_PAYLOAD_ARCHIVE_MODE=1` for dirty keeper payloads with intentional untracked fragments, and do not stage files as a setup workaround
- prepared-image posture: cite the active daily facts path plus prepared image tag, image id, and dependency hash when reusing it; otherwise default to prepare-or-wait by omitting `--skip-prepared-image-build`
- exact apply-only verifier command
- exact no-TTY Docker command
- required output paths for raw log, failed node ids, and failed reasons
- cleanup rule: remove only the worker's own applied worktree, after extraction
- final response shape

Each worker final response should include:

- pass label
- whether normal tracked-payload mode or archive-mode payload verification was used
- verifier status, `series_count`, and `required_test_count`
- kept worktree path and whether it was removed
- prepared image tag and image id
- prepared image dependency hash
- uv cache volume name
- Docker exit code
- pytest summary line
- wall time
- raw log path
- failed node-id list path
- failed node-plus-reason list path
- note that no repo files were edited

Verifier-applied worktrees are not durable proof after extraction. The durable proof is the raw log, normalized node lists, verifier summary, QA event, and patch repo commit. If a worktree was intentionally kept for focused inspection, remove it before the next QA gate unless the active task still needs it.

The main thread should normalize all worker outputs before comparing them. The previous three-pass run showed that one worker can return node ids with reasons while another returns node ids only; direct set comparison on those mixed files is invalid. Normalize from raw logs or enforce both extracted forms up front.

## Extraction requirements

Node-only lists are not enough. The most useful run artifacts preserve the failure reason from each `FAILED ... - ...` line, for example:

```text
tests/gateway/test_run_progress_topics.py::test_run_agent_progress_uses_event_message_id_for_slack_dm - TypeError: FakeAgent.run_conversation() got an unexpected keyword argument 'active_user_intent'
```

For each worker, extract both forms:

- `failed-nodes.txt`: exact pytest node ids only
- `failed-reasons.txt`: exact pytest node id plus first reported reason

Keep the raw log even when extraction succeeds. The reason line is a triage index, not a replacement for traceback context.

## Baseline discipline

Use the clean unpatched baseline as a comparator, not as a vague expectation.

For each patched wave:

1. Confirm the clean baseline command, image, and excludes match the patched wave.
2. Build patched frequency buckets from the four accepted pass files: failed in 1/4, 2/4, 3/4, and 4/4.
3. Compare the patched 4/4 bucket against the clean baseline 4/4 bucket:
   - clean-stable overlap
   - Docker test cases our changes broke, with the stable patched-only calculation label if needed
   - clean-stable not stable under patched runs
4. Record patched 1/4, 2/4, and 3/4 buckets separately as unstable evidence.
5. Subtract the clean baseline union from those unstable buckets to identify red-flag instability: tests that clean-passed 4/4 but patched-failed 1/4-3/4.
6. For every overlap claim, list the overlapping node ids.
7. Treat Docker test cases our changes broke in 4/4 patched passes as the first triage queue.
8. Treat one-off and partial-frequency nodes as load, order, or environment-sensitive until a focused rerun or later wave proves otherwise, but keep red-flag instability visible across waves.

For long-running cleanup, move patched-only failures into `validation/regression-triage/regressions.tsv` and follow `validation/regression-triage/README.md`. Do not keep the triage plan only in chat.

## Best next-run improvements

- Store run artifacts under a dated `validation/runs/` subdirectory instead of relying only on `/tmp` paths. Track concise summaries and exact set files; leave huge raw logs untracked if needed.
- Capture failed reasons for every worker, not just normalized node ids.
- Include Docker image id and Hermes base commit in each worker summary so later comparisons are apples to apples.
- Run the broad wave first for inventory, then follow with local focused family reruns on Docker test cases our changes broke in 4/4 patched passes.
- For focused reruns, run the same node ids against clean and patched local worktrees with comparable pytest command shape, then classify as existing baseline, intentional test-contract shift, or probable regression.
- Group broken patched-only failures by breakage mechanism, not by file alone. Useful families include API signature propagation, gateway media/document behavior, action-authority result shape, skill fetch hardening, delegation prompt contract, and true infrastructure flake.
- Keep `--tb=short -ra` for broad inventory. Use `-vv --tb=long` only for focused repros after the broad delta is known.

The closeout question for a real run is not "did the suite get greener?" It is "which exact previously passing Hermes behaviors are broken by this payload in Docker, did that broken set shrink, and are any remaining broken tests intentional, covered, and acceptable?"
