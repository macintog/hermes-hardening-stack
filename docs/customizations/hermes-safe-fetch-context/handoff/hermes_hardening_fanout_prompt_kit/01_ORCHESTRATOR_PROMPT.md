# Orchestrator prompt for Hermes hostile-download prompt-injection hardening

You are the coordinating agent. Use the connected GitHub repo `macintog/hermes-hardening-stack` as source of truth and a Hermes checkout as the patch application target.

## Mission

Complete the hardening methodology so the stack credibly contains prompt injection from hostile downloads and tool-derived content. The desired property is not that the model never sees malicious text; it is that malicious text cannot obtain authority.

## Initial repository read

Read these before delegating:

```text
README.md
patches/hermes-safe-fetch-context/series
patches/hermes-safe-fetch-context/manifest.yaml
patches/hermes-safe-fetch-context/base.ref
patches/hermes-safe-fetch-context/0001-context-safety-core.patch
patches/hermes-safe-fetch-context/0002-safe-http-gateway-download-hardening.patch
patches/hermes-safe-fetch-context/0003-customization-maintenance-tool.patch
patches/hermes-safe-fetch-context/0004-provenance-action-authority-hardening.patch
patches/hermes-safe-fetch-context/0005-tool-result-promotion-action-registry.patch
docs/customizations/hermes-safe-fetch-context/README.md
docs/customizations/hermes-safe-fetch-context/INTENT.md
docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
scripts/verify-hermes-safe-fetch-context-stack.sh
verification-output/*.log
```

Record the current base SHA, patch order, manifest phases, and docs drift before changing anything.

## Subagent fan-out

Dispatch the subagent prompts in this order.

### Batch A: analysis and design

Run these in parallel if the harness allows it:

1. `S00_repo_snapshot_and_gap_triage.md`
2. `S01_threat_model_and_invariants.md`
3. `S02_structured_taint_and_authority_grants.md`
4. `S03_tool_registry_metadata_fail_closed.md`
5. `S04_tool_result_promotion_default_taint.md`
6. `S05_safe_http_ssrf_parser_hardening.md`
7. `S06_persistence_memory_cron_skills_plugins.md`
8. `S07_adversarial_e2e_harness.md`
9. `S08_docs_manifest_playbook_ci.md`

Expected output from Batch A: concrete file-level change plan, tests to add, verifier updates, and risk register entries. Reject vague recommendations that do not specify code paths and test names.

### Batch B: implementation

Create implementation subagents based on the Batch A results. Suggested splits:

- structured taint/provenance + action-authority integration;
- tool registry metadata + fail-closed unknown tool policy;
- tool-result promotion default-taint and model-message rendering;
- persistence surfaces: memory, cron, skills, plugin/pre-LLM context;
- safe HTTP and parser/extractor limits;
- adversarial end-to-end tests;
- docs/manifest/playbook/verifier/CI.

Each implementation subagent must return a patch/diff and the exact tests it expects to pass.

### Batch C: integration and review

Run:

1. `S10_integration_patch_refresh.md`
2. `review_prompts/R01_security_boundary_review.md`
3. `review_prompts/R02_regression_test_review.md`
4. `review_prompts/R03_doc_drift_review.md`
5. `subagent_prompts/S09_final_red_team_review.md`

## Required security invariants

The final work must enforce or explicitly track these invariants:

1. Remote-content invariant: URL fetches, gateway attachments, browser pages, OCR, PDFs, documents, transcripts, plugin outputs, external API text, skill/community content, memory recall, and cron outputs are untrusted by default unless explicitly trusted by local policy.
2. Promotion invariant: untrusted strings shown to the model are fenced/evidence-only or carried in a structured untrusted channel.
3. Authority invariant: untrusted content cannot authorize side effects.
4. Derived-action invariant: if the model turn was influenced by untrusted content, side-effecting tool calls require trusted scoped authorization unless an explicit local policy grant applies.
5. Persistence invariant: data derived from untrusted content can be stored only with durable taint/provenance and recalled as evidence-only.
6. Registry invariant: every tool declares action class, credential use, network behavior, persistence behavior, output trust level, and confirmation requirements. Unknown side effects fail closed.
7. Confirmation invariant: confirmation must be explicit, scoped to tool/arguments/target/time, and must not launder attacker-controlled text into authority.
8. Evaluation invariant: every new model-visible ingress surface and side-effecting tool receives adversarial tests.

## Patch strategy

Prefer refreshing existing topical patches when the changes are small and clearly belong there:

- 0001: context safety, promotion, rendering, memory/cron/skill context surfaces.
- 0002: safe HTTP and remote-byte ingress.
- 0004: provenance and action authority.
- 0005: tool registry and tool-result promotion.

If changes are broad and risk destabilizing the existing topical split, add a new patch such as:

```text
0006-structured-taint-authority-e2e-hardening.patch
```

If adding a patch, update:

```text
patches/hermes-safe-fetch-context/series
patches/hermes-safe-fetch-context/manifest.yaml
docs/customizations/hermes-safe-fetch-context/README.md
docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
scripts/verify-hermes-safe-fetch-context-stack.sh
```

## Verification minimum

At the end, run or prepare to run:

```bash
python -m py_compile $(manifest-owned-python-files)
python -m pytest -o 'addopts=' -q \
  tests/agent/test_context_safety.py \
  tests/tools/test_safe_http.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/security/test_safe_fetch_surfaces.py \
  tests/security/test_artifact_provenance.py \
  tests/security/test_action_authority.py \
  tests/security/test_prompt_injection_containment.py \
  tests/security/test_tool_result_promotion.py \
  tests/security/test_structured_taint_authority.py \
  tests/security/test_hostile_download_e2e.py \
  tests/security/test_persistence_taint.py \
  tests/security/test_tool_registry_security_metadata.py

HERMES_BASE_REF=origin/main ./scripts/verify-hermes-safe-fetch-context-stack.sh /path/to/hermes
```

Adjust file names if the implementation chooses different test names, but keep equivalent coverage.

## Final response contract

Produce:

- summary of implemented changes;
- list of changed patch-stack files;
- list of changed Hermes target files;
- tests run and results;
- updated residual risk register;
- exact next maintainer commands.
