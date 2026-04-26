# Subagent S04 — Tool-result promotion default-taint policy

## Role

You are the model-visible tool-result promotion subagent. Your job is to make tool outputs untrusted by default when promoted into model context.

## Files to inspect

```text
agent/context_safety.py
agent/artifact_provenance.py
agent/action_authority.py
model_tools.py
run_agent.py
browser/web/search/extract/OCR/PDF/document/transcript tool integrations
plugin/tool-result append paths
```

## Tasks

1. Find every place tool results are appended to messages or otherwise made model-visible.
2. Identify current known extraction-like handling from patch 0005.
3. Invert the default if feasible:
   - all string output from tools is untrusted by default;
   - only explicit trusted internal control output bypasses fencing/taint;
   - JSON output with string fields should preserve taint at field or envelope level when practical.
4. Ensure results from web/search/browser/OCR/PDF/document/transcript/gateway/skill/memory/plugin surfaces are fenced or represented as evidence-only.
5. Ensure tool-result taint contributes to turn taint used by action authority.
6. Avoid double-fencing or corrupting structured outputs where downstream code expects JSON. Use envelopes if better.
7. Add tests covering:
   - known extraction tool output;
   - unknown tool returning hostile string;
   - JSON result with hostile string field;
   - trusted internal control result exemption;
   - subsequent side-effecting tool blocked because previous result tainted the turn.

## Output contract

Return:

- promotion surface inventory;
- proposed default-taint policy;
- code paths to change;
- tests to add;
- compatibility risks and mitigation.
