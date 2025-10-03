#!/bin/bash
set -e

# Test des binaires Kaspa locaux
# Vérification complète avant production

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KASPA_BIN_DIR="$PROJECT_DIR/kaspa-wallet/bin"

echo "🧪 Test des binaires Kaspa"
echo "=========================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

test_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier la présence des binaires
echo "📁 Vérification des binaires..."
BINARIES=("kaspad" "kaspawallet" "kaspaminer" "kaspactl" "genkeypair")
MISSING_BINARIES=()

for binary in "${BINARIES[@]}"; do
    if [ -f "$KASPA_BIN_DIR/$binary" ]; then
        if [ -x "$KASPA_BIN_DIR/$binary" ]; then
            test_ok "Binaire $binary présent et exécutable"
        else
            test_warning "Binaire $binary présent mais non exécutable"
            chmod +x "$KASPA_BIN_DIR/$binary"
            test_ok "Permissions corrigées pour $binary"
        fi
    else
        test_error "Binaire $binary manquant"
        MISSING_BINARIES+=("$binary")
    fi
done

if [ ${#MISSING_BINARIES[@]} -gt 0 ]; then
    echo ""
    echo "❌ Binaires manquants: ${MISSING_BINARIES[*]}"
    echo "Téléchargez les binaires depuis: https://github.com/kaspanet/kaspad/releases"
    exit 1
fi

echo ""
echo "🔍 Test des commandes d'aide..."

# Tester kaspad --help
echo "Testing kaspad --help..."
if "$KASPA_BIN_DIR/kaspad" --help >/dev/null 2>&1; then
    test_ok "kaspad --help fonctionne"
else
    test_error "kaspad --help échoue"
fi

# Tester kaspawallet --help
echo "Testing kaspawallet --help..."
if "$KASPA_BIN_DIR/kaspawallet" --help >/dev/null 2>&1; then
    test_ok "kaspawallet --help fonctionne"
else
    test_error "kaspawallet --help échoue"
fi

# Tester kaspaminer --help
echo "Testing kaspaminer --help..."
if "$KASPA_BIN_DIR/kaspaminer" --help >/dev/null 2>&1; then
    test_ok "kaspaminer --help fonctionne"
else
    test_error "kaspaminer --help échoue"
fi

# Tester kaspactl --help
echo "Testing kaspactl --help..."
if "$KASPA_BIN_DIR/kaspactl" --help >/dev/null 2>&1; then
    test_ok "kaspactl --help fonctionne"
else
    test_error "kaspactl --help échoue"
fi

# Tester genkeypair
echo "Testing genkeypair..."
if "$KASPA_BIN_DIR/genkeypair" >/dev/null 2>&1; then
    test_ok "genkeypair fonctionne"
else
    test_error "genkeypair échoue"
fi

echo ""
echo "🔑 Test de génération de clés..."

# Test de génération de paire de clés
KEYPAIR_OUTPUT=$("$KASPA_BIN_DIR/genkeypair" 2>/dev/null || echo "ERROR")
if [ "$KEYPAIR_OUTPUT" != "ERROR" ]; then
    test_ok "Génération de paire de clés réussie"
    echo "   Exemple de sortie:"
    echo "$KEYPAIR_OUTPUT" | head -3 | sed 's/^/   /'
else
    test_error "Génération de paire de clés échouée"
fi

echo ""
echo "🐳 Test de l'environnement Docker..."

# Vérifier Docker
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        test_ok "Docker disponible et fonctionnel"
    else
        test_error "Docker installé mais daemon non accessible"
    fi
else
    test_error "Docker non installé"
fi

# Vérifier Docker Compose
if command -v docker-compose &> /dev/null; then
    test_ok "Docker Compose disponible"
    DOCKER_COMPOSE="docker-compose"
elif command -v docker compose &> /dev/null; then
    test_ok "Docker Compose (plugin) disponible"
    DOCKER_COMPOSE="docker compose"
else
    test_error "Docker Compose non disponible"
fi

echo ""
echo "📊 Test de démarrage kaspad (mode test)..."

# Créer un dossier temporaire pour le test
TEST_DIR="/tmp/kaspa-test-$$"
mkdir -p "$TEST_DIR"

# Configuration de test
cat > "$TEST_DIR/kaspad-test.conf" << EOF
network=testnet-11
datadir=$TEST_DIR/data
logdir=$TEST_DIR/logs
rpclisten=127.0.0.1:16310
rpcbind=127.0.0.1:16310
listen=127.0.0.1:16311
loglevel=info
EOF

echo "Démarrage de kaspad en mode test..."
"$KASPA_BIN_DIR/kaspad" --configfile="$TEST_DIR/kaspad-test.conf" &
KASPAD_PID=$!

# Attendre que kaspad démarre
sleep 5

# Vérifier si kaspad fonctionne
if kill -0 $KASPAD_PID 2>/dev/null; then
    test_ok "kaspad démarré avec succès (PID: $KASPAD_PID)"
    
    # Tester la connexion RPC
    sleep 2
    if "$KASPA_BIN_DIR/kaspactl" --rpcserver=127.0.0.1:16310 get-info >/dev/null 2>&1; then
        test_ok "Connexion RPC fonctionnelle"
    else
        test_warning "Connexion RPC non disponible (normal au démarrage)"
    fi
    
    # Arrêter kaspad
    kill $KASPAD_PID
    wait $KASPAD_PID 2>/dev/null || true
    test_ok "kaspad arrêté proprement"
else
    test_error "kaspad n'a pas pu démarrer"
fi

# Nettoyer
rm -rf "$TEST_DIR"

echo ""
echo "🔧 Test de configuration Docker..."

# Vérifier les fichiers Docker
if [ -f "$PROJECT_DIR/docker-compose-mining.yml" ]; then
    test_ok "Fichier docker-compose-mining.yml présent"
    
    # Valider la syntaxe YAML
    if $DOCKER_COMPOSE -f "$PROJECT_DIR/docker-compose-mining.yml" config >/dev/null 2>&1; then
        test_ok "Syntaxe docker-compose valide"
    else
        test_error "Erreur de syntaxe dans docker-compose-mining.yml"
    fi
else
    test_error "Fichier docker-compose-mining.yml manquant"
fi

if [ -f "$PROJECT_DIR/kaspa-wallet/Dockerfile" ]; then
    test_ok "Dockerfile Kaspa présent"
else
    test_error "Dockerfile Kaspa manquant"
fi

echo ""
echo "📋 Résumé des tests:"
echo "==================="

# Compter les résultats
TOTAL_TESTS=$(grep -c "test_\(ok\|warning\|error\)" "$0" || echo "0")
echo "Tests effectués: $TOTAL_TESTS"

echo ""
echo "🚀 Prochaines étapes recommandées:"
echo "1. Si tous les tests passent: ./scripts/start-mining.sh"
echo "2. Créer un wallet: ./scripts/create-wallet-cli.sh"
echo "3. Configurer un pool: ./scripts/configure-pool-mining.sh"
echo "4. Vérifier le système: ./scripts/check-mining-system.sh"

echo ""
echo "📚 Documentation:"
echo "- Guide de minage: ./MINING_GUIDE.md"
echo "- Guide de sécurité: ./KASPA_SECURITY_GUIDE.md"
echo "- README principal: ./README.md"