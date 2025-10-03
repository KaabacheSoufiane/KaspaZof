#!/bin/bash

# Script de gestion du wallet Kaspa officiel
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Gestionnaire Wallet Kaspa KaspaZof"
echo "===================================="

# Fonctions utilitaires
show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    build       - Builder l'image Docker Kaspa
    start       - Démarrer les services Kaspa
    stop        - Arrêter les services Kaspa
    restart     - Redémarrer les services Kaspa
    logs        - Afficher les logs
    status      - Afficher le statut des services
    wallet      - Commandes wallet
    node        - Commandes nœud
    miner       - Commandes miner
    clean       - Nettoyer les volumes (⚠️ DESTRUCTIF)

WALLET COMMANDS:
    wallet create <name>     - Créer un nouveau wallet
    wallet list             - Lister les wallets
    wallet balance <name>   - Afficher le solde
    wallet send <from> <to> <amount> - Envoyer des KAS

NODE COMMANDS:
    node info               - Informations du nœud
    node peers              - Liste des peers
    node sync               - Statut de synchronisation

MINER COMMANDS:
    miner start <address>   - Démarrer le mining
    miner stop              - Arrêter le mining
    miner status            - Statut du mining

OPTIONS:
    -h, --help              - Afficher cette aide
    -v, --verbose           - Mode verbeux

EXAMPLES:
    $0 build                - Builder l'image
    $0 start                - Démarrer tous les services
    $0 wallet create mywallet - Créer un wallet
    $0 node info            - Info du nœud
    $0 miner start kaspa:qz... - Démarrer mining
EOF
}

# Vérifier les prérequis
check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker non installé"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose non disponible"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        echo "❌ Fichier .env manquant"
        echo "💡 Exécutez: ./scripts/generate_dev_secrets.sh"
        exit 1
    fi
}

# Builder l'image Docker
build_kaspa() {
    echo "🏗️  Building Kaspa Docker image..."
    cd "$PROJECT_DIR"
    docker build -t kaspazof/kaspa-wallet:latest ./kaspa-wallet/
    echo "✅ Image Kaspa buildée"
}

# Démarrer les services
start_services() {
    echo "🚀 Démarrage des services Kaspa..."
    cd "$PROJECT_DIR"
    
    # Démarrer sans le miner par défaut
    docker compose -f docker-compose-kaspa-complete.yml up -d kaspa-node kaspa-wallet postgres redis minio api frontend prometheus grafana
    
    echo "✅ Services démarrés"
    echo ""
    echo "📋 Services disponibles:"
    echo "   🔗 Nœud Kaspa:     localhost:16210 (RPC)"
    echo "   💰 Wallet:         Conteneur kaspa-wallet"
    echo "   🔧 API:            http://localhost:8000"
    echo "   🌐 Frontend:       http://localhost:8081"
    echo "   📊 Grafana:        http://localhost:3000"
}

# Démarrer avec mining
start_with_mining() {
    local mining_address=$1
    
    if [ -z "$mining_address" ]; then
        echo "❌ Adresse de mining requise"
        echo "Usage: $0 start-mining <kaspa_address>"
        exit 1
    fi
    
    echo "⛏️  Démarrage avec mining vers: $mining_address"
    cd "$PROJECT_DIR"
    
    export MINING_ADDRESS="$mining_address"
    docker compose -f docker-compose-kaspa-complete.yml --profile mining up -d
    
    echo "✅ Services avec mining démarrés"
}

# Arrêter les services
stop_services() {
    echo "🛑 Arrêt des services Kaspa..."
    cd "$PROJECT_DIR"
    docker compose -f docker-compose-kaspa-complete.yml down
    echo "✅ Services arrêtés"
}

# Redémarrer les services
restart_services() {
    stop_services
    sleep 2
    start_services
}

# Afficher les logs
show_logs() {
    local service=${1:-}
    cd "$PROJECT_DIR"
    
    if [ -n "$service" ]; then
        docker compose -f docker-compose-kaspa-complete.yml logs -f "$service"
    else
        docker compose -f docker-compose-kaspa-complete.yml logs -f
    fi
}

# Afficher le statut
show_status() {
    echo "📊 Statut des services Kaspa:"
    cd "$PROJECT_DIR"
    docker compose -f docker-compose-kaspa-complete.yml ps
    
    echo ""
    echo "🔗 Test de connectivité:"
    
    # Test nœud Kaspa
    if docker exec kaspazof-kaspa-node kaspactl get-info &>/dev/null; then
        echo "   ✅ Nœud Kaspa: Opérationnel"
    else
        echo "   ❌ Nœud Kaspa: Non disponible"
    fi
    
    # Test API
    if curl -f http://localhost:8000/health &>/dev/null; then
        echo "   ✅ API Backend: Opérationnelle"
    else
        echo "   ❌ API Backend: Non disponible"
    fi
    
    # Test Frontend
    if curl -f http://localhost:8081 &>/dev/null; then
        echo "   ✅ Frontend: Accessible"
    else
        echo "   ❌ Frontend: Non accessible"
    fi
}

