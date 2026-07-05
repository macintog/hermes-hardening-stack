# Open hardening backlog

This is the public backlog summary distilled from imported QA bug reports, security finding records, and later trusted-local-work changes. The private authoring repo also keeps local QA event stores and detailed finding records; those raw operational records are intentionally not part of the public publish tree.

## Current publish status

- Payload base: `7b12753948acc373dab31eca481c3b8e6a6329ea`
- Series fragments: `108`
- Manifest-required tests: `55`
- Public root snapshot reproducibility evidence for commit `db5646b2ec21caebfea6a634e7bf630cd4149a29` is recorded in `validation/runs/2026-07-04-public-root-snapshot/SUMMARY.md`; no workflow-run proof was recorded in this repo for that snapshot.
- Broad Docker status: not fully green. The latest repeat has `18` stable patched-only upstream pytest failures against the same-day clean baseline, with `0` new stable patched-only failures outside the original strict regression set.

## Status model

- `open`: still needs implementation or proof.
- `review`: likely still relevant, but confirm against the current patch before changing code.
- `done`: resolved by later work; keep only when it helps explain why an older concern is no longer active.

Older package entries below retain their original focused proof notes as historical rationale. The current publish gate is the status block above; do not treat older verifier counts or kept-worktree paths as the latest qualification result.

## Current priority

### Security findings from 2026-05-02

Status: `done` for the 2026-05-02 candidate queue.

The detailed project-local security finding index and QA event store live in the private authoring repo. This public summary records durable status only.

Closed verified by focused proof plus full payload verifier:
- `@url` forged-fence vulnerability still exists.
- Gateway active intent is still stored in shared runner state.
- Rendered reference truncation can break the fence.
- Generic/missing content-type image downloads can accept arbitrary bytes.
- Permanent scoped approval is still too broad for high-risk actions.
- SafeHTTP proxy/transport policy still has a future footgun.
- Base media cache retry behavior remains removed.
- Action-decision telemetry default.
- Invalid native evidence-ledger diagnostics.
- Customization audit working-tree coverage.
- Local-authored skill trust defaults.

Fixed there: multi-image downloads now route through SafeHTTP for Slack, Discord, and Mattermost and are verified by the 2026-05-02 multi-image SafeHTTP qualification. Tool-output `MEDIA:` delivery injection and final-text local file upload are fixed by trusted-media-artifact gating in gateway media delivery. Remote proxy active-intent docs now match the v2 HMAC, timestamp, nonce, and replay-window contract and are closed verified as a docs-only fix.

No 2026-05-02 security finding remains in candidate state. The current broad Docker gate still has `18` stable patched-only failures on the July 4 strict repeat; those are regression-qualification work, not reopened 2026-05-02 security findings.

Required practice:
- In the private authoring repo, fix from the individual finding file, not from memory.
- Update private finding status and proof when a fix lands.
- Mirror opened, fixed, or reclassified findings in the private QA bug store.
- If a fix changes payload behavior, update manifest ownership, required tests, private checkpoint, and public durable docs in the same work item.

### 0. Red-team remediation plan

Status: `done`

The red-team review found authority-laundering and taint-propagation gaps that should be worked before upstream/demo readiness. The durable execution handoff is `docs/customizations/hermes-safe-fetch-context/RED_TEAM_REMEDIATION_PLAN.md`.

Current work packages:
- Delegation trust boundary: prevent evidence-derived child goals/context/toolsets from becoming trusted child intent.
- Gateway active-intent authentication: replace static header trust with an unforgeable internal contract.
- Memory/plugin taint plumbing: ensure API-call-only context injections are also visible to action authority.
- Affirmative intent and local-dev policy split: block negated/quoted action mentions while preserving expected local repo workflows.
- Skill provenance and trust promotion: prevent community/plugin-installed skills from becoming trusted by path alone.
- Plugin hook authority policy: keep block/observe/transform hooks from bypassing action authority or provenance.
- UX regression harness: prove hardening does not make ordinary Hermes development painful.

