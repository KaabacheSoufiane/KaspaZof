#!/bin/bash
set -e

# Script de démarrage unifié Kaspa
# Support Solo Mining et Pool Mining

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 KaspaZof - Démarrage Unifié"
echo "=============================="

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

show_usage() {
    echo "Usage: $0 [OPTIONS] [MINING_ADDRESS]"
    echo ""
    echo "Options:"
    echo "  --solo              Minage solo (nécessite un nœud local)"
    echo "  --pool POOL_URL     Minage en pool"
    echo "  --wallet-only       Démarrer seulement le wallet (pas de minage)"
    echo "  --node-only         Démarrer seulement le nœud"
    echo "  --threads N         Nombre de threads de minage"
    echo "  --worker NAME       Nom du worker pour le pool"
    echo "  --help              Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 --solo kaspa:votre_adresse"
    echo "  $0 --pool stratum+tcp://pool.woolypooly.com:3112 kaspa:votre_adresse"
    echo "  $0 --wallet-only"
    echo ""
    echo "Pools recommandés:"
    echo "  - WoolyPooly: stratum+tcp://pool.woolypooly.com:3112"
    echo "  - 2Miners: stratum+tcp://kas.2miners.com:2020"
    echo "  - HeroMiners: stratum+tcp://kaspa.herominers.com:1206"
}

# Analyser les arguments
MINING_MODE=""
POOL_URL=""
MINING_ADDRESS=""
MINING_THREADS="auto"
MINING_WORKER="kaspazof-$(hostname 2>/dev/null || echo 'unknown')"
SERVICES_TO_START=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --solo)
            MINING_MODE="solo"
            shift
            ;;
        --pool)
            MINING_MODE="pool"
            POOL_URL="$2"
            shift 2
            ;;
        --wallet-only)
            SERVICES_TO_START="wallet-only"
            shift
            ;;
        --node-only)
            SERVICES_TO_START="node-only"
            shift
            ;;
        --threads)
            MINING_THREADS="$2"
            shift 2
            ;;
        --worker)
            MINING_WORKER="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        kaspa:*)
            MINING_ADDRESS="$1"
            shift
            ;;
        *)
            echo "❌ Option inconnue: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Vérifications
if [ -z "$SERVICES_TO_START" ] && [ -z "$MINING_ADDRESS" ]; then
    echo "❌ Adresse de minage requise"
    show_usage
    exit 1
fi

if [ "$MINING_MODE" = "pool" ] && [ -z "$POOL_URL" ]; then
    echo "❌ URL du pool requise avec --pool"
    show_usage
    exit 1
fi

# Valider l'adresse Kaspa
if [ -n "$MINING_ADDRESS" ] && [[ ! "$MINING_ADDRESS" =~ ^kaspa:[a-z0-9]{61}$ ]]; then
    echo "⚠️  Format d'adresse Kaspa non standard: $MINING_ADDRESS"
    read -p "Continuer quand même? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Configuration des variables d'environnement
export MINING_ADDRESS="$MINING_ADDRESS"
export MINING_THREADS="$MINING_THREADS"
export MINING_WORKER="$MINING_WORKER"

if [ "$MINING_MODE" = "pool" ]; then
    export MINING_POOL="$POOL_URL"
    export MINING_ENABLED="true"
elif [ "$MINING_MODE" = "solo" ]; then
    unset MINING_POOL
    export MINING_ENABLED="true"
fi

# Afficher la configuration
echo "📋 Configuration:"
if [ -n "$MINING_ADDRESS" ]; then
    echo "   Adresse: $MINING_ADDRESS"
fi
if [ -n "$MINING_MODE" ]; then
    echo "   Mode: $MINING_MODE"
fi
if [ -n "$POOL_URL" ]; then
    echo "   Pool: $POOL_URL"
fi
echo "   Threads: $MINING_THREADS"
echo "   Worker: $MINING_WORKER"

# Arrêter les services existants
echo ""
echo "🛑 Arrêt des services existants..."
$DOCKER_COMPOSE -f docker-compose-mining.yml down

# Construire les images si nécessaire
echo "🔨 Vérification des images Docker..."
$DOCKER_COMPOSE -f docker-compose-mining.yml build --pull

# Démarrer les services selon la configuration
echo ""
case "$SERVICES_TO_START" in
    "wallet-only")
        echo "💰 Démarrage du wallet uniquement..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d postgres redis kaspa-wallet
        ;;
    "node-only")
        echo "🔗 Démarrage du nœud uniquement..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d postgres redis kaspa-node
        ;;
    *)
        echo "🚀 Démarrage complet..."
        
        # Services de base
        echo "   Démarrage des services de base..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d postgres redis
        
        # Attendre PostgreSQL
        echo "   Attente de PostgreSQL..."
        sleep 10
        
        # Nœud Kaspa (toujours nécessaire)
        echo "   Démarrage du nœud Kaspa..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-node
        
        # Attendre la synchronisation
        echo "   Attente de la synchronisation du nœud..."
        sleep 30
        
        # Wallet
        echo "   Démarrage du wallet..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-wallet
        
        # Monitoring
        echo "   Démarrage du monitoring..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d prometheus grafana mining-monitor
        
        # API et Frontend
        echo "   Démarrage de l'interface web..."
        $DOCKER_COMPOSE -f docker-compose-mining.yml up -d api frontend
        
        # Mineur (si configuré)
        if [ "$MINING_ENABLED" = "true" ]; then
            echo "   Démarrage du mineur..."
            $DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-miner-1
        fi
        ;;
esac

echo ""
echo "✅ Démarrage terminé!"
echo ""
echo "🌐 Interfaces disponibles:"
echo "   Frontend:    http://localhost:8081"
echo "   API:         http://localhost:8000"
echo "   Grafana:     http://localhost:3000"
echo "   Prometheus:  http://localhost:9090"
echo "   Monitoring:  http://localhost:8080"
echo ""
echo "📊 Commandes utiles:"
echo "   Statut:      ./scripts/mining-manager.sh status"
echo "   Logs:        $DOCKER_COMPOSE -f docker-compose-mining.yml logs -f"
echo "   Arrêter:     $DOCKER_COMPOSE -f docker-compose-mining.yml down"
echo ""

if [ "$MINING_MODE" = "pool" ]; then
    echo "🏊 Minage en pool configuré:"
    echo "   Vérifiez le dashboard du pool avec votre adresse"
    echo "   URL du pool: $POOL_URL"
elif [ "$MINING_MODE" = "solo" ]; then
    echo "⛏️  Minage solo configuré:"
    echo "   Le nœud doit être complètement synchronisé"
    echo "   Surveillez les logs pour voir la progression"
fi

echo ""
echo "📚 Documentation:"
echo "   Guide de minage: ./MINING_GUIDE.md"
echo "   Guide de sécurité: ./KASPA_SECURITY_GUIDE.md"