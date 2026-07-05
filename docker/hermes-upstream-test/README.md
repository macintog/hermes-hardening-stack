# Hermes upstream test container

This image is for qualifying an applied hardening payload against Hermes Agent's own test contract.

It follows upstream CI instead of the production Hermes runtime image:

- Python 3.11
- `uv`
- `ripgrep`
- Node/npm for browser and UI-adjacent imports
- Docker CLI only, copied from Docker's official CLI image, for Docker-environment tests and optional nested runtime checks

Use `scripts/qualify-hermes-patch-docker.sh` from the payload repo. The script applies the payload to a clean Hermes worktree, bind-mounts that worktree, prepares or reuses a dependency-hashed image, installs the wrapper-owned pytest runner dependency for optional `-n auto` overrides, refreshes the mounted editable install with `uv pip install --no-deps -e .`, and runs the reduced no-TTY upstream pytest comparator in an isolated container with a timeout guard.

The base image is local test infrastructure, not a shipped artifact. Rebuilds use `docker build --pull` so the base image and package indexes stay current. The image includes Docker CLI plugins such as `buildx`, and the wrapper forces `DOCKER_BUILDKIT=1` for host-side and nested Docker builds because current Hermes Dockerfiles use BuildKit-only `COPY --chmod` syntax. The prepared dependency image is disposable cache state tagged like `hermes-agent-upstream-test:py311-YYYYMMDD-DEPHASH-prepared`; it stores the heavy `.[all,dev]` install in `/opt/hermes-test-venv` and uses the named Docker volume `hermes-upstream-uv-cache` for uv downloads and builds. `DEPHASH` comes from the applied worktree's `pyproject.toml`, `uv.lock`, base image tag, this test Dockerfile, the wrapper script, and wrapper-owned test-runner dependencies, and image preparation is guarded by a host-side lock under `$TMPDIR/hermes-upstream-test-image-locks`.

For morning readiness and other all-day comparator setup, run `scripts/codex-hermes-docker-qa doctor` and `scripts/codex-hermes-docker-qa prepare` before the four-pass clean baseline fan-out. Record the prepared image tag, image id, and dependency hash, then let the baseline and later same-day Docker QA require or reuse that exact prepared image. Do not pass `--skip-prepared-image-build` unless the exact prepared image tag/hash has already been proven in the current session. Outside the daily preflight, the wrapper's default prepare-or-wait path remains safe: if the image is cold, the first broad worker prepares it and the rest wait on the lock.

The prepared image is a filesystem snapshot taken before pytest starts. Do not checkpoint or resume a live pytest/xdist container after `bringing up nodes`; every verification pass should still start a fresh test container and a fresh applied Hermes worktree. The wrapper removes each applied Hermes test worktree unless `--keep-worktree` is passed.
