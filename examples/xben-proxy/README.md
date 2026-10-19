# XBOW benchmarks, solved in proxy mode

Worked solutions to the [XBOW Validation
Benchmarks](https://github.com/xbow-engineering/validation-benchmarks), using
h5i in **proxy mode**: a real external Chromium, driven by
[`agent-browser`](https://github.com/h5i-dev/agent-browser), with its HTTP/S
traffic captured through `h5i browser proxy`.

The sibling directory [`../xben/`](../xben/) solves the same corpus with h5i's
own browser (`h5i browser open --capture`). These scripts are the proxy-mode
twins. The exploit is identical — inspect and resend the captured request with
`h5i websec` — and only the capture path differs:

```
          examples/xben/                     examples/xben-proxy/
  capture  h5i browser open --capture        h5i browser proxy  +  agent-browser
  drive    h5i browser type/click/navigate   agent-browser open/fill/click
  attack   h5i websec replay / match         h5i websec replay / match   (same)
```

Proxy mode is what you use when the target needs a full browser engine — real
JavaScript, a login the page performs itself — but you still want every request
recorded and replayable. h5i runs a loopback capture proxy; agent-browser is
pointed at it; the messages land in the same session store that `h5i websec`
reads, so replay, diff and match work exactly as in the native-browser
examples.

## Setup

In addition to the corpus and Docker (see [`../xben/README.md`](../xben/README.md)):

* **h5i** on `$PATH` (or `$H5I`) with the `websec` plugin installed.
* **agent-browser** on `$PATH`, with a Chromium it can launch. If it cannot find
  one, run `agent-browser install`, or point `AGENT_BROWSER_EXECUTABLE_PATH` at
  a Chromium binary.

```bash
URL="$(./scripts/xben.sh up XBEN-005-24)"
H5I=../h5i/target/release/h5i ./examples/xben-proxy/xben-005-idor-post-privesc.sh "$URL"
./scripts/xben.sh down XBEN-005-24
```

Each script accepts a URL and prints the flag. Its output is checked against the
flag the corpus computes for that benchmark (`FLAG{sha256(NAME)}`), so a pass
means the exact expected string came back.

## The shared setup

[`_proxy-lib.sh`](./_proxy-lib.sh) holds the boilerplate every script sources:

* `proxy_start URL` — start the capture proxy and point agent-browser at it
  (headless, no-sandbox, loopback routed through the proxy). Registers cleanup
  on exit.
* `ab …` — agent-browser bound to this session.
* `go URL` — open a page and wait for the DOM, so a step does not race a cold
  Chromium or an in-flight navigation.
* `click_sel SELECTOR` — wait for an element, then click it.
* `req_of METHOD URL-SUBSTRING` — the id (e.g. `req_19`) of the last captured
  request matching a method and a URL substring, to feed `h5i websec replay`.
* `replay_flag REQ_ID` — re-send a captured request and print the flag from its
  response. Needed when the flag only appears after some earlier request changed
  server state, so the originally captured response predates the change.
* `print_flag` — scan stored response bodies for a flag, newest first.

## Verified scripts vs. drafts

* Scripts in **this directory** are run against a freshly built instance and
  verified to return the corpus’s exact flag. So far 93: benchmarks 001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 018, 019, 020, 021, 022, 024, 025, 026, 027, 028, 029, 031, 032, 033, 034, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 060, 061, 062, 063, 064, 065, 067, 068, 069, 070, 071, 072, 073, 074, 075, 076, 077, 078, 079, 080, 083, 085, 086, 087, 089, 090, 091, 093, 094, 096, 098, 099, 100, 101, 102, 103, 104 — the IDOR, reflected-XSS, SQLi (incl. blind boolean/char-exfil), SSTI, LFI, SSRF, file-upload-to-RCE, OS-command-injection, GraphQL and type-juggling families, where the attack is a single replayed request (or a short browser
  login followed by one).
* **[`draft/`](./draft/)** holds the remaining 2 benchmarks, distilled
  automatically from the recorded solver transcript. They capture the real
  proxy-mode exploit (the `h5i websec` steps are the attack) and each one's
  header carries the agent's own account of the vulnerability. They are **not
  yet re-run against a fresh instance**: request ids (`req_N`) and snapshot refs
  (`@eN`) are from the recorded session and generally need re-deriving with
  `h5i websec requests`. A draft is promoted into this directory once it has
  been fixed up and verified. Four drafts whose payloads do not survive
  mechanical shell reconstruction (tricky quoting) record their commands as
  comments instead of running them.