Required proof:
- Focused tests per package from the remediation plan.
- Recorded-base verifier.
- Public-sample checks from the verifier, or a focused rerun against one intentionally kept applied worktree that is removed after evidence capture.
- Current-upstream apply proof when conflict-prone files change.

Proof:
- Implemented across final-state payload fragments for delegation, gateway active-intent signing, memory/plugin taint, affirmative local-dev authority, skill provenance, plugin hooks, and UX regression proof.
- Recorded-base full verifier passed on 2026-04-29: required tests `1224 passed, 1 skipped, 108 warnings`; strict evidence-ledger smoke `6 passed, 6 warnings`; public samples `sample_count=8`, `ux_regression_count=14`, `failure_count=0`; kept verifier worktree path redacted in public snapshot.
- Current-upstream apply-only passed against `origin/main` at `4899bd99c0b72d926deb51b0be25b19384b5d0f0`; kept verifier worktree path redacted in public snapshot.

### 1. JSON-string tool result promotion

Status: `done`

Many Hermes tools return JSON as a string. `model_tools.py` calls `render_model_visible_tool_result(function_name, result)`, and `agent/context_safety.py` currently preserves native evidence ledgers only when the result is already a mapping.

Risk:
- A JSON string that contains `evidence_ledger` can be fenced as opaque text instead of preserved as structured provenance.
- Strict native-ledger mode can miss missing ledgers for known untrusted producers if the result is still an unparsed JSON string.

Expected fix:
- Normalize model-visible tool results before promotion.
- Parse JSON object/array strings for promotion only when parsing succeeds.
- Preserve native `evidence_ledger` values as structured fields.
- In strict mode, fail known untrusted producers that return parsed JSON without native ledgers.
- Keep invalid JSON/plain strings fenced as untrusted text.

Required tests:
- JSON string with native `evidence_ledger` preserves the ledger structurally.
- JSON string from `web_extract` or another known evidence producer without a native ledger fails when `HERMES_REQUIRE_EVIDENCE_LEDGER` is enabled.
- Plain non-JSON string remains fenced.
- Nested strings in parsed JSON are still rendered as evidence unless explicitly trusted.

Proof:
- Implemented in `agent/context_safety.py` promotion normalization.
- Verified by payload verifier: `1271 passed, 38 skipped, 26 warnings`; kept verifier worktree path redacted in public snapshot.
- Public sample checks passed: `sample_count=8`, `failure_count=0`; public sample output path redacted in public snapshot.

### 2. Native action-decision ledgers from dispatch

Status: `done`

`agent/action_authority.py` has `to_action_decision_payload(...)`, and unit tests cover the payload builder. The real dispatch path in `model_tools.py` now emits native `action_decisions` while preserving the older error/message compatibility surface.

Risk:
- The action gate can deny correctly while downstream sentinels cannot consume a uniform machine-readable decision record.
- Denied, confirmation-required, and allowed side-effect decisions are not represented through the same ledger contract as evidence inputs.

Expected fix:
- Emit native `action_decisions` from the actual dispatch path for deny, confirmation-required, and allow decisions where the tool has side-effect or confidentiality impact.
- Keep human-readable error fields for compatibility.
- Include trusted intent summary, evidence input summaries when available, decision reason, action class, and denial payload.

Required tests:
- Real `handle_function_call(...)` denial returns `action_decisions`.
- The denial record carries `schema: hermes.action_decision.v1`, `allowed: false`, decision, action class, reason, and safety block.
- Existing callers that expect `error` and `message` still work.
- Allowed side-effect or confidentiality-impact dispatch results attach `action_decisions` while preserving the `handle_function_call(...) -> str` contract.

