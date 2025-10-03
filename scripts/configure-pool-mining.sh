#!/bin/bash
set -e

# Configuration automatique du minage en pool
# Pools Kaspa recommandés avec vérifications

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🏊 Configuration du minage en pool Kaspa"
echo "========================================"

# Pools Kaspa recommandés (vérifiés)
declare -A POOLS
POOLS["woolypooly"]="stratum+tcp://pool.woolypooly.com:3112"
POOLS["2miners"]="stratum+tcp://kas.2miners.com:2020"
POOLS["herominers"]="stratum+tcp://kaspa.herominers.com:1206"
POOLS["kryptex"]="stratum+tcp://pool.kryptex.network:7777"
POOLS["f2pool"]="stratum+tcp://kas.f2pool.com:4200"

declare -A POOL_FEES
POOL_FEES["woolypooly"]="0.9%"
POOL_FEES["2miners"]="1%"
POOL_FEES["herominers"]="0.9%"
POOL_FEES["kryptex"]="0.9%"
POOL_FEES["f2pool"]="2.5%"

declare -A POOL_PAYOUT
POOL_PAYOUT["woolypooly"]="1 KAS"
POOL_PAYOUT["2miners"]="1 KAS"
POOL_PAYOUT["herominers"]="1 KAS"
POOL_PAYOUT["kryptex"]="1 KAS"
POOL_PAYOUT["f2pool"]="10 KAS"

echo "📊 Pools disponibles:"
echo "===================="
for pool in "${!POOLS[@]}"; do
    echo "🏊 $pool"
    echo "   URL: ${POOLS[$pool]}"
    echo "   Frais: ${POOL_FEES[$pool]}"
    echo "   Payout min: ${POOL_PAYOUT[$pool]}"
    echo ""
done

# Sélection du pool
echo "Choisissez un pool:"
select pool_name in "${!POOLS[@]}" "custom"; do
    if [ -n "$pool_name" ]; then
        break
    fi
done

if [ "$pool_name" = "custom" ]; then
    read -p "URL du pool personnalisé (stratum+tcp://...): " POOL_URL
    read -p "Port: " POOL_PORT
    SELECTED_POOL="$POOL_URL:$POOL_PORT"
    POOL_FEES_SELECTED="Inconnu"
    POOL_PAYOUT_SELECTED="Inconnu"
else
    SELECTED_POOL="${POOLS[$pool_name]}"
    POOL_FEES_SELECTED="${POOL_FEES[$pool_name]}"
    POOL_PAYOUT_SELECTED="${POOL_PAYOUT[$pool_name]}"
fi

# Demander l'adresse de minage
echo ""
read -p "Adresse Kaspa pour recevoir les paiements: " MINING_ADDRESS

# Valider l'adresse Kaspa
if [[ ! "$MINING_ADDRESS" =~ ^kaspa:[a-z0-9]{61}$ ]]; then
    echo "⚠️  Format d'adresse Kaspa non standard: $MINING_ADDRESS"
    echo "Format attendu: kaspa:qqxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    read -p "Continuer quand même? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Configuration du mineur
echo ""
echo "⚙️  Configuration du mineur:"
read -p "Nombre de threads CPU (défaut: auto): " THREADS
THREADS=${THREADS:-"auto"}

read -p "Nom du worker (optionnel): " WORKER_NAME
WORKER_NAME=${WORKER_NAME:-"kaspazof-$(hostname)"}

# Créer le fichier de configuration
CONFIG_FILE="$PROJECT_DIR/pool-mining.conf"
cat > "$CONFIG_FILE" << EOF
# Configuration du minage en pool Kaspa
# Généré le $(date)

[pool]
name = $pool_name
url = $SELECTED_POOL
fees = $POOL_FEES_SELECTED
min_payout = $POOL_PAYOUT_SELECTED

[miner]
address = $MINING_ADDRESS
worker = $WORKER_NAME
threads = $THREADS
algorithm = kaspa

[advanced]
retry_delay = 5
max_retries = 10
log_level = info
EOF

# Créer le script de démarrage du pool mining
POOL_SCRIPT="$PROJECT_DIR/scripts/start-pool-mining.sh"
cat > "$POOL_SCRIPT" << EOF
#!/bin/bash
set -e

