# Nginx Load Balancer Demo — Docker Swarm

> Created by **akumenbyq**

Round-robin load balancing across 3–5 HTTP server replicas using Nginx + Docker Swarm. Every request shows the replica's **private IP**, **container ID**, and creator tag.

---

## Project Structure

```
swarm-nginx-demo/
├── app/
│   ├── server.py        # Python HTTP server — prints IP + creator
│   └── Dockerfile
├── nginx/
│   └── nginx.conf       # Nginx reverse proxy config
├── docker-compose.yml   # Swarm stack definition
└── run.sh               # Helper script for all commands
```

---

## Prerequisites

- Docker 20+ installed
- Single machine (swarm will auto-init) **or** multiple machines

---

## Quick Start

### 1. Deploy (3 replicas by default)

```bash
bash run.sh up
```

**Expected output:**
```
================================================
  Nginx Load Balancer Demo — Docker Swarm
  Created by: akumenbyq
================================================

✔  Swarm is already active.
📦 Building app image...
✔  Image built: swarm-demo-app:latest

🚀 Deploying stack 'nginxdemo'...
Creating network nginxdemo_swarm-net
Creating config nginxdemo_nginx_conf
Creating service nginxdemo_app
Creating service nginxdemo_nginx

⏳ Waiting for replicas to start...

📋 Stack services:
ID             NAME              MODE         REPLICAS   IMAGE                    PORTS
a1b2c3d4e5f6   nginxdemo_app     replicated   3/3        swarm-demo-app:latest
b2c3d4e5f6g7   nginxdemo_nginx   replicated   1/1        nginx:1.25-alpine        *:80->80/tcp

📋 All tasks:
NAME                  NODE       CURRENT STATE     IMAGE
nginxdemo_app.1       manager1   Running           swarm-demo-app:latest
nginxdemo_app.2       worker1    Running           swarm-demo-app:latest
nginxdemo_app.3       worker2    Running           swarm-demo-app:latest
nginxdemo_nginx.1     manager1   Running           nginx:1.25-alpine

✅ Demo is live!
   Open: http://localhost
   Refresh repeatedly to see different replica IPs.
```

---

### 2. Test Round-Robin (watch IPs rotate)

```bash
bash run.sh test
```

**Expected output:**
```
================================================
  Nginx Load Balancer Demo — Docker Swarm
  Created by: akumenbyq
================================================

🔁 Sending 10 requests to http://localhost — watch IPs rotate!

  Request #1  → Replica IP: 10.0.1.4:8080   HTTP: 200
  Request #2  → Replica IP: 10.0.1.5:8080   HTTP: 200
  Request #3  → Replica IP: 10.0.1.6:8080   HTTP: 200
  Request #4  → Replica IP: 10.0.1.4:8080   HTTP: 200
  Request #5  → Replica IP: 10.0.1.5:8080   HTTP: 200
  Request #6  → Replica IP: 10.0.1.6:8080   HTTP: 200
  Request #7  → Replica IP: 10.0.1.4:8080   HTTP: 200
  Request #8  → Replica IP: 10.0.1.5:8080   HTTP: 200
  Request #9  → Replica IP: 10.0.1.6:8080   HTTP: 200
  Request #10 → Replica IP: 10.0.1.4:8080   HTTP: 200

✅ Round-robin confirmed — each request hit a different replica!
```

> Notice IPs cycle: `.4 → .5 → .6 → .4 → ...` — that's Nginx round-robin!

---

### 3. Show Replica Private IPs

```bash
bash run.sh ips
```

**Expected output:**
```
🌐 Replica container IPs:

  a1b2c3d4e5f6  nginxdemo_app.1  → 10.0.1.4  [Created by: akumenbyq]
  b2c3d4e5f6g7  nginxdemo_app.2  → 10.0.1.5  [Created by: akumenbyq]
  c3d4e5f6g7h8  nginxdemo_app.3  → 10.0.1.6  [Created by: akumenbyq]
```

---

