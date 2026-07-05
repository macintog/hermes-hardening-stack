# Hermes Agent hostile-content hardening payload

This repository packages downstream Hermes Agent changes that prevent prompt-injection text in external content from authorizing tool calls or changing what the agent is allowed to do.

The payload hardens three connected boundaries:

- safe fetch: validate user/platform-provided URLs, redirects, byte caps, credential redirects, and URL redaction
- context promotion: render downloaded, recalled, cron, skill, gateway, browser, and tool-result text as evidence with provenance
- action authority: require trusted scoped user/system/developer intent before side-effecting tools can write files, run commands, send messages, persist memory/cron state, use credentials, or act in a browser

It is a patch payload for a clean Hermes Agent checkout. It does not vendor, mirror, or fork Hermes Agent source.

License: MIT. See `LICENSE`.

Executable sources:

- `patches/hermes-safe-fetch-context/series` — apply order for final-state payload fragments
- `patches/hermes-safe-fetch-context/*.patch` — final-state deltas, one target file per fragment unless explicitly documented as an atomic group
- `patches/hermes-safe-fetch-context/base.ref` — recorded upstream base
- `patches/hermes-safe-fetch-context/manifest.yaml` — paths/tests covered by the hardening payload
- `scripts/verify-hermes-safe-fetch-context-payload.sh` — clean-base apply/test verifier

Human docs:

- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/INTENT.md`
- `docs/customizations/hermes-safe-fetch-context/SECURITY_MODEL.md`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- `docs/customizations/hermes-safe-fetch-context/HARDENING_SURFACE_INVENTORY.md`
- `docs/customizations/hermes-safe-fetch-context/OPEN_HARDENING_BACKLOG.md`
- `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`

Public publish scope:

- This public tree intentionally contains the patch payload, public docs, verifier/harness scripts, fixtures, and the already-public April sample artifacts.
- It intentionally excludes local agent handoff files, QA event stores, regression-triage internals, security-finding scratch records, and raw validation logs.
- `docs/customizations/hermes-safe-fetch-context/OPEN_HARDENING_BACKLOG.md` is the public status summary for hardening follow-ups.

Basic apply flow from a clean Hermes checkout:

```bash
cd "$HOME/.hermes/hermes-agent"

while read -r fragment; do
  [ -z "$fragment" ] && continue
  git apply --3way $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/$fragment
done < $HOME/.config/hermes-agent-patches/patches/hermes-safe-fetch-context/series
```

Verification applies the patch stack to a temporary Hermes worktree, runs every `payload.required_tests` entry from `patches/hermes-safe-fetch-context/manifest.yaml`, and then runs the public-sample prompt-injection checks:

```bash
cd <patch-repo>
PYTHON=<hermes-python> \
HERMES_CHECKOUT=<hermes-checkout> \
./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

The verifier removes its temporary applied worktree by default. Set `KEEP_WORKTREE=1` only when a follow-up inspection needs the applied tree, then remove verifier residue after evidence capture:

```bash
./scripts/cleanup-hermes-verifier-worktrees --remove --force
```

Upstream qualification runs the applied payload against Hermes Agent's own CI-style test command inside a Docker image:

```bash
cd <patch-repo>
./scripts/codex-hermes-docker-qa doctor
./scripts/codex-hermes-docker-qa prepare
./scripts/codex-hermes-docker-qa smoke
```

`scripts/codex-hermes-docker-qa` is the repo-owned control plane for Docker QA. It checks `codex-qa`, Docker socket access, and wrapper fixture drift before running containers; records prepared-image and smoke evidence in the QA store; and reports typed `PASS` / `ATTENTION` / `BLOCKED` results instead of raw rediscovery failures. From Codex, start `codex-qa`, Docker harness, payload verifier, and focused applied-tree pytest surfaces under local authority whenever they need generated QA-index writes, Docker socket access, loopback socket binds, or verifier temp-worktree writes. Do not run a sandbox probe first. The harness short-circuits accidental Codex seatbelt runs with `local_authority_required`.

