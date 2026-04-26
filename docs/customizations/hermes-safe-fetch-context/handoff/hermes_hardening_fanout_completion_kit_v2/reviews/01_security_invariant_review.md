# Security invariant review prompt

Review the completed changes against these invariants:

1. External/tool/browser/plugin/skill/gateway/downloaded/extracted/recalled content is untrusted by default.
2. Model-visible string tool outputs are untrusted by default unless registry metadata explicitly marks them trusted internal control output.
3. Untrusted context seen in the current turn structurally affects action authority.
4. Side-effecting tools require trusted scoped authorization under untrusted turn taint.
5. Unknown side-effecting tools fail closed or require confirmation.
6. Browser context tools are classified as credentialed/sensitive when they can inspect or affect sessions.
7. Skill/plugin content cannot execute before trust/provenance and authority checks.
8. Persisted untrusted-derived content remains tainted when recalled.

For each invariant, state: pass, partial, fail, evidence, and required fix.
