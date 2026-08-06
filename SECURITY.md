# Security Policy

## Supported versions

Security fixes land in the current release. Moped is a small project with a single
maintainer, so older versions are not patched — please update to the latest release.

| Version | Supported |
|---|---|
| 3.0.x | Yes |
| 2.x and earlier | No |

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Use GitHub's private reporting instead:
[Report a vulnerability](https://github.com/RobertoMachorro/Moped/security/advisories/new).
If that is unavailable to you, open a normal issue saying only that you have a security
report and asking for a private channel — no details.

Please include what you can:

- the Moped version (**Moped ▸ About Moped**) and your macOS version
- what an attacker can do, and what access they need to do it
- steps to reproduce, and a sample file if one is involved

You can expect an acknowledgement within about a week. Fixes are released as soon as
practical, and I'm glad to credit you in the release notes unless you'd rather not be.

## Scope

Moped is a sandboxed, offline text editor: no network access, no telemetry, no accounts.
Reports that are in scope include anything that lets a crafted file escape the sandbox,
execute code, read or write files outside what the user opened, or corrupt a file on save.

Out of scope: crashes or hangs on malformed or very large input with no further consequence.
Those are ordinary bugs — please open a regular issue for them, they are still worth fixing.