The low-level wrapper uses a prepared dependency image by default. It still creates a fresh applied Hermes worktree for each run, but dependency downloads and wheel/build cache live in the named Docker volume `hermes-upstream-uv-cache`, and today's prepared image is tagged like `hermes-agent-upstream-test:py311-YYYYMMDD-DEPHASH-prepared`. `DEPHASH` is derived from the applied worktree's `pyproject.toml`, `uv.lock`, base image tag, the test Dockerfile, and wrapper-owned test-runner dependencies. Harness or wrapper command-runner edits do not change dependency filesystem state and must not force a new prepared image. A host-side lock under `$TMPDIR/hermes-upstream-test-image-locks` prevents cold worker waves from preparing the same image more than once. Each wrapper run also prunes label-matched Hermes prepared dependency images older than two days before payload apply; use `--no-prune-prepared-images` only for narrow debugging. For morning readiness, preflight this once with the harness before fanning out the four clean baseline passes:

```bash
./scripts/codex-hermes-docker-qa prepare
```

`prepare` writes the current pass facts to `.codex/qa/current-docker-prepared-image.json` by default. Use that file as the authority for the rest of the QA pass:

```bash
./scripts/codex-hermes-docker-qa facts
./scripts/codex-hermes-docker-qa clean-baseline-plan --queue-file /tmp/hermes-docker-clean-baseline-queue.json
./scripts/codex-hermes-docker-qa clean-baseline-finalize --run-dir validation/runs/<clean-baseline-run-id>
./scripts/codex-hermes-docker-qa worker-command
./scripts/codex-hermes-docker-qa worker-plan --plan-kind shard
./scripts/codex-hermes-docker-qa worker-plan --plan-kind repeat --queue-file /tmp/hermes-docker-repeat-queue.json
```

The printed worker command includes `--skip-prepared-image-build --prepared-image <prepared_image>`, an immutable `--base-ref <prepared_base_ref>` from the prepared-image facts, and a stable `--run-label` used to name the pytest container. The compact JSON includes the recorded dependency hash, image id, source fingerprint, run label, and local-authority rule. The facts baseline is the cache authority for the pass; omit `--base-ref` in later same-day worker generation so Hermes intraday movement does not invalidate the warmed image. If an operator intentionally wants a new baseline, rerun `prepare --base-ref <commit-or-ref>` once, then generate workers from the refreshed facts without passing `--base-ref`. A supplied `--base-ref` must match the facts baseline exactly, or the harness reports `ATTENTION: prepared_image_base_mismatch` before any Docker worker starts.

The fingerprint covers the harness script, low-level Docker wrapper, test Dockerfile, `series`, `manifest.yaml`, `base.ref`, any current-upstream marker file, and every patch fragment named by `series`. `facts`, `worker-command`, `worker-plan`, and facts-backed `smoke` reject missing or dependency-affecting stale fingerprints with a rerun-prepare command. Control-plane-only harness or wrapper edits and moving current-upstream marker files do not force a prepared-image rebuild when the existing facts still name the intended baseline. Facts-backed worker commands set `HERMES_TEST_ALLOW_PREPARED_IMAGE_HASH_MISMATCH=1` only after the harness has accepted the facts file and exact Docker image ID; do not set that env by hand for raw wrapper runs.

`clean-baseline-plan` is the same-day stock comparator path. By default it prints four monolithic repeat passes of the approved broad Docker fixture, tied to the prepared-image facts, because formal baselines need apples-to-apples stability evidence. Use a smaller `--repeat-count` only for an explicitly provisional smoke. Use `--run-suffix <short-label>` for corrective reruns that must not collide with an invalid or superseded baseline ID. Its compact JSON includes explicit baseline identity fields: `baseline_id`, `suggested_run_id`, `prepared_image`, `image_id`, `dependency_hash`, `prepared_base_ref`, `fixture`, `repeat_count`, per-pass container names, and `plan_kind=repeat`. After the clean workers finish, run `./scripts/codex-hermes-docker-qa clean-baseline-finalize --run-dir <run-dir>`. The finalize command writes `pass-N.failed-node-ids.txt`, `known-bad-stable.txt`, `known-bad-fringe.txt`, `failure-frequency.tsv`, `pass-summary.tsv`, `node-id-normalization.tsv`, and `SUMMARY.md`, then emits the exact `codex-qa ingest run` and `codex-qa baseline establish` commands for that run directory. Those steps record the day's clean baseline; shard output is discovery evidence only and must not be treated as baseline establishment.