Proof:
- Implemented in `model_tools.py` dispatch by evaluating action authority before registry dispatch and serializing model-visible results with attached native `action_decisions`.
- Deny and confirmation-required paths preserve existing `error` and `message` fields while adding `action_decisions`.
- Allowed side-effect and confidentiality-impact results attach native decisions after model-visible tool-result promotion; read-only/local/internal allow decisions stay omitted to avoid ledger noise.
- `agent/action_authority.py` preserves trusted `policy_context` in emitted action-decision payloads when supplied.
- Verified by payload verifier: `1271 passed, 38 skipped, 26 warnings`; kept verifier worktree path redacted in public snapshot.
- Public sample checks passed: `sample_count=8`, `failure_count=0`; public sample output path redacted in public snapshot.

### 3. Gateway active-intent segmentation proof

Status: `done`

The action-authority consumer now supports `__active_user_intent`, and tests cover typed/string markers. The remaining question is whether gateway construction always separates user-authored text from derived evidence.

Risk:
- Image analysis, audio transcripts, document text, reply quotes, URL expansions, or platform metadata can be appended to the same user message and later treated as trusted user intent.

Expected fix:
- Gateway message preparation should explicitly segment:
  - trusted typed/caption text
  - evidence-only image analysis/OCR
  - evidence-only STT transcript
  - evidence-only document or attachment text
  - evidence-only reply quote
  - evidence-only URL expansion and platform metadata
- Attach trusted text through `__active_user_intent`.
- Render derived evidence through context safety before model-visible promotion.

Required tests:
- Gateway image-derived text saying to send secrets cannot authorize outbound tools.
- Gateway audio transcript saying to write or run a command cannot authorize file/terminal tools.
- Gateway document or reply quote containing a path, recipient, URL, or command cannot authorize that target unless the user-typed text supplies trusted scope.

Proof:
- Implemented in `gateway/run.py`: gateway message preparation now keeps typed/caption text in `__active_user_intent`, renders image/OCR, STT, document, reply, `@` reference expansion, and platform sender metadata as evidence-only context, and threads the marker through direct `AIAgent.run_conversation(...)` and proxy chat message construction.
- `run_agent.py` accepts an optional `active_user_intent` marker and attaches it to the current user message so the existing action-authority consumer sees the trusted scope for the live turn.
- Added `tests/gateway/test_active_intent_segmentation.py` coverage for image-derived outbound attempts, audio transcript terminal attempts, document/reply target injection, and typed trusted scope surviving adjacent reply evidence.
- Updated reply-to tests to expect the disambiguation pointer inside a `gateway_reply` evidence fence.
- Verified by payload verifier: `1275 passed, 38 skipped, 26 warnings`; kept verifier worktree path redacted in public snapshot.
- Public sample checks passed: `sample_count=8`, `failure_count=0`; public sample output path redacted in public snapshot.

### 4. `safe_download_to_file` streaming and fd hygiene

Status: `done`

`tools/safe_http.py` now implements `safe_download_to_file` as a first-class streaming helper. It no longer calls `safe_download_bytes` and no longer writes buffered content with `Path(path).write_bytes(...)`.

Original risk:
- The original file descriptor was not deterministically closed before path writes.
- Large media/document downloads were materialized in memory before writing.
- Partial file cleanup on failure was weaker than a true streaming writer.

Proof:
- Implemented in `tools/safe_http.py`: streams response chunks directly to the `mkstemp` fd through `os.fdopen`, validates redirects through the shared safe HTTP path, enforces `Content-Length` and incremental byte caps, updates SHA-256 metadata while streaming, closes descriptors deterministically, and removes partial files on failure.
- Covered by `tests/tools/test_safe_http.py` cases for streaming success, fd cleanup, over-cap chunk failure, partial-file removal, exact private-origin matching, DNS/IP preflight, and default-transport connection peer validation.
- Verified by payload verifier after S01: `1278 passed, 38 skipped, 26 warnings`; kept verifier worktree path redacted in public snapshot.
- Later full verifier after S02/S06/S07 passed: main required tests `1430 passed, 38 skipped, 102 warnings`; strict evidence-ledger smoke `6 passed, 6 warnings`; public samples `sample_count=8`, `failure_count=0`.