# Commandes wallet
wallet_commands() {
    local cmd=$1
    shift
    
    case $cmd in
        "create")
            local wallet_name=$1
            if [ -z "$wallet_name" ]; then
                echo "❌ Nom du wallet requis"
                echo "Usage: $0 wallet create <name>"
                exit 1
            fi
            
            echo "💰 Création du wallet: $wallet_name"
            docker exec -it kaspazof-kaspa-wallet kaspawallet create-wallet --wallet-name="$wallet_name"
            ;;
        "list")
            echo "📋 Liste des wallets:"
            docker exec kaspazof-kaspa-wallet kaspawallet list-wallets
            ;;
        "balance")
            local wallet_name=$1
            if [ -z "$wallet_name" ]; then
                echo "❌ Nom du wallet requis"
                exit 1
            fi
            
            echo "💰 Solde du wallet $wallet_name:"
            docker exec kaspazof-kaspa-wallet kaspawallet balance --wallet-name="$wallet_name"
            ;;
        "send")
            local from_wallet=$1
            local to_address=$2
            local amount=$3
            
            if [ -z "$from_wallet" ] || [ -z "$to_address" ] || [ -z "$amount" ]; then
                echo "❌ Paramètres manquants"
                echo "Usage: $0 wallet send <from_wallet> <to_address> <amount>"
                exit 1
            fi
            
            echo "💸 Envoi de $amount KAS de $from_wallet vers $to_address"
            docker exec -it kaspazof-kaspa-wallet kaspawallet send \
                --wallet-name="$from_wallet" \
                --to-address="$to_address" \
                --amount="$amount"
            ;;
        *)
            echo "❌ Commande wallet inconnue: $cmd"
            echo "Commandes disponibles: create, list, balance, send"
            exit 1
            ;;
    esac
}

# Commandes nœud
node_commands() {
    local cmd=$1
    
    case $cmd in
        "info")
            echo "🔗 Informations du nœud Kaspa:"
            docker exec kaspazof-kaspa-node kaspactl get-info
            ;;
        "peers")
            echo "👥 Peers connectés:"
            docker exec kaspazof-kaspa-node kaspactl get-peer-info
            ;;
        "sync")
            echo "🔄 Statut de synchronisation:"
            docker exec kaspazof-kaspa-node kaspactl get-sync-status
            ;;
        *)
            echo "❌ Commande nœud inconnue: $cmd"
            echo "Commandes disponibles: info, peers, sync"
            exit 1
            ;;
    esac
}

# Commandes miner
miner_commands() {
    local cmd=$1
    shift
    
    case $cmd in
        "start")
            local mining_address=$1
            if [ -z "$mining_address" ]; then
                echo "❌ Adresse de mining requise"
                echo "Usage: $0 miner start <kaspa_address>"
                exit 1
            fi
            
            start_with_mining "$mining_address"
            ;;
        "stop")
            echo "🛑 Arrêt du mining..."
            docker compose -f docker-compose-kaspa-complete.yml stop kaspa-miner
            ;;
        "status")
            echo "⛏️  Statut du mining:"
            if docker ps | grep kaspazof-kaspa-miner &>/dev/null; then
                echo "   ✅ Miner: Actif"
                docker logs --tail 10 kaspazof-kaspa-miner
            else
                echo "   ❌ Miner: Inactif"
            fi
            ;;
        *)
            echo "❌ Commande miner inconnue: $cmd"
            echo "Commandes disponibles: start, stop, status"
            exit 1
            ;;
    esac
}

# Nettoyer les volumes
clean_volumes() {
    echo "⚠️  ATTENTION: Cette opération supprimera TOUTES les données Kaspa!"
    echo "   - Blockchain synchronisée"
    echo "   - Wallets créés"
    echo "   - Configuration"
    echo ""
    read -p "Êtes-vous sûr? (tapez 'yes' pour confirmer): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "🧹 Nettoyage des volumes..."
        cd "$PROJECT_DIR"
        docker compose -f docker-compose-kaspa-complete.yml down -v
        docker volume prune -f
        echo "✅ Volumes nettoyés"
    else
        echo "❌ Opération annulée"
    fi
}

# Main
main() {
    check_requirements
    
    case "${1:-}" in
        "build")
            build_kaspa
            ;;
        "start")
            start_services
            ;;
        "start-mining")
            start_with_mining "$2"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "logs")
            show_logs "$2"
            ;;
        "status")
            show_status
            ;;
        "wallet")
            shift
            wallet_commands "$@"
            ;;
        "node")
            shift
            node_commands "$@"
            ;;
        "miner")
            shift
            miner_commands "$@"
            ;;
        "clean")
            clean_volumes
            ;;
        "-h"|"--help"|"help"|"")
            show_help
            ;;
        *)
            echo "❌ Commande inconnue: $1"
            echo "Utilisez '$0 --help' pour voir les commandes disponibles"
            exit 1
            ;;
    esac
}

main "$@"