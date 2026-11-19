#!/usr/bin/env bash
# Smoke tests for stop2shell. No network, no root, no side effects.
# Usage: bash tests/smoke.sh
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT/stop2shell.sh"
PASS=0
FAIL=0
TMP=$(mktemp -d 2>/dev/null || mktemp -d -t stop2shell)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

ok() {
  PASS=$((PASS + 1))
  printf 'ok   %s\n' "$1"
}

no() {
  FAIL=$((FAIL + 1))
  printf 'FAIL %s\n' "$1"
  if [ "${2:-}" != '' ]; then
    printf '     %s\n' "$2"
  fi
}

# Feed one line per argument to the prank. Always non-tty and no colors.
run_lines() {
  for _line in "$@"; do
    printf '%s\n' "$_line"
  done | STOP2SHELL_NO_TTY=1 bash "$SCRIPT" --fast --no-color --no-title --timer 0
}

printf 'stop2shell smoke tests\n'
printf 'script: %s\n\n' "$SCRIPT"

# -- syntax -------------------------------------------------------------------
if bash -n "$SCRIPT" 2>"$TMP/n"; then ok 'bash -n'; else no 'bash -n' "$(cat "$TMP/n")"; fi
if command -v dash >/dev/null 2>&1; then
  if dash -n "$SCRIPT" 2>"$TMP/n"; then ok 'dash -n'; else no 'dash -n' "$(cat "$TMP/n")"; fi
fi

# -- help ---------------------------------------------------------------------
out=$(bash "$SCRIPT" --help 2>&1)
case "$out" in
  *Usage:*'--timer'*) ok 'help lists usage and options' ;;
  *) no 'help lists usage and options' ;;
esac

# -- reveal paths -------------------------------------------------------------
out=$(run_lines 'id' 'stop2shell')
case "$out" in
  *'This was a prank.'*) ok 'stop2shell reveals the prank' ;;
  *) no 'stop2shell reveals the prank' ;;
esac

out=$(run_lines 'exit' 'exit')
case "$out" in
  *'Adorable'*'This was a prank.'*) ok 'second exit reveals the prank' ;;
  *) no 'second exit reveals the prank' ;;
esac

out=$(run_lines 'systemctl stop 2shell')
case "$out" in
  *'Job for 2shell.service canceled.'*'This was a prank.'*) ok 'systemctl stop is an alternate ending' ;;
  *) no 'systemctl stop is an alternate ending' ;;
esac

# -- fake shell ---------------------------------------------------------------
out=$(run_lines 'id')
case "$out" in
  *'uid=0(root)'*) ok 'id is fake root' ;;
  *) no 'id is fake root' ;;
esac

out=$(run_lines 'whoami')
case "$out" in
  *'root'*) ok 'whoami is fake root' ;;
  *) no 'whoami is fake root' ;;
esac

out=$(run_lines 'cat flag.txt')
case "$out" in
  *'flag{2shell_was_inside_you_all_along}'*) ok 'flag is available' ;;
  *) no 'flag is available' ;;
esac

out=$(run_lines 'history')
case "$out" in
  *'stop2shell'*) ok 'history hints at stop2shell' ;;
  *) no 'history hints at stop2shell' ;;
esac

out=$(printf 'id\nstop2shell\n' | STOP2SHELL_NO_TTY=1 bash "$SCRIPT" --fast --no-color --no-title --timer 0 --bare-prompt)
case "$out" in
  *'# uid=0(root)'*) ok 'bare prompt is available for the homage' ;;
  *) no 'bare prompt is available for the homage' ;;
esac

out=$(run_lines 'echo "hello world"')
case "$out" in
  *'hello world'*) ok 'echo strips quotes' ;;
  *) no 'echo strips quotes' ;;
esac

# -- safety -------------------------------------------------------------------
out=$(run_lines 'sudo -i')
case "$out" in
  *'[sudo] password'*|*'Password:'*) no 'sudo never asks for a password' ;;
  *'no password'*) ok 'sudo never asks for a password' ;;
  *) no 'sudo never asks for a password' ;;
