# Risk register template

| ID | Risk | Severity | Status | Mitigation | Evidence/Test | Owner |
|---|---|---|---|---|---|---|
| R-001 | | Critical/High/Medium/Low | Fixed/Partial/Open/Accepted | | | |

## Severity guide

- Critical: attacker-controlled content can execute code, exfiltrate secrets, send messages, or persist instructions without trusted authorization.
- High: attacker-controlled content can influence side-effecting tool arguments or persistence under plausible workflow conditions.
- Medium: hardening behavior can be lost during rebase or bypassed by newly added tools/surfaces.
- Low: docs/log hygiene/ergonomic issues that do not directly break containment.
