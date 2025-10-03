#!/bin/bash
set -e

# Script de démarrage du minage Kaspa
# Usage: ./start-mining.sh [MINING_ADDRESS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 KaspaZof - Démarrage du minage Kaspa"
echo "========================================"

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

# Définir la commande Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

cd "$PROJECT_DIR"

# Vérifier le fichier .env
if [ ! -f ".env" ]; then
    echo "📝 Génération du fichier .env..."
    ./scripts/generate_dev_secrets.sh
fi

# Charger les variables d'environnement
source .env

# Vérifier l'adresse de minage
MINING_ADDRESS=${1:-$MINING_ADDRESS}
if [ -z "$MINING_ADDRESS" ]; then
    echo "❌ Adresse de minage requise"
    echo "Usage: $0 <MINING_ADDRESS>"
    echo "Ou définir MINING_ADDRESS dans .env"
    exit 1
fi

# Valider l'adresse Kaspa
if [[ ! "$MINING_ADDRESS" =~ ^kaspa:[a-z0-9]{61}$ ]]; then
    echo "⚠️  Format d'adresse Kaspa invalide: $MINING_ADDRESS"
    echo "Format attendu: kaspa:qqxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    read -p "Continuer quand même? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 Configuration du minage:"
echo "   Adresse: $MINING_ADDRESS"
echo "   Réseau: mainnet"
echo "   Mineurs: 1 (principal)"

# Exporter l'adresse de minage
export MINING_ADDRESS="$MINING_ADDRESS"

# Arrêter les services existants
echo "🛑 Arrêt des services existants..."
$DOCKER_COMPOSE -f docker-compose-mining.yml down

# Construire les images
echo "🔨 Construction des images Docker..."
$DOCKER_COMPOSE -f docker-compose-mining.yml build

# Démarrer les services de base
echo "🚀 Démarrage des services de base..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d postgres redis

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 10

# Démarrer le nœud Kaspa
echo "🔗 Démarrage du nœud Kaspa..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-node

# Attendre que le nœud soit synchronisé
echo "⏳ Attente de la synchronisation du nœud..."
sleep 30

# Démarrer le wallet
echo "💰 Démarrage du wallet Kaspa..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-wallet

# Démarrer le monitoring
echo "📊 Démarrage du monitoring..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d prometheus grafana mining-monitor

# Démarrer l'API et le frontend
echo "🌐 Démarrage de l'interface web..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d api frontend

# Démarrer le mineur principal
echo "⛏️  Démarrage du mineur Kaspa..."
$DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-miner-1

echo ""
echo "✅ Minage Kaspa démarré avec succès!"
echo ""
echo "🌐 Interfaces disponibles:"
echo "   Frontend:    http://localhost:8081"
echo "   API:         http://localhost:8000"
echo "   Grafana:     http://localhost:3000 (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo "   Monitoring:  http://localhost:8080"
echo ""
echo "📊 Commandes utiles:"
echo "   Logs du mineur:  $DOCKER_COMPOSE -f docker-compose-mining.yml logs -f kaspa-miner-1"
echo "   Logs du nœud:    $DOCKER_COMPOSE -f docker-compose-mining.yml logs -f kaspa-node"
echo "   Statistiques:    curl http://localhost:8080/stats"
echo "   Arrêter:         $DOCKER_COMPOSE -f docker-compose-mining.yml down"
echo ""
echo "⚠️  Le nœud doit se synchroniser avant que le minage soit efficace."
echo "   Surveillez les logs pour voir la progression."