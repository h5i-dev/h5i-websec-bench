# XBOW benchmarks, solved in proxy mode

Worked solutions to the [XBOW Validation
Benchmarks](https://github.com/xbow-engineering/validation-benchmarks), using
h5i's capture proxy: a real external Chromium, driven by
[`agent-browser`](https://github.com/h5i-dev/agent-browser), with its HTTP/S
traffic captured through `h5i browser proxy`. The exploit step is always `h5i
websec` on the captured traffic — inspect, replay, diff, match — so what the
script demonstrates is the attack, not a scripted HTTP client.

Since h5i 0.5.0 every browser session *is* a Chromium behind the capture proxy
(the old in-process browser and its `--capture` flag were removed), so these are
the canonical worked solutions for this corpus. A session can be started two
ways; these scripts use the explicit form so the pieces are visible:

```
  explicit (these scripts)              one command (0.5.0)
  h5i browser proxy  +  agent-browser   h5i browser open URL
```

Either way the messages land in the session store that `h5i websec` reads, so
replay, diff and match work the same.

## Setup

In addition to the corpus and Docker:

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

* `proxy_start URL [extra-origin …]` — start the capture proxy and point
  agent-browser at it (headless, no-sandbox, loopback routed through the proxy).
  Extra origins are added to the allowlist for multi-service targets. Registers
  cleanup on exit.
* `ab …` — agent-browser bound to this session.
* `go URL` — open a page and wait for the DOM, so a step does not race a cold
  Chromium or an in-flight navigation.
* `click_sel SELECTOR` — wait for an element, then click it.
* `req_of METHOD URL-SUBSTRING` — the id (e.g. `req_19`) of the last captured
  request matching a method and a URL substring, to feed `h5i websec replay`.
* `replay_flag REQ_ID` — re-send a captured request and print the flag from its
  response. Needed when the flag only appears after some earlier request changed
  server state, so the originally captured response predates the change.
* `print_flag` — scan every stored response for a flag (`h5i websec match
  --all`).

### Authenticated replays: `--as`

`h5i websec replay` re-sends a stored request's exact bytes and does **not** pull
cookies from the session jar — that is opt-in. So when a script logs in with one
replay and then acts as that user with another, the second replay must carry the
login cookie explicitly:

```bash
# log in (the server's Set-Cookie goes into this session's jar)
h5i websec replay "$BASE" --create --session "$S" --as "$S" --set method=POST --set path=/login ...
# act as the logged-in user: --as sends this session's jar cookies
h5i websec replay "$BASE" --create --session "$S" --as "$S" --set method=GET --set path=/orders/42 ...
```

`--as "$S"` injects session `S`'s own `Cookie`/`Authorization`; `--as other`
borrows another session's identity (the IDOR "do it as user B" move). Where a
request sets a forged credential explicitly (e.g. an `alg=none` JWT in a
cookie), do **not** add `--as` on that step — it would re-inject the real token
and overwrite the forged one.

## Verified scripts vs. drafts

* Scripts in **this directory** are run against a freshly built instance and
  verified to return the corpus's exact flag — 99 benchmarks: 001–022, 024–104
  except 023, 030, 066, 088, 092 (the IDOR, reflected-XSS, SQLi incl. blind
  boolean/char-exfil, SSTI, LFI, SSRF, file-upload-to-RCE, OS/argument command
  injection, GraphQL, JWT, deserialization and type-juggling families). Most are
  a single replayed request, or a short login followed by one; the multi-step
  ones (padding oracle, CBC bitflip, pearcmd LFI→RCE, Struts OGNL) drive several
  `h5i websec` steps.
* **[`draft/`](./draft/)** holds `023`, distilled from a recorded solver
  transcript but not reproduced end to end: the Jinja SSTI RCE gadget
  (`config.__init__.__globals__.os.popen`) fires, but a reliable script is still
  blocked by flaky login-session persistence across fresh instances and by
  `/flag` being a 22-byte decoy. It is left in `draft/` rather than labelled
  solved.

The remaining corpus benchmarks (030, 066, 088, 092) have no worked solution
here.

### A note on `xben-084`

`xben-084` is an **authored** worked solution, not a blind agent solve, and is
only partly proxy-mode: the fake S3 service sits on a second published port the
app URL does not reveal, so that port is discovered with `docker` (as the
corpus's own tooling does) and then driven through the proxy. Its header says so.
