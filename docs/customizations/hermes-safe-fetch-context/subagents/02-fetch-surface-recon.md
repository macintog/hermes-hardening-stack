# Subagent 02: Fetch Surface Reconnaissance

You are a reconnaissance subagent for Hermes safe-fetch hardening.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Mission:
Inspect Hermes for remote fetch/download surfaces and identify the safest first caller to migrate to a shared `safe_http` helper. This is read-only. Do not modify files.

Inspect at minimum:
- `tools/url_safety.py`
- `tools/vision_tools.py`
- `tools/web_tools.py`
- `gateway/platforms/base.py`
- `gateway/platforms/wecom.py`
- `gateway/platforms/feishu.py`
- `gateway/platforms/slack.py`
- `gateway/platforms/qqbot/adapter.py`
- `gateway/platforms/mattermost.py`
- `gateway/platforms/telegram.py`
- `gateway/platforms/discord.py`
- `tools/skills_hub.py`

Look for:
- `httpx`, `requests`, `aiohttp`, `urllib`, `urlopen`
- `follow_redirects=True`
- `response.content` or full-body reads
- missing max-byte caps
- missing content-type checks
- missing redirect target revalidation
- Authorization headers on downloads
- existing `is_safe_url` usage

Deliverable:
A concise report with:
1. Fetch surface table: file, function, remote URL source, current protections, gaps.
2. Risk ranking: high/medium/low.
3. Which paths are credential-bearing.
4. Which paths already have redirect hooks and should be left alone initially.
5. Recommended first migration target and why.
6. Tests needed for that first migration.
7. Compatibility constraints to preserve.

Constraints:
- Do not edit files.
- Do not run broad test suites.
- Do not recommend changing terminal explicit user commands.
- Prefer one contained caller for the first migration.
