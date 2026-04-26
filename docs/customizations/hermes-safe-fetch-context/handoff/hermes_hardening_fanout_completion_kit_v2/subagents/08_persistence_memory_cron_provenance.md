Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: persistence, memory, cron, and provenance

## Task

Audit durable state paths to ensure untrusted-derived content remains tainted and cannot reappear later as trusted instruction.

## Read/search

- `agent/memory_manager.py`
- memory provider/tool code
- `cron/scheduler.py`
- `tools/cronjob_tools.py`
- `agent/artifact_provenance.py`
- `agent/action_authority.py`
- tests around memory/cron/security

## Required behavior

- Memory writes derived from untrusted content require trusted scoped authorization.
- Cron creation/update derived from untrusted content requires trusted scoped authorization.
- Persisted untrusted-derived data is stored with provenance or always recalled as untrusted evidence.
- Cron pre-run output and context_from output remain untrusted when promoted into job prompts.

## Tests

Add or update tests for:

- hostile downloaded text cannot create/update cron jobs;
- hostile downloaded text cannot write persistent memory as trusted preference;
- recalled memory derived from external content remains fenced/tainted;
- cron output cannot authorize outbound messages or shell commands.
