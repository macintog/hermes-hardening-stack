# Patch refresh checklist

- [ ] Record current patch repo commit SHA.
- [ ] Record Hermes base ref.
- [ ] Confirm `series` patch list.
- [ ] Apply patches in `series` to clean Hermes worktree.
- [ ] Make implementation/doc/test changes.
- [ ] Refresh every modified patch.
- [ ] If new patch added, update `series` and `manifest.yaml`.
- [ ] Update docs README.
- [ ] Update `SURFACE_MAP.md`.
- [ ] Update `REBASE_PLAYBOOK.md` patch list, targeted tests, and refresh commands.
- [ ] Update verifier test list and consistency checks.
- [ ] Run clean-base verifier.
- [ ] Run `HERMES_BASE_REF=origin/main` verifier if feasible.
- [ ] Summarize/sanitize verification output.
- [ ] Update risk register and final handoff prompt.
