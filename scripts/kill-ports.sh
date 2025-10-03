#!/bin/bash

# Script pour tuer tous les processus sur les ports utilisés par KaspaZof
set -e

echo "🔪 Nettoyage des ports KaspaZof..."

# Ports utilisés par KaspaZof
PORTS=(
    8000    # Backend API
    8081    # Frontend
    8082    # Frontend alternatif
    3000    # Grafana
    9090    # Prometheus
    9001    # MinIO Console
    9000    # MinIO API
    5432    # PostgreSQL
    6379    # Redis
    16210   # Kaspa RPC
    16211   # Kaspa P2P
)

# Fonction pour tuer un processus sur un port
kill_port() {
    local port=$1
    echo "🔍 Vérification du port $port..."
    
    # Trouver les PIDs utilisant le port
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "⚡ Processus trouvés sur le port $port: $pids"
        
        # Tuer les processus
        for pid in $pids; do
            if kill -0 $pid 2>/dev/null; then
                echo "   🔫 Arrêt du processus $pid..."
                kill -TERM $pid 2>/dev/null || true
                
                # Attendre 2 secondes puis forcer si nécessaire
                sleep 2
                if kill -0 $pid 2>/dev/null; then
                    echo "   💥 Force kill du processus $pid..."
                    kill -KILL $pid 2>/dev/null || true
                fi
            fi
        done
        
        echo "✅ Port $port libéré"
    else
        echo "✅ Port $port déjà libre"
    fi
}

# Arrêter Docker Compose s'il tourne
echo "🐳 Arrêt des conteneurs Docker..."
if [ -f "docker-compose.yml" ]; then
    docker compose down --remove-orphans 2>/dev/null || true
fi

if [ -f "docker-compose-kaspa-mining_Version3.yml" ]; then
    docker compose -f docker-compose-kaspa-mining_Version3.yml down --remove-orphans 2>/dev/null || true
fi

# Tuer les processus sur chaque port
for port in "${PORTS[@]}"; do
    kill_port $port
done

# Nettoyer les processus Python/Node spécifiques
echo "🧹 Nettoyage des processus spécifiques..."

# Tuer les serveurs Python
pkill -f "python.*http.server" 2>/dev/null || true
pkill -f "uvicorn.*main:app" 2>/dev/null || true

# Tuer les processus Node/npm
pkill -f "node.*vite" 2>/dev/null || true
pkill -f "npm.*dev" 2>/dev/null || true

# Tuer les processus Kaspa
pkill -f "kaspad" 2>/dev/null || true

echo ""
echo "🎉 Nettoyage terminé!"
echo ""
echo "📊 État des ports après nettoyage:"
for port in "${PORTS[@]}"; do
    if lsof -ti:$port >/dev/null 2>&1; then
        echo "   ❌ Port $port: OCCUPÉ"
    else
        echo "   ✅ Port $port: LIBRE"
    fi
done

echo ""
echo "🚀 Vous pouvez maintenant démarrer KaspaZof en toute sécurité!"
echo "   ./scripts/quick-start.sh"