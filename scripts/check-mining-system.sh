#!/bin/bash
set -e

# Script de vérification du système de minage Kaspa
# Vérifie que tous les composants sont correctement installés et configurés

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Vérification du système de minage KaspaZof"
echo "=============================================="

cd "$PROJECT_DIR"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifications système
echo "📋 Vérifications système:"

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    check_ok "Docker installé (version $DOCKER_VERSION)"
else
    check_error "Docker non installé"
    exit 1
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
    check_ok "Docker Compose installé (version $COMPOSE_VERSION)"
    DOCKER_COMPOSE="docker-compose"
elif command -v docker compose &> /dev/null; then
    check_ok "Docker Compose (plugin) installé"
    DOCKER_COMPOSE="docker compose"
else
    check_error "Docker Compose non installé"
    exit 1
fi

# Vérifier que Docker fonctionne
if docker ps &> /dev/null; then
    check_ok "Docker daemon actif"
else
    check_error "Docker daemon non accessible"
    exit 1
fi

echo ""
echo "📁 Vérifications des fichiers:"

# Fichiers requis
REQUIRED_FILES=(
    "docker-compose-mining.yml"
    "kaspa-wallet/Dockerfile"
    "kaspa-wallet/docker-entrypoint.sh"
    "mining-monitor/Dockerfile"
    "mining-monitor/main.py"
    "scripts/start-mining.sh"
    "scripts/mining-manager.sh"
    "monitoring/prometheus-mining.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_ok "Fichier $file présent"
    else
        check_error "Fichier $file manquant"
    fi
done

# Vérifier les permissions des scripts
SCRIPTS=(
    "scripts/start-mining.sh"
    "scripts/mining-manager.sh"
    "scripts/generate_dev_secrets.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        check_ok "Script $script exécutable"
    else
        check_warning "Script $script non exécutable (chmod +x $script)"
    fi
done

echo ""
echo "⚙️  Vérifications de configuration:"

# Fichier .env
if [ -f ".env" ]; then
    check_ok "Fichier .env présent"
    
    # Vérifier les variables importantes
    source .env
    
    if [ -n "$MINING_ADDRESS" ] && [ "$MINING_ADDRESS" != "kaspa:qz0000000000000000000000000000000000000000000000000000000000" ]; then
        check_ok "Adresse de minage configurée: $MINING_ADDRESS"
    else
        check_warning "Adresse de minage par défaut (à modifier dans .env)"
    fi
    
    if [ -n "$KASPA_RPC_PASSWORD" ]; then
        check_ok "Mot de passe RPC Kaspa configuré"
    else
        check_warning "Mot de passe RPC Kaspa non configuré"
    fi
    
else
    check_warning "Fichier .env manquant (exécuter ./scripts/generate_dev_secrets.sh)"
fi

# Binaires Kaspa
echo ""
echo "🔗 Vérifications des binaires Kaspa:"

KASPA_BINARIES=(
    "kaspa-wallet/bin/kaspad"
    "kaspa-wallet/bin/kaspawallet"
    "kaspa-wallet/bin/kaspaminer"
    "kaspa-wallet/bin/kaspactl"
)

for binary in "${KASPA_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        if [ -x "$binary" ]; then
            check_ok "Binaire $binary présent et exécutable"
        else
            check_warning "Binaire $binary présent mais non exécutable"
        fi
    else
        check_error "Binaire $binary manquant"
    fi
done

echo ""
echo "🐳 Vérifications Docker:"

# Images Docker
echo "Vérification des images Docker disponibles..."
if docker images | grep -q "kaspazof"; then
    check_ok "Images KaspaZof présentes"
else
    check_warning "Images KaspaZof non construites (seront construites au démarrage)"
fi

# Volumes Docker
echo "Vérification des volumes Docker..."
VOLUMES=$(docker volume ls -q | grep kaspazof | wc -l)
if [ "$VOLUMES" -gt 0 ]; then
    check_ok "$VOLUMES volumes KaspaZof existants"
else
    check_warning "Aucun volume KaspaZof (seront créés au démarrage)"
fi

echo ""
echo "🌐 Vérifications réseau:"

# Ports disponibles
REQUIRED_PORTS=(8000 8080 8081 3000 9090 5432 6379 16210 16211)
for port in "${REQUIRED_PORTS[@]}"; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        check_warning "Port $port déjà utilisé"
    else
        check_ok "Port $port disponible"
    fi
done

echo ""
echo "💾 Vérifications des ressources:"

# Espace disque
AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

if [ "$AVAILABLE_GB" -gt 50 ]; then
    check_ok "Espace disque suffisant (${AVAILABLE_GB}GB disponibles)"
elif [ "$AVAILABLE_GB" -gt 20 ]; then
    check_warning "Espace disque limité (${AVAILABLE_GB}GB disponibles, 50GB+ recommandés)"
else
    check_error "Espace disque insuffisant (${AVAILABLE_GB}GB disponibles, 50GB+ requis)"
fi

# Mémoire RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -gt 7 ]; then
    check_ok "RAM suffisante (${TOTAL_RAM}GB)"
elif [ "$TOTAL_RAM" -gt 3 ]; then
    check_warning "RAM limitée (${TOTAL_RAM}GB, 8GB+ recommandés)"
else
    check_error "RAM insuffisante (${TOTAL_RAM}GB, 4GB+ requis)"
fi

echo ""
echo "📊 Résumé:"

# Compter les erreurs et avertissements
ERROR_COUNT=$(grep -c "❌" /tmp/check_output 2>/dev/null || echo 0)
WARNING_COUNT=$(grep -c "⚠️" /tmp/check_output 2>/dev/null || echo 0)

if [ "$ERROR_COUNT" -eq 0 ] && [ "$WARNING_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Système prêt pour le minage Kaspa!${NC}"
    echo ""
    echo "Commandes pour démarrer:"
    echo "  ./scripts/start-mining.sh [ADRESSE_KASPA]"
    echo "  ./scripts/mining-manager.sh status"
elif [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Système fonctionnel avec quelques avertissements${NC}"
    echo "Vous pouvez démarrer le minage, mais vérifiez les avertissements ci-dessus."
else
    echo -e "${RED}❌ Erreurs détectées, corrigez-les avant de démarrer le minage${NC}"
    exit 1
fi

echo ""
echo "📚 Ressources utiles:"
echo "  Guide de minage: ./MINING_GUIDE.md"
echo "  Documentation: ./README.md"
echo "  Support: https://github.com/BJATechnology/KaspaZof/issues"