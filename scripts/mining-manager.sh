#!/bin/bash
set -e

# Gestionnaire de minage Kaspa
# Permet de contrôler le minage (start, stop, status, logs)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Définir la commande Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

cd "$PROJECT_DIR"

show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|stats|multi}"
    echo ""
    echo "Commandes:"
    echo "  start     - Démarrer le minage"
    echo "  stop      - Arrêter le minage"
    echo "  restart   - Redémarrer le minage"
    echo "  status    - Afficher le statut des services"
    echo "  logs      - Afficher les logs du mineur"
    echo "  stats     - Afficher les statistiques de minage"
    echo "  multi     - Démarrer le minage multi-instances"
    echo ""
    echo "Exemples:"
    echo "  $0 start"
    echo "  $0 logs kaspa-miner-1"
    echo "  $0 stats"
}

start_mining() {
    echo "🚀 Démarrage du minage..."
    $DOCKER_COMPOSE -f docker-compose-mining.yml up -d kaspa-miner-1
    echo "✅ Mineur démarré"
}

stop_mining() {
    echo "🛑 Arrêt du minage..."
    $DOCKER_COMPOSE -f docker-compose-mining.yml stop kaspa-miner-1 kaspa-miner-2
    echo "✅ Minage arrêté"
}

restart_mining() {
    echo "🔄 Redémarrage du minage..."
    stop_mining
    sleep 2
    start_mining
}

show_status() {
    echo "📊 Statut des services de minage:"
    echo "=================================="
    $DOCKER_COMPOSE -f docker-compose-mining.yml ps
    
    echo ""
    echo "🔗 Statut du nœud Kaspa:"
    if docker exec kaspazof-kaspa-node kaspactl --rpcserver=localhost:16210 get-info &>/dev/null; then
        echo "✅ Nœud Kaspa: Connecté"
        docker exec kaspazof-kaspa-node kaspactl --rpcserver=localhost:16210 get-info | grep -E "(blockCount|peerCount|difficulty)"
    else
        echo "❌ Nœud Kaspa: Déconnecté"
    fi
}

show_logs() {
    local service=${1:-kaspa-miner-1}
    echo "📋 Logs de $service:"
    $DOCKER_COMPOSE -f docker-compose-mining.yml logs -f --tail=50 "$service"
}

show_stats() {
    echo "📈 Statistiques de minage:"
    echo "=========================="
    
    if curl -s http://localhost:8080/health &>/dev/null; then
        echo "✅ Service de monitoring: Actif"
        echo ""
        curl -s http://localhost:8080/stats | jq '.' 2>/dev/null || curl -s http://localhost:8080/stats
    else
        echo "❌ Service de monitoring: Inactif"
    fi
    
    echo ""
    echo "🔗 Informations du nœud:"
    if docker exec kaspazof-kaspa-node kaspactl --rpcserver=localhost:16210 get-info &>/dev/null; then
        docker exec kaspazof-kaspa-node kaspactl --rpcserver=localhost:16210 get-info
    else
        echo "❌ Impossible de récupérer les informations du nœud"
    fi
}

start_multi_mining() {
    echo "🚀 Démarrage du minage multi-instances..."
    $DOCKER_COMPOSE -f docker-compose-mining.yml --profile multi-mining up -d
    echo "✅ Minage multi-instances démarré"
    echo "   - Mineur 1: kaspa-miner-1"
    echo "   - Mineur 2: kaspa-miner-2"
}

# Vérifier les arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    start)
        start_mining
        ;;
    stop)
        stop_mining
        ;;
    restart)
        restart_mining
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    stats)
        show_stats
        ;;
    multi)
        start_multi_mining
        ;;
    *)
        echo "❌ Commande inconnue: $1"
        show_usage
        exit 1
        ;;
esac