### 5. Upstream/demo readiness split

Status: `open`

The payload remains the canonical hardening source for now. For maintainer review or contest presentation, publish an applied-tree branch in a fork of `NousResearch/hermes-agent` rather than asking maintainers to inspect patch fragments first.

Expected workflow:
- Keep authoring in this patch-stack repo through the current hardening pass.
- Dry-run apply against fresh upstream `main`.
- Run the payload verifier; use focused public-sample reruns only when needed and remove any kept verifier worktree afterward.
- Commit an applied tree to a fork branch only when the operator explicitly starts a maintainer-review presentation lane. Default commits stay in this patch repo.
- Keep local development authority clearly marked as dev-only, disabled by default, and removable before upstream/public shipping.

## Review backlog

### Safe-download coverage sweep

Status: `done` for S02-owned gateway call sites; keep as recurring review for newly added platforms or provider paths.

The old audit flagged gateway/media paths that bypassed the shared safe downloader. The S02 sweep moved owned Discord fallback, Slack private/outbound, Mattermost, Feishu, QQBot, WeCom, BlueBubbles, and Telegram URL-cache paths to `safe_download_bytes` or documented provider-mediated exceptions. The 2026-06-30 plugin-adapter refresh retargeted moved Feishu, Matrix, Slack, Telegram, and WeCom platform fragments to `plugins/platforms/*/adapter.py`.

Closed check:
- Slack private files and downloads
- Mattermost files
- Feishu document/media paths
- Discord fallback attachment paths
- QQBot/media paths
- Telegram/WeCom fallback paths

For each path, S02 confirmed or added initial URL validation, redirect validation, byte cap, credential redirect policy, and URL redaction. Remaining nuance is content-type strictness/provider SDK opacity, tracked in `HARDENING_SURFACE_INVENTORY.md` as partial coverage where applicable.

### Matrix/Yuanbao media download sweep

Status: `done`

Static closeout found raw media URL download paths in Matrix/Yuanbao call sites. The follow-up now owns `plugins/platforms/matrix/adapter.py`, `gateway/platforms/yuanbao_media.py`, and related `gateway/platforms/yuanbao.py` files in `patches/hermes-safe-fetch-context/series` and `manifest.yaml`, with provider-mediated exceptions documented explicitly.

Resolution:
- Matrix outbound `send_image` arbitrary URL downloads now use `safe_download_bytes` with a 10 MiB cap, image content-type allowlist, no-credential redirect policy, redirect/peer validation, and redacted logging.
- Matrix `mxc://` inbound media remains provider-mediated through the Matrix SDK `download_media(ContentURI(...))`; Matrix homeserver API/session/upload calls remain credentialed provider APIs.
- Yuanbao arbitrary URL media downloads now route through `gateway.platforms.yuanbao_media.download_url`, which delegates to `safe_download_bytes` with byte caps, no-credential redirects, URL redaction from safe_http errors, and caller-supplied image/file content-type allowlists.
- Yuanbao token/sign, resource URL resolution, COS upload, and WebSocket business calls remain fixed/credentialed provider APIs; resource-mediated inbound bytes are safe-downloaded only after provider resolution.
- Added required gateway coverage in `tests/gateway/test_matrix_yuanbao_media_downloads.py` for safe downloader policy, Matrix provider-mediated inbound media, oversize responses, private/metadata redirects, and content-type rejection.

### Redaction and schema governance

Status: `done`

Evidence ledgers and safe HTTP redaction should use compatible URL/path redaction behavior.

Check:
- query string redaction
- fragment redaction
- userinfo redaction
- token-like path segment redaction
- absolute local path redaction
- canonical writer schemas:
  - `hermes.tool_result_ledger.v1`
  - `hermes.tool_result_ledger.legacy.v1`
  - `hermes.action_decision.v1`

Adapters may tolerate legacy variants, but writers should stay canonical.

