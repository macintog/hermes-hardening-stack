# Orchestrator prompt

You are the orchestrator for a one-session completion pass on `macintog/hermes-hardening-stack`. Use the repository and the local Hermes checkout as source material. Your job is to coordinate subagents, merge their findings, implement or direct code/doc/test changes, regenerate the patch stack, and produce a final zip artifact.

## Mission

Complete the methodology and handoff gaps for hostile-download prompt-injection containment in Hermes. This is not a generic prompt-injection scanner. The expected security boundary is deterministic authority control:

- untrusted external/tool-derived content may be evidence;
- it must not become authority;
- it must not drive side effects without trusted, scoped authorization;
- the stack must remain maintainable as upstream Hermes changes.

## Canonical stack

Read `patches/hermes-safe-fetch-context/series` and `manifest.yaml` before making assumptions. The stack is expected to include:

1. `0001-context-safety-core.patch`
2. `0002-safe-http-gateway-download-hardening.patch`
3. `0003-customization-maintenance-tool.patch`
4. `0004-provenance-action-authority-hardening.patch`
5. `0005-tool-result-promotion-action-registry.patch`

If the latest repo differs, document the divergence and align all docs/verifier metadata to the executable stack. Never silently remove a patch from `series`.

## Fan-out sequence

Run these subagents in parallel where the harness supports it, then integrate:

1. Repo state and drift baseline.
2. Docs/playbook synchronization.
3. Structured turn-taint design and implementation.
4. Tool registry metadata and fail-closed action classification.
5. Tool-result promotion default-deny/default-untrusted policy.
6. Browser and credentialed network action review.
7. Skill/plugin execution ordering and inline shell expansion review.
8. Persistence, memory, cron, and provenance review.
9. Safe HTTP, parser, and extraction risk review.
10. Adversarial tests and deterministic pass/fail criteria.
11. Verifier, CI, and doc-drift checks.
12. Integration and patch refresh.
13. Red-team review.

Use the subagent prompts in `subagents/` verbatim when possible. Each subagent must produce a concise report using `templates/subagent_report.md`.

## Integration rules

- Security-critical code changes should be represented in patch files, not only in docs.
- If changes belong naturally to an existing patch topic, refresh that patch.
- If adding a new cross-cutting phase is cleaner, create `0006-<clear-name>.patch` and update:
  - `series`
  - `manifest.yaml`
  - `REBASE_PLAYBOOK.md`
  - `SURFACE_MAP.md`
  - `README.md`
  - verifier targeted tests
  - source-of-truth docs and handoff prompts
- If you add a patch, the docs must explain why the new phase is mandatory and how to refresh it.

## Code invariants

Enforce or approximate these invariants:

1. **Ingress invariant:** external/tool/browser/plugin/skill/gateway/downloaded/extracted/recalled content enters as untrusted unless explicitly trusted by code provenance.
2. **Promotion invariant:** model-visible tool strings are untrusted evidence by default unless registry metadata marks them trusted internal control output.
3. **Turn-taint invariant:** if a turn has seen untrusted content, side-effecting actions require trusted scoped authorization regardless of whether tool arguments still contain textual tags.
4. **Action invariant:** untrusted content cannot authorize file writes, terminal execution, outbound messages, credentialed browser/network actions, memory writes, cron changes, skill/plugin install or execution, config changes, secret access, or unknown side effects.
5. **Persistence invariant:** untrusted-derived persisted data remains tainted on recall.
6. **Registry invariant:** tool metadata must declare action class, output trust, credential/network/persistence behavior, and confirmation requirement; unknown side effects fail closed.
7. **Docs invariant:** docs/playbooks/verifier/manifest/series/test lists must agree.

## Minimum implementation targets

Resolve these before spending time on lower-priority items:

- Fix `REBASE_PLAYBOOK.md` to include `0005` in patch list, refresh command, `series` rewrite, and targeted tests.
- Rewrite docs README around the current five-phase hardening model and remove stale WeCom wording.
- Add a patch `0005` section to `SURFACE_MAP.md`.
- Reclassify `browser_console` and related browser context capabilities as credentialed/browser-context sensitive unless evidence proves otherwise.
- Move/gate inline shell expansion in skill loading so untrusted/community/plugin skill content cannot execute before trust/provenance checks.
- Invert tool-result promotion default for string outputs: untrusted by default unless metadata says trusted internal output.
- Add a structured turn security context or documented transition path with tests.
- Add verifier checks for doc drift where feasible.

## Verification

Run the patch-stack verifier. If failures occur, preserve the failure log and fix the stack. Required tests should include at least all manifest-required tests and any new tests added for:

- tool-result promotion defaulting;
- unknown tool output string fencing;
- browser console/credentialed browser gating;
- skill inline shell ordering/gating;
- structured turn taint blocking side effects;
- docs/playbook/series/manifest consistency.

## Final deliverable

Produce a zip containing:

- changed patch-stack files;
- any refreshed patch files;
- updated docs;
- verifier output summary;
- subagent reports;
- risk register;
- residual issues;
- final handoff prompt for future sessions.

Also provide a concise final narrative: what changed, tests run, what remains, and exact files touched.
