#!/usr/bin/env bash
# Shared setup for the proxy-mode examples.
#
# The examples under examples/xben/ capture traffic with h5i's own browser
# (`h5i browser open --capture`). These examples do the same attack, but drive
# a real external Chromium through `h5i browser proxy` instead: h5i runs a
# loopback capture proxy, agent-browser is pointed at it, and every request the
# page makes is recorded in the same session store that `h5i websec` reads. The
# exploit step — `h5i websec replay`/`match` — is identical; only the capture
# path differs.
#
# A script sources this, calls `proxy_start "$URL"`, drives the page with `ab`
# (a thin wrapper over agent-browser bound to the session), inspects and mutates
# traffic with `"$H5I" websec ... --session "$SESSION"`, and prints the flag.
#
# Requirements:
#   * h5i on $PATH (or $H5I) with the websec plugin installed.
#   * agent-browser on $PATH, with a Chromium it can launch. If it cannot find
#     one, set AGENT_BROWSER_EXECUTABLE_PATH, or run `agent-browser install`.
# Optional environment:
#   * AGENT_BROWSER_EXECUTABLE_PATH — Chromium binary, if not auto-detected.
#   * AGENT_BROWSER_EXTRA_ARGS       — extra launch args, comma-separated.
set -uo pipefail

H5I="${H5I:-h5i}"
: "${SESSION:?SESSION must be set before sourcing _proxy-lib.sh}"
FLAG_RE='FLAG\{[^}]+\}'

proxy_cleanup() {
  agent-browser --session "$SESSION" close >/dev/null 2>&1 || true
  "$H5I" browser close --session "$SESSION" >/dev/null 2>&1 || true
}

# proxy_start URL : start the capture proxy and point agent-browser at it.
proxy_start() {
  local url="$1" record
  trap proxy_cleanup EXIT
  record="$("$H5I" browser proxy "$url" --session "$SESSION" --expires-in 3600 --json)"
  PROXY_URL="$(printf '%s' "$record" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["proxy"]["url"])')"
  export AGENT_BROWSER_SESSION="$SESSION"
  export AGENT_BROWSER_PROXY="$PROXY_URL"
  export AGENT_BROWSER_IGNORE_HTTPS_ERRORS=1
  # Bypass the proxy for nothing (route loopback through it too), and run
  # headless without a sandbox, which is what a CI/container host needs.
  export AGENT_BROWSER_ARGS="--no-sandbox,--proxy-bypass-list=<-loopback>${AGENT_BROWSER_EXTRA_ARGS:+,$AGENT_BROWSER_EXTRA_ARGS}"
}

# ab ... : agent-browser bound to this session.
ab() { agent-browser --session "$SESSION" "$@"; }

# go URL : open a page and wait for the DOM, so the next step does not race a
# cold Chromium or an in-flight navigation.
go() { ab open "$1" >/dev/null; ab wait --load domcontentloaded >/dev/null 2>&1 || true; }

# click_sel SELECTOR : wait for the element, then click it.
click_sel() { ab wait "$1" >/dev/null 2>&1 || true; ab click "$1" >/dev/null; }

# req_of METHOD URL-SUBSTRING : the id (e.g. req_19) of the last captured
# request matching method + a substring of the URL.
req_of() {
  "$H5I" websec requests --session "$SESSION" --method "$1" --url-contains "$2" --json 2>/dev/null |
    python3 -c '
import json,sys
ids=[r["id"] for r in json.load(sys.stdin).get("requests",[])
     if str(r.get("id","")).startswith("req_")]
print(ids[-1] if ids else "", end="")'
}

# replay_flag REQ_ID : re-send a captured request and print the flag in its
# response. Use when the flag only appears once some earlier request changed
# server state (so the originally-captured response predates the change).
replay_flag() {
  "$H5I" websec replay "$1" --body --session "$SESSION" 2>/dev/null |
    grep -oE "$FLAG_RE" | head -1
}

# print_flag : scan every stored response for a flag and print it. Uses
# `match --all`, which reads each response's captured bytes directly, so it does
# not depend on a replay's exact body still being in the store.
print_flag() {
  local out
  out="$("$H5I" websec match --all --session "$SESSION" --regex "$FLAG_RE" 2>/dev/null |
    grep -oE "$FLAG_RE" | head -1)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; return 0; fi
  echo "no flag found" >&2; return 1
}
