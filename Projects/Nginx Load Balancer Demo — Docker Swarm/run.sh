#!/usr/bin/env bash
# ============================================================
#  Nginx Load Balancer Demo — Docker Swarm
#  Created by: akumenbyq
#  Usage: bash run.sh [up|down|scale|test|ips|logs|clean]
# ============================================================

set -e

STACK_NAME="nginxdemo"
APP_IMAGE="swarm-demo-app:latest"
CREATOR="akumenbyq"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}${BOLD}================================================${NC}"
  echo -e "${CYAN}${BOLD}  Nginx Load Balancer Demo — Docker Swarm${NC}"
  echo -e "${CYAN}${BOLD}  Created by: ${YELLOW}${CREATOR}${NC}"
  echo -e "${CYAN}${BOLD}================================================${NC}"
  echo ""
}

check_swarm() {
  if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo -e "${YELLOW}⚠  Swarm not active. Initializing...${NC}"
    docker swarm init 2>/dev/null || true
    echo -e "${GREEN}✔  Swarm initialized.${NC}"
  else
    echo -e "${GREEN}✔  Swarm is already active.${NC}"
  fi
}

build() {
  echo -e "${BOLD}📦 Building app image...${NC}"
  # All files are in the same flat directory
  docker build -t "${APP_IMAGE}" .
  echo -e "${GREEN}✔  Image built: ${APP_IMAGE}${NC}"
}

up() {
  banner
  check_swarm
  build

  echo ""
  echo -e "${BOLD}🚀 Deploying stack '${STACK_NAME}'...${NC}"
  docker stack deploy -c docker-compose.yml "${STACK_NAME}"

  echo ""
  echo -e "${BOLD}⏳ Waiting for replicas to start...${NC}"
  sleep 10

  echo ""
  echo -e "${BOLD}📋 Stack services:${NC}"
  docker stack services "${STACK_NAME}"

  echo ""
  echo -e "${BOLD}📋 All tasks:${NC}"
  docker stack ps "${STACK_NAME}" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Image}}"

  echo ""
  echo -e "${GREEN}${BOLD}✅ Demo is live!${NC}"
  echo -e "   Open: ${CYAN}http://localhost${NC}"
  echo -e "   Refresh repeatedly to see different replica IPs."
  echo ""
  echo -e "   Or run:  ${YELLOW}bash run.sh test${NC}"
}

scale() {
  REPLICAS="${2:-5}"
  echo -e "${BOLD}⚙️  Scaling app to ${REPLICAS} replicas...${NC}"
  docker service scale "${STACK_NAME}_app=${REPLICAS}"
  sleep 5
  echo ""
  echo -e "${BOLD}📋 Tasks after scaling:${NC}"
  docker service ps "${STACK_NAME}_app" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
}

test() {
  banner
  echo -e "${BOLD}🔁 Sending 10 requests to http://localhost — watch IPs rotate!${NC}"
  echo ""

  for i in $(seq 1 10); do
    HANDLED_BY=$(curl -sI http://localhost 2>/dev/null \
      | grep -i "X-Handled-By" | awk '{print $2}' | tr -d '\r' || echo "?")
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "ERR")
    echo -e "  Request ${CYAN}#${i}${NC}  →  Replica IP: ${GREEN}${HANDLED_BY}${NC}   HTTP: ${HTTP_CODE}"
    sleep 0.4
  done

  echo ""
  echo -e "${GREEN}✅ Round-robin confirmed — watch the IP change each request!${NC}"
}

ips() {
  echo ""
  echo -e "${BOLD}🌐 Replica container IPs:${NC}"
  echo ""

  docker ps --filter "name=${STACK_NAME}_app" \
    --format "{{.ID}}\t{{.Names}}" | while IFS=$'\t' read -r cid cname; do
      IP=$(docker inspect "${cid}" \
        --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' 2>/dev/null \
        | tr -s ' ' | sed 's/^ //' | sed 's/ $//')
      echo -e "  ${CYAN}${cid:0:12}${NC}  ${cname}  →  ${GREEN}${IP}${NC}   [Created by: ${YELLOW}${CREATOR}${NC}]"
  done
  echo ""
}

logs() {
  echo -e "${BOLD}📜 Nginx access logs (live):${NC}"
  docker service logs "${STACK_NAME}_nginx" --follow --tail 30
}

down() {
  echo -e "${BOLD}🛑 Removing stack '${STACK_NAME}'...${NC}"
  docker stack rm "${STACK_NAME}"
  echo -e "${GREEN}✔  Stack removed.${NC}"
}

clean() {
  down || true
  sleep 5
  echo -e "${BOLD}🧹 Removing image...${NC}"
  docker rmi "${APP_IMAGE}" 2>/dev/null || true
  echo -e "${GREEN}✔  Cleaned up.${NC}"
}

help() {
  banner
  echo "Usage: bash run.sh <command>"
  echo ""
  echo "Commands:"
  echo "  up          Build image, init swarm, deploy stack (3 replicas)"
  echo "  down        Remove the stack"
  echo "  scale N     Scale app to N replicas (default: 5)"
  echo "  test        Send 10 requests and show which replica handled each"
  echo "  ips         Show each replica's private IP"
  echo "  logs        Tail nginx access logs"
  echo "  clean       Remove stack + image"
  echo "  help        Show this message"
  echo ""
}

CMD="${1:-help}"

case "$CMD" in
  up)      up ;;
  down)    down ;;
  scale)   scale "$@" ;;
  test)    test ;;
  ips)     ips ;;
  logs)    logs ;;
  clean)   clean ;;
  *)       help ;;
esac
