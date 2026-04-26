# Maintainer handoff review prompt

Review whether a future maintainer can safely carry this stack as Hermes changes.

Check:

- root README points to the right canonical artifacts;
- docs README describes the actual stack;
- `REBASE_PLAYBOOK.md` preserves every patch and required test;
- `SURFACE_MAP.md` includes every patch and moved-surface search guidance;
- `manifest.yaml`, `series`, verifier, docs, and test lists agree;
- verification logs or summaries are useful and not polluted by avoidable local path noise;
- the final handoff prompt tells a fresh session not to drop `0005` or any new mandatory patch.

Return a pass/fail verdict and exact file edits if needed.
