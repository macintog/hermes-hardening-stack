Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: browser and credentialed network context

## Task

Review browser-related tools and classification. Ensure browser-console/browser-context capabilities are treated as credentialed/sensitive where appropriate.

## Read/search

- `tools/browser_tool.py`
- `tools/web_tools.py`
- `agent/action_authority.py`
- `agent/context_safety.py`
- browser snapshot/console/navigation/click/type/download tools
- tests around browser or action authority

## Required assessment

Classify at least these categories:

- public read-only web search/extract;
- browser snapshot of current page;
- browser console;
- browser navigation/click/type;
- credentialed browser session actions;
- browser downloads or file access;
- web extraction output shown to model.

## Expected direction

`browser_console` should not be treated as ordinary read-only fetch if it can inspect or execute within a credentialed browser context. It should require confirmation or block under untrusted turn taint.

## Tests

Add/update tests for:

- browser console requires confirmation/block after untrusted content;
- browser navigation/click/type are not authorized by hostile page text;
- browser/web extraction output is untrusted evidence.
