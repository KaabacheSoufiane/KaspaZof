#!/bin/bash
set -e

# Script d'entrée pour le conteneur Kaspa Wallet
echo "🚀 Démarrage du conteneur Kaspa Wallet v0.12.22"

# Variables d'environnement par défaut
KASPA_NETWORK=${KASPA_NETWORK:-mainnet}
KASPA_RPC_USER=${KASPA_RPC_USER:-kaspa}
KASPA_RPC_PASS=${KASPA_RPC_PASS:-$(openssl rand -base64 32)}
KASPA_LOG_LEVEL=${KASPA_LOG_LEVEL:-info}

# Créer les dossiers nécessaires
mkdir -p "${KASPA_DATA_DIR}" "${KASPA_CONFIG_DIR}" /kaspa/logs

# Fonction pour générer la configuration kaspad
generate_kaspad_config() {
    cat > "${KASPA_CONFIG_DIR}/kaspad.conf" << EOF
# Configuration Kaspa Node
network=${KASPA_NETWORK}
datadir=${KASPA_DATA_DIR}
logdir=/kaspa/logs

# RPC Configuration
rpcuser=${KASPA_RPC_USER}
rpcpass=${KASPA_RPC_PASS}
rpclisten=0.0.0.0:16210
rpcbind=0.0.0.0:16210

# P2P Configuration
listen=0.0.0.0:16211

# Logging
loglevel=${KASPA_LOG_LEVEL}

# Performance
dbtype=leveldb
EOF
    echo "✅ Configuration kaspad générée"
}

# Fonction pour générer la configuration wallet
generate_wallet_config() {
    cat > "${KASPA_CONFIG_DIR}/wallet.conf" << EOF
# Configuration Kaspa Wallet
network=${KASPA_NETWORK}
rpcserver=localhost:16210
rpcuser=${KASPA_RPC_USER}
rpcpass=${KASPA_RPC_PASS}

# Wallet settings
walletdir=${KASPA_DATA_DIR}/wallets
logdir=/kaspa/logs

# Security
timeout=300
EOF
    echo "✅ Configuration wallet générée"
}

# Fonction pour démarrer kaspad (nœud)
start_kaspad() {
    echo "🔗 Démarrage du nœud Kaspa (kaspad)..."
    
    generate_kaspad_config
    
    exec kaspad \
        --configfile="${KASPA_CONFIG_DIR}/kaspad.conf" \
        --datadir="${KASPA_DATA_DIR}" \
        --logdir=/kaspa/logs \
        --network="${KASPA_NETWORK}" \
        --rpclisten=0.0.0.0:16210 \
        --rpcbind=0.0.0.0:16210 \
        --listen=0.0.0.0:16211 \
        --loglevel="${KASPA_LOG_LEVEL}"
}

# Fonction pour démarrer le wallet
start_wallet() {
    echo "💰 Démarrage du wallet Kaspa..."
    
    generate_wallet_config
    
    # Attendre que kaspad soit disponible si nécessaire
    if [ "${WAIT_FOR_NODE}" = "true" ]; then
        echo "⏳ Attente du nœud Kaspa..."
        while ! kaspactl --rpcserver=localhost:16210 get-info >/dev/null 2>&1; do
            echo "   Nœud non disponible, nouvelle tentative dans 5s..."
            sleep 5
        done
        echo "✅ Nœud Kaspa disponible"
    fi
    
    exec kaspawallet \
        --configfile="${KASPA_CONFIG_DIR}/wallet.conf" \
        --rpcserver="${KASPA_RPC_SERVER:-localhost:16210}" \
        --rpcuser="${KASPA_RPC_USER}" \
        --rpcpass="${KASPA_RPC_PASS}" \
        --walletdir="${KASPA_DATA_DIR}/wallets" \
        --logdir=/kaspa/logs \
        --network="${KASPA_NETWORK}"
}

# Fonction pour démarrer le miner
start_miner() {
    echo "⛏️  Démarrage du miner Kaspa..."
    
    if [ -z "${MINING_ADDRESS}" ]; then
        echo "❌ MINING_ADDRESS requis pour le mining"
        exit 1
    fi
    
    exec kaspaminer \
        --rpcserver="${KASPA_RPC_SERVER:-localhost:16210}" \
        --rpcuser="${KASPA_RPC_USER}" \
        --rpcpass="${KASPA_RPC_PASS}" \
        --miningaddr="${MINING_ADDRESS}" \
        --numblocks="${NUM_BLOCKS:-0}" \
        --logdir=/kaspa/logs
}

# Fonction pour les outils (kaspactl, genkeypair)
run_tool() {
    local tool=$1
    shift
    
    case $tool in
        "kaspactl")
            exec kaspactl \
                --rpcserver="${KASPA_RPC_SERVER:-localhost:16210}" \
                --rpcuser="${KASPA_RPC_USER}" \
                --rpcpass="${KASPA_RPC_PASS}" \
                "$@"
            ;;
        "genkeypair")
            exec genkeypair "$@"
            ;;
        *)
            echo "❌ Outil non reconnu: $tool"
            echo "Outils disponibles: kaspactl, genkeypair"
            exit 1
            ;;
    esac
}

# Afficher les informations de démarrage
echo "📋 Configuration:"
echo "   Network: ${KASPA_NETWORK}"
echo "   Data Dir: ${KASPA_DATA_DIR}"
echo "   Config Dir: ${KASPA_CONFIG_DIR}"
echo "   RPC User: ${KASPA_RPC_USER}"
echo "   Log Level: ${KASPA_LOG_LEVEL}"

# Router selon le mode demandé
case "$1" in
    "node"|"kaspad")
        start_kaspad
        ;;
    "wallet"|"kaspawallet")
        start_wallet
        ;;
    "miner"|"kaspaminer")
        start_miner
        ;;
    "kaspactl")
        shift
        run_tool kaspactl "$@"
        ;;
    "genkeypair")
        shift
        run_tool genkeypair "$@"
        ;;
    "bash"|"sh")
        exec /bin/bash
        ;;
    *)
        echo "❌ Mode non reconnu: $1"
        echo ""
        echo "Modes disponibles:"
        echo "  node     - Démarrer le nœud Kaspa (kaspad)"
        echo "  wallet   - Démarrer le wallet Kaspa"
        echo "  miner    - Démarrer le miner Kaspa"
        echo "  kaspactl - Exécuter kaspactl avec arguments"
        echo "  genkeypair - Générer une paire de clés"
        echo "  bash     - Shell interactif"
        echo ""
        echo "Exemples:"
        echo "  docker run kaspa-wallet node"
        echo "  docker run kaspa-wallet wallet"
        echo "  docker run kaspa-wallet kaspactl get-info"
        exit 1
        ;;
esac