Proof:
- Evidence-ledger URL redaction now matches Safe HTTP for query strings, fragments, userinfo, and token-like path segments, while preserving absolute local path basename-only redaction.
- The model-visible legacy ledger writer now emits `hermes.tool_result_ledger.legacy.v1`; the reader accepts both the canonical schema and the older `hermes.evidence_ledger.legacy.v1`.
- Native writer schemas remain `hermes.tool_result_ledger.v1` and `hermes.action_decision.v1`.
- Confirmed through the payload verifier/applied-worktree flow on 2026-04-29: apply-only verifier passed with private verifier worktree retained only in the private QA store; focused compile and pytest passed `147 passed, 140 warnings` across evidence-ledger, tool-result promotion, surface-matrix, `@url`, Tavily web-extract, and action-authority coverage.

### `@url` expansion schema regression

Status: `done`

`agent/context_references.py` calls `web_extract_tool(...)` and parses JSON. Confirm it handles the patched `web_extract` result shape and preserves/fences evidence consistently.

Required test:
- `@url` reference expansion against patched `web_extract` produces model-visible fenced evidence and does not bypass native ledger handling.

Proof:
- `agent/context_references.py` accepts patched `web_extract` `results[0].content`, preserves valid native ledgers as stable JSON inside the model-visible evidence block, and avoids double-fencing already fenced text.
- Confirmed through the same 2026-04-29 applied-worktree focused proof: `tests/security/test_context_promotion_boundaries.py` and `tests/tools/test_web_tools_tavily.py` passed inside a private verifier worktree retained only in the private QA store.

### Local read confidentiality boundary

Status: `done`

The action-authority model is strongest around side effects. Confirm that file reads parameterized only by evidence-only untrusted text are blocked or require trusted scope, even when the path is not obviously secret-like.

Required test:
- Untrusted evidence naming a local non-secret path cannot authorize reading that path without trusted user scope.

Proof:
- Covered in `tests/security/test_action_authority.py` by non-secret local read cases: downloaded evidence naming `/tmp/private-notes.md` is blocked, an unscoped local read with untrusted context requires confirmation, and a user can explicitly adopt the same path in trusted scope.
- Confirmed through the payload verifier/applied-worktree flow on 2026-04-29: apply-only verifier passed with private verifier worktree retained only in the private QA store; focused pytest on that applied worktree passed `6 passed, 6 warnings` for the local-read authority boundary cases.

### Passive browser action split

Status: `done`

Browser observation primitives may be stricter than necessary. This is mainly usability, not a known security gap.

Possible split:
- passive observation: snapshot, get images, passive console read, scroll, back/forward without attacker-supplied navigation
- stateful/credentialed action: click, type, submit, upload, JS eval, attacker-directed navigation

Keep the stateful class behind trusted scoped authority.

Proof:
- `browser_snapshot`, `browser_get_images`, `browser_vision`, `browser_console` without `expression`, `browser_scroll`, and `browser_back` classify as `read_only_network_fetch`; scroll/back skip the network-egress guard only when they carry no URL-like network target fields.
- `browser_console(expression=...)`, `browser_navigate`, `browser_click`, `browser_type`, `browser_press`, `browser_cdp`, and `browser_dialog` stay behind trusted scoped authority.
- No `browser_forward` tool is registered in the observed Hermes checkout.
- Confirmed through the same 2026-04-29 applied-worktree focused proof: `tests/security/test_action_authority.py` passed inside a private verifier worktree retained only in the private QA store.

## Closed from the old audit

### Verifier required-tests execution

Status: `done`

The verifier now derives pytest targets from `manifest.yaml` `payload.required_tests` and runs those paths directly. This fixed the old false-confidence risk where tests could be listed in the manifest without being executed.

Current proof:
- `scripts/verify-hermes-safe-fetch-context-payload.sh` builds the pytest target list from `payload.required_tests`.
- `README.md` documents that verification runs every manifest-required test.
- Latest checkpoint evidence records a passing verifier with manifest-derived tests.
