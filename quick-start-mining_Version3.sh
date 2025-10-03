#!/usr/bin/env bash
# Quick start script for local Kaspa mining test (dev only)
set -euo pipefail
REPO_DIR="${1:-construction-web3-mining}"
COMPOSE_FILE="docker-compose-kaspa-mining.yml"

# 1) Clone (if missing)
if [ ! -d "$REPO_DIR" ]; then
  git clone https://github.com/your-org/construction-web3-mining.git "$REPO_DIR" || true
fi
cd "$REPO_DIR"

# 2) Create .env from example
[ -f .env ] || cp .env.example .env

# 3) Build & start
docker compose -f "$COMPOSE_FILE" up -d --build

# 4) Wait for kaspa rpc health (simple loop)
echo "Waiting for kaspa rpc..."
for i in $(seq 1 20); do
  if ss -tulnp | grep -q 16210; then
    echo "kaspad RPC appears listening"
    break
  fi
  sleep 3
done

echo "Stack started. Check logs:"
echo " docker logs kaspa-node --tail 200"
echo " docker logs kaspa-miner-placeholder --tail 200"