`worker-plan --plan-kind shard` prints the four disjoint broad Docker avenues used to refill up to four worker slots while mapping breakage. `worker-plan --plan-kind repeat` prints four repeated full-pass runs over the same default upstream pytest scope; use repeat output for 4/4 stability buckets. `--queue-file <path>` writes the same pending items as compact JSON with `max_parallel_workers=4`, facts path, source fingerprint, prepared image info, item labels, run labels, `status=pending`, pytest args, command, and plan kind. If a worker or client is interrupted, rerun the same generated command or capture the named container's logs; do not start a hand-copied anonymous replacement. If the active payload is intentionally dirty because `series` references untracked fragments, run `prepare --archive-mode` or pass `HERMES_PAYLOAD_ARCHIVE_MODE=1`; the facts file records that posture and `worker-command` / `worker-plan` prefix broad worker commands with `HERMES_PAYLOAD_ARCHIVE_MODE=1`.

`doctor` also checks for stale verifier temp worktrees. If it reports `ATTENTION: stale_verifier_worktrees`, run:

```bash
./scripts/codex-hermes-docker-qa cleanup-worktrees --force
```

For broad upstream comparison, use the exact methodology in `validation/docker-upstream-methodology.md`. The goal is not a green count; it is an exact clean-versus-patched inventory by pytest node id and failure reason. Report stock failures, patched failures, and patched regressions as separate facts: failure is contract-relative, while regression is comparator-relative. Broad Docker matrix runs outside the harness are worker-owned: each container run gets one unforked GPT-5.5-medium worker with one fresh applied worktree, while the main thread manages sequencing, comparison, and documentation.

Current publish status:

- Payload base: `7b12753948acc373dab31eca481c3b8e6a6329ea`
- Series fragments: `108`
- Manifest-required tests: `55`
- Public root snapshot reproducibility evidence for commit `db5646b2ec21caebfea6a634e7bf630cd4149a29` is recorded in `validation/runs/2026-07-04-public-root-snapshot/SUMMARY.md`; no workflow-run proof was recorded in this repo for that snapshot.
- Latest broad Docker repeat is not fully green: `18` stable patched-only upstream pytest node IDs remain against the same-day clean baseline. The public payload is current, but it is not claimed as fully Docker-qualified.
- The 2026-05-02 security-finding queue is closed verified in the private QA store; public docs summarize the durable outcomes in `docs/customizations/hermes-safe-fetch-context/OPEN_HARDENING_BACKLOG.md`.

For iterative testing, the wrapper is disposable by default: it creates a fresh applied Hermes worktree, prepares or reuses the dependency image, runs the Docker test, then removes that worktree. Reuse the built base image and narrow pytest scope while editing patch fragments:

```bash
./scripts/qualify-hermes-patch-docker.sh \
  --skip-image-build \
  --pytest-args 'tests/tools/test_safe_http.py -q' \
  <hermes-checkout>
```

Use `--skip-prepared-image-build` only through a current facts file from `scripts/codex-hermes-docker-qa prepare`, or after this session has otherwise proven the exact prepared image tag/hash/id. Morning readiness should record that prepared tag/hash/id and reuse it for the four clean passes plus later same-day Docker QA. Otherwise leave the skip flag off; the wrapper's lock makes the cold path safe.

To run only the prepared-image cleanup without applying the payload or starting test containers:

```bash
./scripts/qualify-hermes-patch-docker.sh --prune-prepared-images-only
```

Useful broader gates:

```bash
./scripts/qualify-hermes-patch-docker.sh --targeted-payload-tests --e2e --image-smoke <hermes-checkout>
```
