# Security invariants for hostile-download prompt-injection containment

The hardening should be judged against invariants, not against whether a scanner recognizes a string.

## I1. Remote-content invariant

Any content obtained from the following is untrusted by default:

- arbitrary URL fetch;
- gateway/media/document attachment;
- browser page/snapshot/console/content extraction;
- web search/extract/crawl result;
- OCR/vision-derived text;
- PDF/document/archive/transcript extraction;
- plugin output or plugin-provided context;
- skill/community/hub/plugin content;
- memory recall containing untrusted-derived material;
- cron prompt/output/pre-run script output;
- external API text returned through tools.

A source may become trusted only through explicit local policy or trusted user/system/developer input, not because it was fetched successfully.

## I2. Promotion invariant

No untrusted string may enter a model-visible role or prompt/context slot as if it were instruction. It must be represented as evidence-only data using structured provenance, a dedicated untrusted channel, and/or untrusted-context fencing.

## I3. Authority invariant

Untrusted content cannot authorize side effects, even when it contains plausible task language. It cannot authorize:

- terminal/code execution;
- file writes/deletes/config changes;
- outbound messages or posts;
- credentialed browser/network actions;
- secret reads or secret transmission;
- memory writes;
- cron creation/update/delete;
- skill/plugin install/update/enable/execute;
- downloaded-code execution;
- privileged local policy changes.

## I4. Derived-action invariant

If untrusted content influenced the current turn, side-effecting tool calls require trusted scoped authorization. It is not sufficient to check whether the final tool arguments still contain an untrusted-context tag. Taint must be non-textual or otherwise deterministic.

## I5. Persistence invariant

Untrusted-derived data may be persisted only with durable taint/provenance. When recalled later, it must still be evidence-only and unable to authorize side effects.

## I6. Registry invariant

Every registered tool must declare at least:

- action class;
- side-effect behavior;
- credential use;
- network behavior;
- persistence behavior;
- secret access behavior;
- model-visible output trust level;
- confirmation/authorization requirements.

Unknown side effects fail closed when untrusted context has influenced the turn.

## I7. Confirmation invariant

A confirmation grant must be explicit and scoped. It should bind to:

- user instruction source;
- tool name/action class;
- material arguments or target;
- recipient/destination/path/origin where applicable;
- time/session/single-use limit;
- whether untrusted-derived content may be used as a parameter.

A generic “yes” to an attacker-invented action is insufficient unless the prompt shown to the user clearly distinguishes trusted request from untrusted suggestion.

## I8. Evaluation invariant

Every new ingress surface and side-effecting tool must have adversarial regression tests. The success criterion is deterministic containment by policy or gate, not only a model refusal.