### 4. Scale to 5 Replicas

```bash
bash run.sh scale 5
```

**Expected output:**
```
⚙️  Scaling app to 5 replicas...
nginxdemo_app scaled to 5
overall progress: 5 out of 5 tasks
1/5: running
2/5: running
3/5: running
4/5: running
5/5: running
verify: Service converged

📋 Tasks after scaling:
NAME                NODE       CURRENT STATE
nginxdemo_app.1     manager1   Running
nginxdemo_app.2     worker1    Running
nginxdemo_app.3     worker2    Running
nginxdemo_app.4     worker1    Running
nginxdemo_app.5     manager1   Running
```

---

### 5. View Live Nginx Logs

```bash
bash run.sh logs
```

**Expected output:**
```
nginxdemo_nginx.1 | 172.20.0.1 -> upstream:10.0.1.4:8080 [15/Jan/2024:10:30:01] "GET / HTTP/1.1" 200 upstream_response_time=0.002
nginxdemo_nginx.1 | 172.20.0.1 -> upstream:10.0.1.5:8080 [15/Jan/2024:10:30:02] "GET / HTTP/1.1" 200 upstream_response_time=0.001
nginxdemo_nginx.1 | 172.20.0.1 -> upstream:10.0.1.6:8080 [15/Jan/2024:10:30:03] "GET / HTTP/1.1" 200 upstream_response_time=0.002
```

> Each line shows a different `upstream:IP` — proof of round-robin in action.

---

### 6. Browser Output

When you open `http://localhost` in a browser, each replica returns:

```
🐳 Docker Swarm Replica

Nginx Load Balancer Demo
Created by akumenbyq

Container ID    a1b2c3d4e5f6
Private IP      10.0.1.5          ← changes on each refresh!
All IPs         10.0.1.5 10.0.0.3
Port            8080
Timestamp       2024-01-15T10:35:22Z
Request #       7
```

---

### 7. Manual curl with headers

```bash
curl -v http://localhost 2>&1 | grep -E "X-Handled-By|X-Creator|X-Container"
```

**Expected output:**
```
< X-Handled-By: 10.0.1.4:8080
< X-Creator: akumenbyq
```

---

## Cleanup

```bash
# Remove stack only
bash run.sh down

# Remove stack + image
bash run.sh clean
```

---

## How It Works

```
Browser / curl
      │
      ▼  port 80
┌─────────────┐
│    Nginx    │  ← single entry point
│  (replica 1)│
└──────┬──────┘
       │  overlay network (swarm-net)
       │  DNS: "app" → [10.0.1.4, 10.0.1.5, 10.0.1.6]
       │  round-robin each request
       ├──────────────────────┐──────────────────────┐
       ▼                      ▼                      ▼
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│  app.1      │        │  app.2      │        │  app.3      │
│  10.0.1.4   │        │  10.0.1.5   │        │  10.0.1.6   │
│  port 8080  │        │  port 8080  │        │  port 8080  │
│ akumenbyq   │        │ akumenbyq   │        │ akumenbyq   │
└─────────────┘        └─────────────┘        └─────────────┘
```

Docker Swarm's internal DNS resolves the service name `app` to all healthy replica IPs.
Nginx uses these IPs in its upstream pool and round-robins requests across them.
If a replica dies, Swarm restarts it — Nginx retries automatically.

---

## Key Concepts Demonstrated

| Concept | Where |
|---|---|
| Overlay network | `swarm-net` connects nginx ↔ app replicas |
| Service DNS | Nginx uses `server app:8080` — Swarm resolves to all IPs |
| Ingress routing mesh | Port 80 published on ALL nodes, any node accepts traffic |
| Round-robin LB | Nginx cycles through replica IPs per request |
| Self-healing | Kill a container — Swarm replaces it in seconds |
| Rolling updates | `docker service update --image ...` updates one at a time |
| Replica scaling | `bash run.sh scale 5` adds 2 more replicas live |

---

> Created by **akumenbyq**
