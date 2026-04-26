# Subagent 04: artifact provenance and taint propagation

You are an application-security implementation subagent. Your task is to make untrusted external content first-class and traceable across fetch, extraction, caching, context promotion, and action authorization.

## Security invariant

Untrusted content must carry provenance and trust state. It must not be converted into a naked string or bytes object at a security boundary without preserving enough metadata to prevent authority confusion.

## Suggested design

Inspect existing Hermes conventions before choosing names. A possible shape is:

```python
@dataclass(frozen=True)
class ContextProvenance:
    source_type: str
    source_label: str | None
    source_url_redacted: str | None = None
    final_url_redacted: str | None = None
    sha256: str | None = None
    content_type: str | None = None
    status_code: int | None = None
    bytes_read: int | None = None
    fetch_policy: Mapping[str, Any] = field(default_factory=dict)
    extraction_chain: tuple[str, ...] = ()
    trust_level: Literal["trusted", "user_supplied", "external", "hostile_unknown"] = "external"
    authority: Literal["none", "trusted_user", "system", "developer", "local_policy"] = "none"
```

Use Hermes style and avoid unnecessary dependencies. The exact names may differ, but these concepts must be represented.

## Required properties

For fetched/extracted external content, provenance must include as much as feasible:

- source type, such as `downloaded_text`, `gateway_attachment_text`, `web_page`, `skill_content`, `plugin_context`, `memory_context`, `cron_prior_output`, `at_reference`
- redacted source URL and final URL when URL-based
- sha256 of bytes or extracted text where feasible
- content type
- bytes read
- fetch policy, including max bytes and content-type policy where feasible
- extraction chain, such as `safe_fetch -> pdf_text -> markdown`
- trust level
- explicit `authority="none"` unless the content is trusted by a non-model policy

## Required implementation work

1. Find where `safe_download_bytes` returns metadata or can be wrapped to produce provenance.
2. Find where bytes are converted to text, temp files, cached files, summaries, gateway payloads, tool results, or prompt context.
3. Preserve provenance through these conversions.
4. Ensure context-safety scan results can attach to or be associated with provenance.
5. Ensure action-authority gating can inspect provenance/trust state later.
6. Do not break existing tool result schemas unless necessary; if schema must remain stable, add metadata alongside existing fields or maintain an internal sidecar.

## Specific surfaces to check

- gateway attachment/document text
- web tool extracted text
- skill/plugin content
- memory provider output
- cron output/context_from
- @ file/git/url references
- cached downloaded media/document paths that later become model-visible

## Test requirements

Create or update tests, likely:

```text
tests/security/test_artifact_provenance.py
```

Tests must prove:

- safe fetch metadata becomes provenance
- redacted URLs are used in provenance and errors
- source URL query/userinfo/fragment are not exposed
- provenance survives extraction from bytes to text
- provenance survives fencing/promotion into context
- external provenance has `authority="none"`
- action-authority gate can identify untrusted provenance

## Acceptance criteria

A future subagent can inspect any model-visible external text and determine where it came from, how it was fetched/extracted, whether it was scanned, and whether it carries authority. If that answer is unavailable for a surface, the surface is not fully hardened.
