#!/bin/bash

# Script de démarrage complet KaspaZof (Frontend + Backend + Services)
set -e

echo "🚀 Démarrage complet de KaspaZof..."
echo "=================================="

# Nettoyer les ports d'abord
echo "🧹 Nettoyage des ports..."
./scripts/kill-ports.sh >/dev/null 2>&1

# Générer les secrets si nécessaire
if [ ! -f ".env" ]; then
    echo "🔐 Génération des secrets de développement..."
    ./scripts/generate_dev_secrets.sh
fi

# Démarrer les services Docker en arrière-plan
echo "🐳 Démarrage des services Docker..."
if [ -f "docker-compose.yml" ]; then
    docker compose up -d --build
    echo "✅ Services Docker démarrés"
else
    echo "⚠️  docker-compose.yml non trouvé, services Docker ignorés"
fi

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 10

# Démarrer le backend
echo "🔧 Démarrage du backend API..."
cd backend

# Créer et activer l'environnement virtuel
if [ ! -d "venv" ]; then
    echo "📦 Création de l'environnement virtuel backend..."
    python3 -m venv venv
fi

source venv/bin/activate

# Installer les dépendances
echo "📦 Installation des dépendances backend..."
pip install -r requirements.txt >/dev/null 2>&1

# Démarrer l'API en arrière-plan
echo "🚀 Lancement de l'API FastAPI..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
API_PID=$!

cd ..

# Attendre que l'API démarre
echo "⏳ Attente du démarrage de l'API..."
for i in {1..30}; do
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        echo "✅ API backend opérationnelle"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "⚠️  Timeout: API backend non accessible"
    fi
    
    sleep 2
done

# Démarrer le frontend
echo "🎨 Démarrage de l'interface frontend..."
cd frontend

# Démarrer le serveur frontend
python3 -m http.server 8081 &
FRONTEND_PID=$!

cd ..

# Attendre que le frontend démarre
echo "⏳ Attente du démarrage du frontend..."
sleep 3

if curl -f http://localhost:8081 >/dev/null 2>&1; then
    echo "✅ Frontend accessible"
else
    echo "❌ Frontend non accessible"
fi

# Afficher le résumé
echo ""
echo "🎉 KaspaZof démarré avec succès!"
echo "================================"
echo ""
echo "📱 Interfaces disponibles:"
echo "   🌐 Frontend:    http://localhost:8081"
echo "   🔧 API:         http://localhost:8000"
echo "   📚 API Docs:    http://localhost:8000/docs"
echo "   📊 Grafana:     http://localhost:3000 (si Docker actif)"
echo "   📈 Prometheus:  http://localhost:9090 (si Docker actif)"
echo "   💾 MinIO:       http://localhost:9001 (si Docker actif)"
echo ""
echo "🔧 Commandes utiles:"
echo "   📋 Logs Docker: docker compose logs -f"
echo "   🛑 Arrêt:       ./scripts/kill-ports.sh"
echo "   🔄 Restart:     ./scripts/start-complete.sh"
echo ""
echo "⌨️  Raccourcis dans l'interface:"
echo "   Ctrl+1-5: Navigation sections"
echo "   Ctrl+R:   Refresh"
echo ""

# Ouvrir le navigateur
if command -v xdg-open >/dev/null 2>&1; then
    echo "🌐 Ouverture du navigateur..."
    sleep 2
    xdg-open http://localhost:8081 >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    sleep 2
    open http://localhost:8081 >/dev/null 2>&1 &
fi

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt de KaspaZof..."
    
    # Arrêter les processus
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
    fi
    
    # Arrêter Docker
    if [ -f "docker-compose.yml" ]; then
        echo "🐳 Arrêt des conteneurs Docker..."
        docker compose down >/dev/null 2>&1 || true
    fi
    
    # Nettoyer les ports
    ./scripts/kill-ports.sh >/dev/null 2>&1 || true
    
    echo "✅ KaspaZof arrêté complètement"
    exit 0
}

# Capturer les signaux d'arrêt
trap cleanup SIGINT SIGTERM

echo "📊 Surveillance active (Ctrl+C pour arrêter)..."
echo "Logs en temps réel:"
echo ""

# Boucle de surveillance avec logs
while true; do
    # Vérifier les services
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "❌ $(date): Frontend arrêté"
        break
    fi
    
    if [ ! -z "$API_PID" ] && ! kill -0 $API_PID 2>/dev/null; then
        echo "❌ $(date): Backend API arrêté"
    fi
    
    # Afficher un heartbeat toutes les 30 secondes
    echo "💓 $(date): Services actifs - Frontend: ✅ API: $(curl -s http://localhost:8000/health >/dev/null && echo "✅" || echo "❌")"
    
    sleep 30
done

cleanup