esac

out=$(run_lines 'rm -rf /')
case "$out" in
  *'absolutely not'*'nothing was deleted'*) ok 'rm -rf is refused' ;;
  *) no 'rm -rf is refused' ;;
esac

out=$(run_lines 'touch /foobar')
case "$out" in
  *'April Fools!'*'read-only'*) ok 'touch /foobar is the homage beat' ;;
  *) no 'touch /foobar is the homage beat' ;;
esac

printf 'keep me\n' > "$TMP/sentinel"
out=$(cd "$TMP" && run_lines 'rm -rf sentinel' 'stop2shell')
if [ -f "$TMP/sentinel" ]; then ok 'sentinel file survives rm -rf'; else no 'sentinel file survives rm -rf'; fi

marker="$TMP/pwned"
out=$(run_lines "\$(touch $marker)" 'stop2shell')
if [ ! -e "$marker" ]; then ok 'command substitution is not executed'; else no 'command substitution is not executed'; fi
case "$out" in
  *'no injection'*) ok 'injection is answered with a joke' ;;
  *) no 'injection is answered with a joke' ;;
esac

marker2="$TMP/pwned2"
out=$(run_lines "\`touch $marker2\`" 'stop2shell')
if [ ! -e "$marker2" ]; then ok 'backticks are not executed'; else no 'backticks are not executed'; fi

# -- no writes ----------------------------------------------------------------
mkdir -p "$TMP/home"
out=$(HOME="$TMP/home" run_lines 'id' 'stop2shell')
if [ -z "$(find "$TMP/home" -mindepth 1 -print -quit 2>/dev/null)" ]; then
  ok 'does not write to HOME'
else
  no 'does not write to HOME'
fi

# -- source isolation ---------------------------------------------------------
out=$(printf '%s\n' 'stop2shell' | STOP2SHELL_NO_TTY=1 bash -uc 'set -e; . "$1" --fast --no-color --no-title --timer 0; printf "AFTER=%s LEAK=%s\n" "$?" "${S2S_PWD:-none}"' _ "$SCRIPT" 2>&1)
case "$out" in
  *'AFTER=0 LEAK=none'*) ok 'sourcing leaves no variables and does not exit' ;;
  *) no 'sourcing leaves no variables and does not exit' ;;
esac

# -- POSIX shell --------------------------------------------------------------
if command -v dash >/dev/null 2>&1; then
  out=$(printf '%s\n' 'id' 'stop2shell' | STOP2SHELL_NO_TTY=1 dash "$SCRIPT" --fast --no-color --no-title --timer 0 2>&1)
  case "$out" in
    *'This was a prank.'*) ok 'runs under dash' ;;
    *) no 'runs under dash' ;;
  esac
fi

# -- static checks ------------------------------------------------------------
if grep -Eq '(^|[;&|[:space:]])eval[[:space:]]' "$SCRIPT"; then
  no 'no eval in source'
else
  ok 'no eval in source'
fi

if grep -Eq '(bash|sh|zsh|dash)[[:space:]]+-c' "$SCRIPT"; then
  no 'no shell -c in source'
else
  ok 'no shell -c in source'
fi

# -- piped mode with a tty ----------------------------------------------------
if command -v script >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
  out=$(printf 'stop2shell\n' | timeout 20 script -qec "cat '$SCRIPT' | bash -s -- --fast --no-color --no-title --timer 5" /dev/null 2>&1)
  case "$out" in
    *'This was a prank.'*) ok 'curl | bash reopens the tty' ;;
    *) no 'curl | bash reopens the tty' ;;
  esac

  out=$( (sleep 4) | timeout 10 script -qec "'$SCRIPT' --fast --no-color --no-title --timer 2" /dev/null 2>&1)
  case "$out" in
    *'session expired'*) ok 'idle timer reveals the prank' ;;
    *) no 'idle timer reveals the prank' ;;
  esac
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
