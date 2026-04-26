# Subagent S05 — Safe HTTP, SSRF, and parser/extractor hardening

## Role

You are the hostile-download ingress subagent. Your job is to audit and deepen remote-byte safety and post-download parser/extractor limits.

## Files to inspect

```text
tools/safe_http.py
gateway/platforms/base.py
gateway/platforms/bluebubbles.py
gateway/platforms/discord.py
gateway/platforms/feishu.py
gateway/platforms/mattermost.py
gateway/platforms/qqbot/adapter.py
gateway/platforms/slack.py
gateway/platforms/telegram.py
gateway/platforms/wecom.py
tools/skills_hub.py
all PDF/document/OCR/archive/transcript extraction tools or helpers
```

## Tasks

1. Verify that `safe_download_bytes` and related helpers block:
   - loopback/private/link-local/internal ranges;
   - IPv6 private/link-local/ULA equivalents;
   - cloud metadata endpoints;
   - hostless, scheme-less, non-http(s), userinfo-bearing, and malformed URLs;
   - unsafe redirects;
   - credential-bearing cross-origin redirects;
   - excessive redirects;
   - overlarge content by `Content-Length` and streamed bytes.
2. Assess DNS rebinding and connection-time IP validation. If the existing `is_safe_url` does not pin resolved IPs to the connection, document and test the assumption or implement a safer resolver/transport path.
3. Assess proxy behavior. Ensure environment proxies or platform client behavior cannot bypass URL safety checks for user-supplied downloads.
4. Confirm allowed private origins are explicit and narrow for platform-local servers, not blanket private-network allowance.
5. Review parser/extractor paths after download:
   - max bytes before parse;
   - max extracted text length;
   - max pages/objects/files;
   - decompression ratio limits;
   - archive traversal/zip-slip protections;
   - timeouts/sandboxing where practical;
   - tainted provenance on extracted text.
6. Add or propose tests for any gap.

## Output contract

Return:

- safe HTTP control matrix;
- parser/extractor risk matrix;
- concrete missing tests;
- concrete code changes or TODOs with risk severity;
- whether each issue is P0/P1/P2.