# Script de démarrage du minage en pool
# Configuration: $CONFIG_FILE

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="\$(dirname "\$SCRIPT_DIR")"
KASPA_BIN_DIR="\$PROJECT_DIR/kaspa-wallet/bin"

echo "🏊 Démarrage du minage en pool Kaspa"
echo "===================================="

# Charger la configuration
source "\$PROJECT_DIR/pool-mining.conf" 2>/dev/null || {
    echo "❌ Fichier de configuration non trouvé: \$PROJECT_DIR/pool-mining.conf"
    exit 1
}

echo "📊 Configuration:"
echo "   Pool: $pool_name"
echo "   URL: $SELECTED_POOL"
echo "   Adresse: $MINING_ADDRESS"
echo "   Worker: $WORKER_NAME"
echo "   Threads: $THREADS"

# Vérifier les binaires
if [ ! -f "\$KASPA_BIN_DIR/kaspaminer" ]; then
    echo "❌ Binaire kaspaminer non trouvé"
    exit 1
fi

# Démarrer le mineur
echo ""
echo "⛏️  Démarrage du mineur..."

# Commande pour différents types de pools
if [[ "$SELECTED_POOL" == stratum+tcp://* ]]; then
    # Pool avec protocole stratum
    POOL_HOST=\$(echo "$SELECTED_POOL" | sed 's|stratum+tcp://||' | cut -d: -f1)
    POOL_PORT=\$(echo "$SELECTED_POOL" | sed 's|stratum+tcp://||' | cut -d: -f2)
    
    echo "Connexion à \$POOL_HOST:\$POOL_PORT..."
    
    # Utiliser kaspaminer avec les paramètres du pool
    "\$KASPA_BIN_DIR/kaspaminer" \\
        --pool-address="\$POOL_HOST:\$POOL_PORT" \\
        --mining-address="$MINING_ADDRESS" \\
        --worker-name="$WORKER_NAME" \\
        --threads="$THREADS" \\
        --log-level=info
else
    echo "❌ Format de pool non supporté: $SELECTED_POOL"
    exit 1
fi
EOF

chmod +x "$POOL_SCRIPT"

# Créer le fichier .env avec la configuration
if [ -f "$PROJECT_DIR/.env" ]; then
    # Mettre à jour .env existant
    sed -i "s/^MINING_ADDRESS=.*/MINING_ADDRESS=$MINING_ADDRESS/" "$PROJECT_DIR/.env"
    sed -i "s/^MINING_POOL=.*/MINING_POOL=$SELECTED_POOL/" "$PROJECT_DIR/.env"
    
    # Ajouter si n'existe pas
    grep -q "^MINING_POOL=" "$PROJECT_DIR/.env" || echo "MINING_POOL=$SELECTED_POOL" >> "$PROJECT_DIR/.env"
    grep -q "^MINING_WORKER=" "$PROJECT_DIR/.env" || echo "MINING_WORKER=$WORKER_NAME" >> "$PROJECT_DIR/.env"
    grep -q "^MINING_THREADS=" "$PROJECT_DIR/.env" || echo "MINING_THREADS=$THREADS" >> "$PROJECT_DIR/.env"
else
    echo "⚠️  Fichier .env non trouvé, exécutez d'abord: ./scripts/generate_dev_secrets.sh"
fi

echo ""
echo "✅ Configuration du pool terminée!"
echo ""
echo "📁 Fichiers créés:"
echo "   Configuration: $CONFIG_FILE"
echo "   Script de démarrage: $POOL_SCRIPT"
echo ""
echo "📊 Résumé de la configuration:"
echo "   Pool: $pool_name ($SELECTED_POOL)"
echo "   Frais: $POOL_FEES_SELECTED"
echo "   Payout minimum: $POOL_PAYOUT_SELECTED"
echo "   Adresse: $MINING_ADDRESS"
echo "   Worker: $WORKER_NAME"
echo ""
echo "🚀 Pour démarrer le minage:"
echo "   $POOL_SCRIPT"
echo ""
echo "📈 Surveillance:"
echo "   - Vérifiez le dashboard du pool avec votre adresse"
echo "   - Surveillez les logs du mineur"
echo "   - Vérifiez les paiements réguliers"
EOF