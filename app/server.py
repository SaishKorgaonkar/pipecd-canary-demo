"""Tiny demo web app for the PipeCD canary demo.

Behaviour is baked in at build time via the APP_VERSION / APP_BROKEN build args:
  v1  -> healthy, blue page
  v2  -> BROKEN: "/" returns HTTP 500 (simulates a bad release); /healthz still
         returns 200 so the pod becomes Ready and only PipeCD's ANALYSIS stage
         can catch the problem
  v3  -> healthy, green page (the fix)
"""
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = os.environ.get("APP_VERSION", "v1")
BROKEN = os.environ.get("APP_BROKEN", "false").lower() == "true"
COLOR = os.environ.get("APP_COLOR", "#2563eb")
HOST = socket.gethostname()

PAGE = """<!doctype html><html><head><meta charset="utf-8"><title>PipeCD demo {v}</title>
<style>body{{margin:0;font-family:system-ui,sans-serif;background:{c};color:#fff;
display:grid;place-items:center;height:100vh;text-align:center}}h1{{font-size:5rem;margin:0}}
p{{font-size:1.3rem;opacity:.9}}</style></head><body><div>
<h1>Version {v}</h1><p>Served by pod <b>{h}</b></p><p>Deployed by PipeCD (GitOps canary)</p>
</div></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/html"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-App-Version", VERSION)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/healthz":
            return self._send(200, "ok", "text/plain")
        if self.path == "/api/version":
            code = 500 if BROKEN else 200
            return self._send(code, json.dumps({"version": VERSION, "pod": HOST, "ok": not BROKEN}), "application/json")
        if BROKEN:
            return self._send(500, f"500 Internal Server Error ({VERSION} on {HOST}): NullPointerException in checkout()", "text/plain")
        return self._send(200, PAGE.format(v=VERSION, c=COLOR, h=HOST))

    def log_message(self, fmt, *args):  # keep pod logs short: one line per request
        print(f"{VERSION} {self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"starting demo app {VERSION} broken={BROKEN} on :8080", flush=True)
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
