# Security Policy

Swift-CSV is designed to parse untrusted input. It enforces explicit limits on input
size, record count, fields per record and field size, and it does not recurse. A crash, a
hang, unbounded memory use or a limit that can be bypassed is a security issue.

## Supported versions

Security fixes go to the latest release.

## Reporting a vulnerability

Please report vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/ThorFuchs/Swift-CSV/security/advisories/new).
Do not open a public issue.

Include the input that triggers the problem, the limits used, and the platform and Swift
version. You can expect an initial response within a week. Fixes are released as patch
versions, with credit unless you prefer otherwise.
