# Hermes hardening fan-out completion kit v2

This package is for a fresh Hermes / GPT-5.5 session with subagent support. It is a completion-oriented fan-out kit for `macintog/hermes-hardening-stack` after the latest review found that the executable five-patch stack had improved but the methodology/handoff still had blocking gaps.

Start with:

```text
00_BASIC_INSTANTIATION_PROMPT.md
```

Then give the session the full package and instruct it to use:

```text
01_ORCHESTRATOR_PROMPT.md
02_DISPATCH_MATRIX.yaml
```

The most important completion goals are:

- preserve `0005` everywhere;
- fix stale docs and rebase refresh procedures;
- add or enforce structured turn taint;
- make tool string outputs untrusted by default;
- harden browser/skill/plugin sensitive surfaces;
- add deterministic adversarial tests;
- update verifier/drift checks;
- produce a final zip of changed artifacts and verification summaries.

Recommended placement in the patch-stack repo:

```bash
$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/handoff/hermes_hardening_fanout_completion_kit_v2/
```

Do not place this kit inside `patches/hermes-safe-fetch-context/`; that directory is for executable patch files and metadata.
