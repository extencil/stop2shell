# Security policy

## Reporting a vulnerability

Do not open a public issue for a security defect in the proof of concept.

Report privately through GitHub's vulnerability reporting:

<https://github.com/extencil/stop2shell/security/advisories/new>

Include:

- affected version of `stop2shell.sh`;
- a minimal reproduction;
- expected and observed behaviour.

Initial response within 72 hours.

## Scope

In scope:

- Input handling in the PoC's session: any path that executes user input,
  writes to the filesystem, or opens a network connection.
- Terminal state after exit: prompt, title, colors, and shell options.
- Shell portability: `bash`, `dash`, `sh`.

Out of scope:

- The vulnerability described in the advisory. This repository is the
  reference proof of concept, not a fix.
- Cosmetic differences in the simulated session.
