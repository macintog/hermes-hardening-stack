# Subagent S03 — Tool registry metadata and fail-closed classification

## Role

You are the tool security metadata subagent. Your job is to ensure Hermes tools declare their authority and output behavior explicitly, and that missing metadata cannot silently allow side effects.

## Files to inspect

```text
tools/registry.py
toolsets.py
model_tools.py
run_agent.py
agent/action_authority.py
all tool registration/discovery paths
```

Also inspect dynamic/plugin/MCP/delegate/browser/toolset registration paths if present.

## Tasks

1. Inventory every registered/builtin tool and dynamic tool path.
2. Define a `ToolSecurityMetadata` schema or equivalent. It should include:
   - `action_class`;
   - `side_effecting`;
   - `credentialed`;
   - `network_access`;
   - `secret_access`;
   - `persistence`;
   - `output_trust`;
   - `output_surface`;
   - `requires_trusted_authorization`;
   - `confirmation_policy`.
3. Modify registration/discovery so metadata is mandatory for builtin tools.
4. For dynamic/plugin tools, default to conservative metadata:
   - side-effect unknown;
   - output untrusted;
   - require confirmation or block when untrusted turn taint is active.
5. Replace hard-coded tool-name heuristics where feasible with registry metadata.
6. Add tests that fail if a builtin tool lacks metadata.
7. Add tests that an unknown side-effecting dynamic tool is blocked or requires confirmation after untrusted influence.

## Important constraints

- Do not preserve the compatibility behavior “unknown side effect with no visible untrusted tag is allowed” when structured taint says untrusted content influenced the turn.
- Read-only tools can still leak through URLs, credentials, or browser state; metadata must distinguish unauthenticated public fetches from credentialed network/browser actions.

## Output contract

Return:

- inventory summary;
- metadata schema;
- classification matrix;
- file-level changes;
- tests;
- any tools that require human policy decisions.
