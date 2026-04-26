# Subagent S06 — Persistence, memory, cron, skills, and plugins

## Role

You are the persistence and semi-instructional surface subagent. Your job is to prevent hostile content from being stored or loaded later as trusted instruction.

## Files to inspect

```text
agent/memory_manager.py
agent/context_references.py
agent/context_safety.py
cron/scheduler.py
tools/cronjob_tools.py
tools/skills_tool.py
tools/skills_hub.py
agent/skill_commands.py
plugin hooks, especially pre_llm_call and pre_tool_call paths
any generated notes/files/context persistence helpers
```

## Tasks

1. Determine where untrusted-derived text can be persisted:
   - memory;
   - cron prompts and pre-run output;
   - skills/plugins;
   - generated files;
   - project context files;
   - notes/profile/preferences.
2. Ensure persisted untrusted-derived content stores durable taint/provenance and re-enters model context as evidence-only.
3. Ensure memory writes under untrusted influence require trusted scoped authorization and preserve taint if allowed.
4. Ensure cron creation/update under untrusted influence requires trusted scoped authorization.
5. Audit skill/plugin paths:
   - external/community/plugin skill content is evidence-only;
   - skill install/update/enable/execute is gated;
   - plugin pre-LLM context is fenced/tainted;
   - plugin tool outputs are untrusted by default;
   - inline shell expansion or command execution cannot occur before authority gating.
6. Add tests:
   - hostile memory poisoning remains tainted on recall;
   - hostile cron output cannot authorize actions;
   - hostile skill content cannot install/execute or write memory;
   - inline shell expansion is disabled/gated for untrusted skill/plugin content.

## Output contract

Return:

- persistence surface inventory;
- current gaps;
- proposed code changes;
- tests;
- any high-risk execution-before-fencing finding called out explicitly.
