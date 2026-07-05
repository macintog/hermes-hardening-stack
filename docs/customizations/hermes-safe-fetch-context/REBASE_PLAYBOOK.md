# Rebase playbook

## Rule

Main is the only live source of truth. Do not preserve earlier payload shapes, compatibility wrappers, historical patch layering, or migration notes in the active artifact. If an older state matters, inspect git history.

## Goal

Keep the hardening payload applying cleanly to upstream Hermes while preserving the current security invariants in `README.md`, `INTENT.md`, `SECURITY_MODEL.md`, and `SURFACE_MAP.md`.

## Canonical files

- `patches/hermes-safe-fetch-context/base.ref`
- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/*.patch`
- `patches/hermes-safe-fetch-context/manifest.yaml`
- `scripts/verify-hermes-safe-fetch-context-payload.sh`

Payload fragments are final-state deltas by target file. Do not encode the path we took to reach the current state.

## Refresh workflow

1. Fetch upstream Hermes.
2. Create a clean scratch worktree from the intended base.
3. Apply the current payload fragments from `series`.
4. Resolve upstream drift by preserving current intent, not old line placement.
5. Run targeted tests.
6. Regenerate final-state fragments from the resolved worktree:
   - one fragment per changed target file by default
   - one atomic group only when a split would be incoherent
7. Replace `series`, `manifest.yaml`, and `*.patch` with the regenerated final-state artifact.
8. Update `base.ref` when the base changes.
9. Run the clean-base verifier.

## Regeneration sketch

From a clean base worktree with the final resolved payload staged:

```bash
git diff --cached --name-only | while read -r path; do
  name=$(printf '%s' "$path" | tr '/' '_' | sed 's/$/.patch/')
  git diff --cached --binary -- "$path" > "$PATCH_REPO/patches/hermes-safe-fetch-context/$name"
done
```

Then rebuild `series` from those fragment names and run:

```bash
scripts/verify-hermes-safe-fetch-context-payload.sh /path/to/hermes-agent
```

## Done criteria

A rebase or refresh is done when:

- every active payload fragment represents final desired state for its target file/group
- no active artifact exists only for historical or compatibility reasons
- `series` lists the active final-state fragments
- `manifest.yaml` matches `series` and the changed paths/tests
- `SURFACE_MAP.md` matches the live code surfaces
- targeted tests pass, or failures are documented with root cause
- the packaged payload applies cleanly in a fresh upstream worktree
