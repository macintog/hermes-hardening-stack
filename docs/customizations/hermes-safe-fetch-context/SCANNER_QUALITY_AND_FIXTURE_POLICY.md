# Scanner quality regression policy

## Purpose

This document governs prompt-injection scanner regression behavior for the
`hermes-safe-fetch-context` hardening payload.

The hard security boundary is provenance-based containment plus deterministic
action authority. Scanner findings are warning, audit, reporting, and regression
metadata. They must never be treated as proof that content is safe, trusted, or
authorized.

## Non-negotiable boundary rule

External, downloaded, gateway-supplied, tool-produced, recalled, cron-supplied,
skill-supplied, plugin-supplied, or `@`-referenced content is evidence-only
because of provenance. It stays evidence-only even when the scanner reports no
findings.

Allowed consequences of a scanner finding:

- add audit metadata;
- block or fence a promotion surface according to the surface policy;
- make a report more specific;
- fail a scanner-quality regression test.

Disallowed consequences of a scanner verdict:

- promote external content to trusted user intent;
- authorize side-effecting tool calls;
- suppress deterministic provenance/authority checks;
- treat a clean scan as permission to unfence or obey downloaded text.

## Required regression metadata

Manifest-driven scanner regressions should record:

- `id`;
- `surface`;
- `sample_text`;
- `expected_categories`;
- optional `expected_rule_ids`;
- `expected_min_severity`.

Regression cases should test detection/classification and containment separately:

- detection/classification: the expected finding category or rule is present;
- containment: the verdict does not upgrade external content to trusted
  authority;
- action authority: separate tests prove evidence-only text cannot authorize
  side-effecting tools.

## Scanner implementation policy

The deterministic scanner should catch high-signal families, including:

- instruction override;
- prompt disclosure/leak attempts;
- role or prompt-boundary spoofing;
- tool/action steering;
- secrecy/deception instructions;
- secret access or exfiltration attempts;
- hidden, invisible, or encoded instruction-like text.

The scanner should normalize obvious evasions before matching: case,
punctuation, whitespace, Unicode compatibility forms, invisible/bidi controls,
simple letter spacing, and conservative leetspeak. Normalization is a scanner
quality measure only; it is not a trust boundary.

LLM-assisted classification may be used offline to expand reviewed regression
fixtures, or as advisory-only metadata. It must not be placed in the live
authorization path. A runtime LLM classifier, if ever added, must have no tools,
no memory, no secrets, no authority to mark content safe, and malformed output
must be treated as suspicious.
