#!/bin/bash
set -e

# Script de démarrage du minage GPU Kaspa selon la documentation officielle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎮 KaspaZof - Démarrage Minage GPU"
echo "=================================="

# Définir Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

cd "$PROJECT_DIR"

# Vérifier .env
if [ ! -f ".env" ]; then
    echo "📝 Génération du fichier .env..."
    ./scripts/generate_dev_secrets.sh
fi

source .env

# Vérifier l'adresse de minage
MINING_ADDRESS=${1:-$MINING_ADDRESS}
if [ -z "$MINING_ADDRESS" ]; then
    echo "❌ Adresse de minage requise"
    echo "Usage: $0 <MINING_ADDRESS> [MINING_MODE] [POOL_URL]"
    exit 1
fi

MINING_MODE=${2:-"pool"}
POOL_URL=${3:-"stratum+tcp://pool.woolypooly.com:3112"}

echo "📋 Configuration GPU Mining:"
echo "   Adresse: $MINING_ADDRESS"
echo "   Mode: $MINING_MODE"
if [ "$MINING_MODE" = "pool" ]; then
    echo "   Pool: $POOL_URL"
fi

# Exporter les variables
export MINING_ADDRESS="$MINING_ADDRESS"
export MINING_MODE="$MINING_MODE"
export POOL_URL="$POOL_URL"

# Extraire host et port du pool
if [[ "$POOL_URL" == stratum+tcp://* ]]; then
    POOL_HOST=$(echo "$POOL_URL" | sed 's|stratum+tcp://||' | cut -d: -f1)
    POOL_PORT=$(echo "$POOL_URL" | sed 's|stratum+tcp://||' | cut -d: -f2)
else
    POOL_HOST=$(echo "$POOL_URL" | cut -d: -f1)
    POOL_PORT=$(echo "$POOL_URL" | cut -d: -f2)
fi

export POOL_HOST="$POOL_HOST"
export POOL_PORT="$POOL_PORT"

# Vérifier NVIDIA Docker support
if command -v nvidia-docker &> /dev/null || docker info | grep -q nvidia; then
    echo "✅ Support GPU NVIDIA détecté"
    GPU_SUPPORT=true
else
    echo "⚠️  Support GPU NVIDIA non détecté, utilisation CPU"
    GPU_SUPPORT=false
fi

# Arrêter les services existants
echo "🛑 Arrêt des services existants..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml down

# Construire les images
echo "🔨 Construction des images..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml build

# Démarrer les services de base
echo "🚀 Démarrage des services de base..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d postgres redis

sleep 10

# Démarrer le nœud Kaspa
echo "🔗 Démarrage du nœud Kaspa..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d kaspa-node

sleep 30

# Démarrer le monitoring
echo "📊 Démarrage du monitoring..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d mining-monitor prometheus grafana

# Démarrer l'API et frontend
echo "🌐 Démarrage de l'interface..."
$DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d api frontend

# Choisir le mineur selon le mode
if [ "$MINING_MODE" = "solo" ]; then
    echo "⛏️  Démarrage Solo Mining..."
    echo "   1. Démarrage Stratum Bridge..."
    $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml --profile solo-mining up -d stratum-bridge
    
    sleep 10
    
    echo "   2. Démarrage Community Miner (Solo)..."
    export MINING_MODE="solo"
    $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d community-miner
    
else
    echo "🏊 Démarrage Pool Mining..."
    
    if [ "$GPU_SUPPORT" = true ]; then
        echo "   Choix du mineur GPU:"
        echo "   1. Community Miner (CPU/GPU optimisé)"
        echo "   2. BzMiner (GPU haute performance)"
        echo "   3. lolMiner (Pool optimisé)"
        
        read -p "Choisir le mineur (1-3, défaut: 1): " MINER_CHOICE
        MINER_CHOICE=${MINER_CHOICE:-1}
        
        case $MINER_CHOICE in
            1)
                echo "   Démarrage Community Miner..."
                $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d community-miner
                ;;
            2)
                echo "   Démarrage BzMiner..."
                $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml --profile gpu-mining up -d bzminer
                ;;
            3)
                echo "   Démarrage lolMiner..."
                $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml --profile gpu-mining up -d lolminer
                ;;
            *)
                echo "   Démarrage Community Miner (défaut)..."
                $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d community-miner
                ;;
        esac
    else
        echo "   Démarrage Community Miner (CPU)..."
        $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml up -d community-miner
    fi
fi

echo ""
echo "✅ Minage GPU Kaspa démarré!"
echo ""
echo "🌐 Interfaces:"
echo "   Frontend:    http://localhost:8081"
echo "   API:         http://localhost:8000"
echo "   Monitoring:  http://localhost:8080"
echo "   Grafana:     http://localhost:3000"
echo ""
echo "📊 Surveillance:"
echo "   Logs mineur: $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml logs -f [community-miner|bzminer|lolminer]"
echo "   Stats:       curl http://localhost:8080/stats"
echo ""
echo "🛑 Arrêter:"
echo "   $DOCKER_COMPOSE -f docker-compose-gpu-mining.yml down"
echo ""
if [ "$MINING_MODE" = "pool" ]; then
    echo "🏊 Pool Mining configuré:"
    echo "   Pool: $POOL_URL"
    echo "   Vérifiez le dashboard du pool avec votre adresse"
else
    echo "⛏️  Solo Mining configuré:"
    echo "   Bridge Stratum: localhost:5555"
    echo "   Le nœud doit être synchronisé pour être efficace"
fi