# Verification review prompt

Review the final verification evidence.

Required:

- current patch repo commit SHA;
- Hermes base ref and/or upstream ref;
- final patch series;
- patch application result;
- compile/import result;
- targeted test result;
- new security tests added and what they cover;
- failures, skips, warnings, and their significance;
- whether logs are suitable for public commit or should be summarized/redacted.

Return a concise verification signoff or blocker list.
