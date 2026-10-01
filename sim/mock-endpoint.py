#!/usr/bin/env python3
"""Stand-in for a client's HTTP endpoint (sim/replay-check.sh).

Usage: mock-endpoint.py PORT LOG REJECT_FIRST
Appends one line per accepted POST to LOG: the number of records in the batch, then each key.
The first REJECT_FIRST requests get HTTP 400, so they are dead-lettered.
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

port, log, reject = int(sys.argv[1]), sys.argv[2], int(sys.argv[3])
calls = 0


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        global calls
        calls += 1
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        status = 400 if calls <= reject else 200
        if status == 200:
            with open(log, "a") as out:
                out.write(json.dumps({"n": len(body), "keys": [json.dumps(r["key"], sort_keys=True) for r in body]}) + "\n")
        self.send_response(status)
        self.end_headers()
        self.wfile.write(b"rejected by mock" if status == 400 else b"ok")

    def log_message(self, *args):
        pass


HTTPServer(("localhost", port), Handler).serve_forever()
