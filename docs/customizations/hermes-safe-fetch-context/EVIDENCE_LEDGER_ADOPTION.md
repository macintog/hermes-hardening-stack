# Evidence ledger adoption notes

This document records the design decisions and completed verification that were previously developed in the temporary image-sentinel prototype notes. The active implementation lives in the `hermes-safe-fetch-context` payload; there is no runtime dependency on a prototype package.

## Core decision

All untrusted content-producing paths should converge on the same Hermes evidence/provenance and action-authority model before model-visible promotion.

Image/media paths can be validated with image/media-specific harnesses, but plain web text, browser DOM text, console logs, document text, transcripts, skill content, community content, memory-like external material, and gateway text should not be forced through an image sentinel.

Common flow:

1. untrusted content source
2. safe ingress when remote bytes are fetched
3. native `evidence_ledger` on the tool result when available
4. context-safety scan/fenced render before model-visible promotion
5. action-authority check before side-effecting tools
6. deterministic tests/verifier assert that evidence can inform but cannot authorize actions

Hard invariant:

- untrusted evidence may inform responses;
- untrusted evidence may be used as content only when independent trusted user intent authorizes the action/scope;
- untrusted evidence must not authorize side effects by itself.

## Implemented coverage

The payload now implements and verifies the following surfaces.

### Generic evidence ledger contract

Implemented in `agent/evidence_ledgers.py`:

- compact evidence item IDs;
- `trust_boundary`;
- `instruction_authority`;
- `can_inform_response`;
- `can_authorize_action`;
- `side_effect_use_policy`;
- redacted source URI/arguments;
- bounded text byte counts and hashes.

Large content is not duplicated in ledgers. The ledger records references, counts, hashes, source metadata, and policy fields.

### Web text

Implemented for:

- `web_search` titles/descriptions/snippets as `web_search_snippet` evidence;
- `web_extract` content as `downloaded_web_text` or `web_extract_summary` when LLM processing rewrites/summarizes the result;
- blocked secret-bearing URL preflight results with redacted blocked ledgers.

### Browser passive observations

Implemented for:

- `browser_navigate` as passive acquisition when the URL is trusted user-scoped;
- `browser_snapshot` DOM/text snapshots;
- passive `browser_console` output;
- `browser_get_images` metadata.

Active browser actions remain action-authority concerns. Passive observation can collect evidence; clicks, typing, form submission, JS eval, CDP/dialog operations, and other stateful actions require trusted scoped authority. Navigation targets supplied only by page/downloaded/tool evidence remain untrusted parameters and must be blocked or confirmed before use, even though navigation to an active-user-scoped URL is low-friction evidence acquisition.

### Transcript/audio-derived text

Implemented for `transcribe_audio` provider branches. Transcript text is evidence-only and cannot authorize side effects.

### Model-visible promotion

Implemented in `agent/context_safety.py`:

- native `evidence_ledger` mappings are preserved;
- known untrusted mapping outputs without native ledgers receive legacy evidence-only wrapping by default;
- strict validation mode can reject missing native ledgers via `HERMES_REQUIRE_EVIDENCE_LEDGER=1|true|yes|strict`.

Runtime compatibility default is wrapping, not hard failure.

### Action authority and dispatch

Implemented in:

- `agent/action_authority.py`;
- `model_tools.py`;
- `run_agent.py`.

Dispatch now evaluates action authority before tool execution and fences/promotes tool results before model-visible insertion. Blocked/confirmation-required decisions include structured payloads with action class, authority source, reason, remediation, retry guidance, and a safety event.

Action-decision ledger support exists through `ActionAuthorityResult.to_action_decision_payload(...)` and schema `hermes.action_decision.v1`.

### Skill/community content

Implemented in:

- `agent/skill_commands.py`;
- `tools/skills_tool.py`;
- `tools/skills_hub.py`.

Skill content without explicit trusted local authority defaults to evidence-only. External/community/plugin skill content and linked skill files expose `authority` and `context_safety` metadata. Inline shell expansion is limited to trusted local policy.

### Gateway/media safe ingress

Safe download boundaries were restored or added for:

- base image cache URL downloads;
- base audio cache URL downloads;
- Telegram fallback image uploads;
- WeCom outbound media URL loads;
- BlueBubbles attachments.

These use `safe_download_bytes(...)` with source-type/policy metadata, byte caps, redirect safety, content-type checks where appropriate, and redacted logging.

## Validation strategy

The prototype idea of a separate broad web/text sentinel was not adopted. The active approach is smaller and more maintainable:

- deterministic pytest fixtures;
- unified security surface matrix tests;
- payload manifest/series verification;
- targeted hardening verifier script.

The image/media prototype harness was useful to prove the image/media idea, but it is not part of the active implementation. Future image/media validation should live as normal payload tests or documented validation runs, not as a tracked prototype runtime tree.

## Image/media validation baseline retained from prototype work

Historical image/media validation established these expectations:

- direct fixture paths through `vision_analyze_tool` can expose native `vision_analyze` ledgers for supported formats;
- served browser paths through `browser_navigate` + `browser_vision` can expose native `browser_vision` ledgers for screenshot/visual observations;
- unsupported image formats should fail closed or warn clearly rather than silently passing;
- browser visual observation ledgers should mark extracted/observed text as evidence-only and deny mutation probes without trusted authority;
- harness adapters must remain thin and must not become policy engines.

These points are retained as design guidance only. The active payload is authoritative.

## Current verifier status

Current full verifier command:

```bash
cd <patch-repo>
PYTHON=<hermes-python> \
HERMES_CHECKOUT=<hermes-checkout> \
./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

Latest recorded private authoring-tree result:

```text
2434 passed, 1 skipped, 163 warnings
strict evidence-ledger validation: 6 passed
public samples: failure_count=0
```

The public preview branch was also checked with `--archive-mode --apply-only`; the stack applied successfully with `series_count=101` and `required_test_count=52`. The broad Docker repeat is not fully green; the current public status is summarized in `OPEN_HARDENING_BACKLOG.md`.

## Remaining known gap

Safety-pipeline interruption diagnostics are not yet unified under one shared payload. Action-authority blocks are structured, but strict missing-ledger failures, safe-fetch errors, context-promotion exceptions, plugin-transform failures, and generic tool-dispatch exceptions can still surface as mixed/plain errors.

Possible future work: add an internal shared safety-interruption payload/helper. This should not be a model-callable tool, and it is not part of the current implementation scope.
