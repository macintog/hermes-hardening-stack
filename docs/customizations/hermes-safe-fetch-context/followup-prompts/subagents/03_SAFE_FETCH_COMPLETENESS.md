# Subagent 03: safe-fetch completeness

You are a secure networking implementation subagent. Your task is to ensure every relevant remote-byte ingestion path is protected by `tools.safe_http` or an equivalent documented control.

## Scope

This workstream protects against network-ingress risks:

- SSRF
- private/internal/link-local/metadata target fetches
- unsafe redirects
- credential leakage across redirects
- unbounded downloads
- content-type confusion where applicable
- signed URL leakage in logs/errors

It does not, by itself, solve prompt injection. Treat fetched content as untrusted even when fetched safely.

## Inputs

Read:

```text
tools/safe_http.py
tests/tools/test_safe_http.py
tools/url_safety.py
SURFACE_MAP.md or HARDENING_SURFACE_INVENTORY.md
IMPLEMENTATION_PLAN.md
```

Use reconnaissance results from subagent 02.

## Required implementation checks

For `tools.safe_http` or equivalent helper, verify and test:

- only `http` and `https` allowed by default
- missing host blocked
- URL userinfo blocked by default
- initial URL preflight checked
- every redirect target validated before following
- max redirect count enforced
- `Content-Length > max_bytes` rejected before body read
- streaming max-byte enforcement rejects over-cap bodies even without `Content-Length`
- content-type allowlist enforced where caller supplies one
- result metadata includes source URL, final URL, status code, content type, content length, bytes read, sha256, source type, and policy where feasible
- redacted URLs in logs/errors never leak userinfo, tokens, signed query strings, or fragments
- credential-bearing requests are bound to the original origin; cross-origin redirects with attached credentials are blocked unless a deliberate explicit policy exists
- malformed initial URLs and malformed redirect `Location` values fail closed
- cookies or auth headers are not leaked to redirected origins

## Required caller checks

For each remote-byte ingress surface identified by reconnaissance:

- route through `safe_download_bytes` or an equivalent audited wrapper
- keep existing compatibility contract
- preserve auth headers only for the intended origin
- add or preserve byte caps
- add content-type allowlists for strict media/image/audio paths where compatibility allows
- ensure unsafe URL failures are fail-closed
- ensure error/log messages are redacted
- ensure tests cover private redirect, over-cap streaming, credential redirect, and redaction for that caller class

High-risk surfaces to verify explicitly:

- gateway media/document downloads
- web extraction/crawl returns, even if backed by a hosted service
- skill/community/GitHub install or fetch paths
- plugin install/update/download paths
- any fallback media path that accepts user-provided URLs

## Test requirements

Add or update tests under appropriate existing test files and, if useful, create:

```text
tests/security/test_safe_fetch_surfaces.py
```

At minimum, test:

- unsafe initial URL blocked
- redirect to metadata/private/loopback blocked
- signed URL redacted in error/log
- `Authorization` or auth credential not sent cross-origin
- byte cap enforced with and without `Content-Length`
- caller compatibility is preserved

## Deliverables

- Code changes where gaps exist
- Tests covering any changed surface
- Updated `SURFACE_MAP.md` or `HARDENING_SURFACE_INVENTORY.md`
- Patch-stack updates later handled by rebase/patch subagent

## Acceptance criteria

All direct remote-byte paths are either safe-fetch protected or explicitly documented as unreachable/non-applicable/equivalent. No hostile remote bytes may bypass URL safety, redirect safety, byte caps, and redacted error handling merely because they enter through a less common tool or platform adapter.
