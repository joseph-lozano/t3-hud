#!/usr/bin/env python3
"""Owned local page for exercising the real HUD without touching a T3 server."""
import http.server
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
run_id = root.name
page = '''<!doctype html><meta charset="utf-8"><title>T3 HUD verification</title>
<style>body{font:20px system-ui;padding:40px;background:#eef4fb}input{font:20px system-ui;width:80%;padding:12px}p{font-size:14px}</style>
<h1>T3 HUD verification fixture</h1><p id="run"></p><p id="document"></p>
<label for="draft">Unsent draft</label><br><input id="draft" placeholder="Type a retention marker">
<p>This page never sends messages. Change server availability through the owned verification fixture.</p>
<script>
document.querySelector('#run').textContent='Run: RUN_ID';
document.querySelector('#document').textContent='Document: '+crypto.randomUUID();
const draft=document.querySelector('#draft');draft.value=localStorage.getItem('draft')||'';
draft.addEventListener('input',()=>localStorage.setItem('draft',draft.value));
</script>'''.replace('RUN_ID', run_id).encode()

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def respond(self, body):
        offline = (root / 'offline').exists()
        self.send_response(503 if offline else 200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('X-T3HUD-Verification', run_id)
        self.end_headers()
        if body:
            self.wfile.write(b'Fixture offline' if offline else page)

    def do_HEAD(self):
        self.respond(False)

    def do_GET(self):
        self.respond(True)

server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
(root / 'endpoint.json').write_text(json.dumps({'url': f'http://127.0.0.1:{server.server_port}', 'run': run_id}))
server.serve_forever()
