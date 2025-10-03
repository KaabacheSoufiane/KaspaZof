```markdown
# Construction Web3 — Mining / Kaspa Server (dev only)

Objectif
---------
Repository indépendant pour déployer un nœud Kaspa (kaspad) et un miner local pour tests & apprentissage.

Important
---------
- Pour tests LOCAUX UNIQUEMENT. NE PAS EXPOSER LE RPC SUR INTERNET.
- Ce repo doit être séparé du coeur de l'application. Ne commitez pas les secrets (.env).

Prérequis
---------
- Docker & Docker Compose (v2)
- Au moins 20 GB disque (plus pour full node)
- CPU 4+ cores, 8+ GB RAM

Quick start (local test)
-----------------------
1. Clone:
   git clone https://github.com/your-org/construction-web3-mining.git
   cd construction-web3-mining

2. Copy sample env:
   cp .env.example .env
   # Edit .env with your wallet address and choices (pool or solo).

3. Start stack:
   docker compose -f docker-compose-kaspa-mining.yml up -d --build

4. Check health:
   docker ps
   docker logs kaspa-node --tail 200
   curl http://localhost:9090  # prometheus (if enabled)

Notes on Solo vs Pool
---------------------
- SOLO: kaspad must be fully synced. Low probability of blocks unless high hashpower.
- POOL: configure miner container to connect to pool and set MINER_WALLET to your wallet.

Security
--------
- Keep RPC bound to 127.0.0.1 (docker-compose uses 127.0.0.1 mapping).
- Store wallet seed offline. Only place receiving address in .env.
- For long-term use, migrate secrets to Vault and protect volumes.

Monitoring
----------
- Prometheus is included as an optional service. Add exporters for kaspa/miner as needed.

Next steps
----------
- Replace miner placeholder with an actual miner image / binary and configure stratum/connection.
- Add healthchecks and alerts for disk usage and sync state.
- If you want to attempt a local full node for production-grade mining, ensure host hardware and storage satisfy kaspa requirements or prefer pool mining.

```