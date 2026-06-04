import http.server
import socket
import os
import json
from datetime import datetime

CREATOR = "akumenbyq"
PORT = 8080


class SwarmHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hostname = socket.gethostname()

        # Get all IPs of this container
        try:
            ip = socket.gethostbyname(hostname)
        except Exception:
            ip = "unknown"

        # Also fetch all interface IPs
        try:
            import subprocess
            result = subprocess.run(
                ["hostname", "-I"], capture_output=True, text=True
            )
            all_ips = result.stdout.strip()
        except Exception:
            all_ips = ip

        container_id = hostname  # In Docker, hostname = short container ID
        request_count = getattr(SwarmHandler, "_count", 0) + 1
        SwarmHandler._count = request_count

        data = {
            "message": f"Hello from replica! Created by {CREATOR}",
            "creator": CREATOR,
            "container_id": container_id,
            "private_ip": ip,
            "all_ips": all_ips,
            "port": PORT,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "request_number": request_count,
            "path": self.path,
        }

        body = json.dumps(data, indent=2).encode()

        # Build a nice HTML response
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Swarm Replica — {CREATOR}</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: 'Courier New', monospace;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 2rem;
    }}
    .card {{
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 12px;
      padding: 2rem 2.5rem;
      max-width: 560px;
      width: 100%;
    }}
    .badge {{
      display: inline-block;
      background: #238636;
      color: #fff;
      font-size: 12px;
      padding: 4px 12px;
      border-radius: 20px;
      margin-bottom: 1.2rem;
      letter-spacing: 1px;
      text-transform: uppercase;
    }}
    h1 {{
      font-size: 1.4rem;
      color: #58a6ff;
      margin-bottom: 0.4rem;
    }}
    .creator {{
      font-size: 1rem;
      color: #f78166;
      margin-bottom: 1.8rem;
    }}
    .row {{
      display: flex;
      justify-content: space-between;
      padding: 0.55rem 0;
      border-bottom: 1px solid #21262d;
      font-size: 0.92rem;
    }}
    .row:last-child {{ border-bottom: none; }}
    .label {{ color: #8b949e; }}
    .value {{ color: #e6edf3; font-weight: bold; }}
    .ip {{ color: #3fb950; font-size: 1.05rem; }}
    .footer {{
      margin-top: 1.5rem;
      font-size: 0.78rem;
      color: #484f58;
      text-align: center;
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">🐳 Docker Swarm Replica</div>
    <h1>Nginx Load Balancer Demo</h1>
    <div class="creator">Created by <strong>{CREATOR}</strong></div>

    <div class="row">
      <span class="label">🖥  Container ID</span>
      <span class="value">{container_id}</span>
    </div>
    <div class="row">
      <span class="label">🌐 Private IP</span>
      <span class="value ip">{ip}</span>
    </div>
    <div class="row">
      <span class="label">📡 All IPs</span>
      <span class="value">{all_ips}</span>
    </span>
    </div>
    <div class="row">
      <span class="label">⚙️  Port</span>
      <span class="value">{PORT}</span>
    </div>
    <div class="row">
      <span class="label">🕐 Timestamp</span>
      <span class="value">{datetime.utcnow().isoformat()}Z</span>
    </div>
    <div class="row">
      <span class="label">📊 Request #</span>
      <span class="value">{request_count}</span>
    </div>

    <div class="footer">
      Refresh to hit a different replica &mdash; watch the IP change!
    </div>
  </div>
</body>
</html>
"""

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("X-Container-ID", container_id)
        self.send_header("X-Private-IP", ip)
        self.send_header("X-Creator", CREATOR)
        self.end_headers()
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        hostname = socket.gethostname()
        try:
            ip = socket.gethostbyname(hostname)
        except Exception:
            ip = "?"
        print(f"[{CREATOR}] [{ip}] [{hostname}] {format % args}")


if __name__ == "__main__":
    print(f"=== Docker Swarm HTTP Server ===")
    print(f"Created by : {CREATOR}")
    print(f"Hostname   : {socket.gethostname()}")
    try:
        print(f"Private IP : {socket.gethostbyname(socket.gethostname())}")
    except Exception:
        print("Private IP : (resolving...)")
    print(f"Listening  : 0.0.0.0:{PORT}")
    print("=" * 32)

    server = http.server.HTTPServer(("0.0.0.0", PORT), SwarmHandler)
    server.serve_forever()
