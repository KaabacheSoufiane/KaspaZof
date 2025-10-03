#!/bin/bash
set -e

# Installation des mineurs GPU Kaspa optimisés

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MINERS_DIR="$PROJECT_DIR/gpu-miners"

echo "🎮 Installation des mineurs GPU Kaspa"
echo "====================================="

# Créer le dossier des mineurs
mkdir -p "$MINERS_DIR"
cd "$MINERS_DIR"

# Détecter l'architecture
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "📋 Système détecté: $OS $ARCH"

# 1. Community Miner (kaspa-miner)
echo "📥 Téléchargement Community Miner..."
COMMUNITY_VERSION="1.4.3"
if [ "$OS" = "linux" ]; then
    COMMUNITY_URL="https://github.com/tmrlvi/kaspa-miner/releases/download/v${COMMUNITY_VERSION}/kaspa-miner-v${COMMUNITY_VERSION}-linux.zip"
    wget -O community-miner.zip "$COMMUNITY_URL"
    unzip -o community-miner.zip -d community-miner/
    chmod +x community-miner/kaspa-miner*
fi

# 2. BzMiner
echo "📥 Téléchargement BzMiner..."
BZMINER_VERSION="21.3.7"
if [ "$OS" = "linux" ]; then
    BZMINER_URL="https://github.com/bzminer/bzminer/releases/download/v${BZMINER_VERSION}/bzminer_v${BZMINER_VERSION}_linux.tar.gz"
    wget -O bzminer.tar.gz "$BZMINER_URL"
    tar -xzf bzminer.tar.gz
    mv bzminer_v${BZMINER_VERSION}_linux bzminer/
    chmod +x bzminer/bzminer
fi

# 3. lolMiner
echo "📥 Téléchargement lolMiner..."
LOLMINER_VERSION="1.88"
if [ "$OS" = "linux" ]; then
    LOLMINER_URL="https://github.com/Lolliedieb/lolMiner-releases/releases/download/${LOLMINER_VERSION}/lolMiner_v${LOLMINER_VERSION}_Lin64.tar.gz"
    wget -O lolminer.tar.gz "$LOLMINER_URL"
    tar -xzf lolminer.tar.gz
    mv ${LOLMINER_VERSION} lolminer/
    chmod +x lolminer/lolMiner
fi

# 4. Kaspa-Stratum Bridge
echo "📥 Installation Kaspa-Stratum Bridge..."
BRIDGE_VERSION="1.2.0"
BRIDGE_URL="https://github.com/KaffinPX/kaspa-stratum-bridge/releases/download/v${BRIDGE_VERSION}/kaspa-stratum-bridge-v${BRIDGE_VERSION}-linux-amd64.tar.gz"
wget -O stratum-bridge.tar.gz "$BRIDGE_URL"
tar -xzf stratum-bridge.tar.gz
mv kaspa-stratum-bridge stratum-bridge/
chmod +x stratum-bridge/kaspa-stratum-bridge

# Nettoyer les archives
rm -f *.zip *.tar.gz

# Créer les scripts de lancement
cat > "$MINERS_DIR/start-community-pool.sh" << 'EOF'
#!/bin/bash
# Community Miner - Pool Mining
POOL_URL=${1:-"stratum+tcp://pool.woolypooly.com:3112"}
WALLET_ADDRESS=${2:-"kaspa:qzejdryvs6t8mzulhlaywpd8awpls7qx2t64elrmxhysjz3lpygqgf454aea8"}

echo "🎮 Démarrage Community Miner (Pool)"
echo "Pool: $POOL_URL"
echo "Wallet: $WALLET_ADDRESS"

cd community-miner/
./kaspa-miner* -a "$WALLET_ADDRESS" -s "$POOL_URL"
EOF

cat > "$MINERS_DIR/start-bzminer-pool.sh" << 'EOF'
#!/bin/bash
# BzMiner - Pool Mining
POOL_URL=${1:-"stratum+tcp://pool.woolypooly.com:3112"}
WALLET_ADDRESS=${2:-"kaspa:qzejdryvs6t8mzulhlaywpd8awpls7qx2t64elrmxhysjz3lpygqgf454aea8"}

echo "🎮 Démarrage BzMiner (Pool)"
echo "Pool: $POOL_URL"
echo "Wallet: $WALLET_ADDRESS"

cd bzminer/
./bzminer -a kaspa -w "$WALLET_ADDRESS" -p "$POOL_URL"
EOF

cat > "$MINERS_DIR/start-lolminer-pool.sh" << 'EOF'
#!/bin/bash
# lolMiner - Pool Mining
POOL_URL=${1:-"pool.woolypooly.com:3112"}
WALLET_ADDRESS=${2:-"kaspa:qzejdryvs6t8mzulhlaywpd8awpls7qx2t64elrmxhysjz3lpygqgf454aea8"}

echo "🎮 Démarrage lolMiner (Pool)"
echo "Pool: $POOL_URL"
echo "Wallet: $WALLET_ADDRESS"

cd lolminer/
./lolMiner --algo KASPA --pool "$POOL_URL" --user "$WALLET_ADDRESS"
EOF

cat > "$MINERS_DIR/start-stratum-bridge.sh" << 'EOF'
#!/bin/bash
# Kaspa-Stratum Bridge pour Solo Mining
KASPA_NODE=${1:-"localhost:16210"}
BRIDGE_PORT=${2:-"5555"}

echo "🌉 Démarrage Kaspa-Stratum Bridge"
echo "Node: $KASPA_NODE"
echo "Bridge Port: $BRIDGE_PORT"

cd stratum-bridge/
./kaspa-stratum-bridge --kaspad-address="$KASPA_NODE" --listen="0.0.0.0:$BRIDGE_PORT"
EOF

# Rendre tous les scripts exécutables
chmod +x "$MINERS_DIR"/*.sh

echo ""
echo "✅ Installation terminée!"
echo ""
echo "📁 Mineurs installés dans: $MINERS_DIR"
echo ""
echo "🎮 Mineurs disponibles:"
echo "   - Community Miner (CPU/GPU optimisé)"
echo "   - BzMiner (GPU haute performance)"
echo "   - lolMiner (GPU pool mining)"
echo "   - Kaspa-Stratum Bridge (solo mining)"
echo ""
echo "🚀 Scripts de lancement:"
echo "   Pool Mining:"
echo "     ./start-community-pool.sh [pool_url] [wallet_address]"
echo "     ./start-bzminer-pool.sh [pool_url] [wallet_address]"
echo "     ./start-lolminer-pool.sh [pool_url] [wallet_address]"
echo ""
echo "   Solo Mining:"
echo "     ./start-stratum-bridge.sh [kaspa_node] [bridge_port]"
echo ""
echo "⚠️  Note: Redémarrez Docker après installation pour utiliser les nouveaux mineurs"