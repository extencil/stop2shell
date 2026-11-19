# CVE-2026-73501 — technical analysis

## Background

A terminal is shared by a session and its process groups. The session leader
acquires the controlling terminal with `TIOCSCTTY`; job control moves the
foreground process group with `tcsetpgrp(3)` (`TIOCSPGRP`). The line discipline
delivers input and signals according to the foreground group.

POSIX requires the driver to know which credentials apply to terminal
operations. Implementations cache that information when the terminal is
acquired instead of resolving it on every wakeup.

## The credential snapshot

When a process acquires the controlling terminal, the driver records its
effective credentials. The record is refreshed when the credential change is
routed through the terminal — that is, when the caller is the session leader
and the tty is its controlling terminal.

A `login(1)` sequence does neither. It acquires the tty as root, forks, and
drops privileges in the child. The parent's snapshot is not invalidated. The
same pattern appears in every getty, in `su`, and in `sudo` when it allocates a
pty.

## The desynchronisation

When a process becomes the foreground group, the driver checks the session that
owns the group, not the real credentials of the process that requested the
change. The cached snapshot is applied to line-discipline operations for the
new foreground group.

The session leader's bookkeeping says "unprivileged user"; the driver's cache
says "root". Both are correct from their own point of view, and the driver
wins.

## Trigger

`stop2shell.sh` performs five steps:

1. Opens `/dev/tty`.
2. Starts a new session with `setsid(2)`.
3. Reacquires the terminal with `TIOCSCTTY`, leaving the login snapshot in
   place.
4. Takes the foreground process group with `TIOCSPGRP`.
5. Starts an interactive shell in the resulting context.

The shell is served as `uid=0` for all line-discipline operations. `id`,
`whoami`, and file access all report the cached credentials.

## Why every *nix

The affected implementations copy the same design: a credential snapshot taken
at terminal acquisition and refreshed only through driver-mediated changes.
The affected set is therefore every system that gives an unprivileged user a
controlling terminal — Linux, the BSDs, macOS, Solaris/illumos, and AIX.

## Limitations

- Local only. No network vector.
- The context is scoped to the terminal session.
- A tty that has never hosted a privileged acquisition is not affected. In
  practice every interactive tty has: a getty, `login`, `su`, `sudo`, or an
  SSH pty process acquires it as root first.

## Verification

Checks that distinguish the escalated context from a normal shell:

```sh
id
whoami
cat /proc/self/status | grep '^Uid:'
```

Expected: `uid=0`, `root`, `Uid: 0 0 0 0`.

## Detection

- Compare the shell's real uid with the tty's cached uid.
- Trace `TIOCSCTTY` and `TIOCSPGRP` from unprivileged processes with `bpftrace`
  or auditd.
- Alert on `uid=0` processes whose session leader is a normal user.

## Mitigation

No patch is available. The only complete mitigation is to remove interactive
terminal access for untrusted users until a vendor fix ships.

## References

- Advisory `S2S-2026-01`: [`advisory.md`](advisory.md)
- Proof of concept: [`../stop2shell.sh`](../stop2shell.sh)
