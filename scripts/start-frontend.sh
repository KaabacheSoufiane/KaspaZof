#!/bin/bash

# Script de démarrage de l'interface KaspaZof
set -e

echo "🎨 Démarrage de l'interface KaspaZof..."

# Vérifier que les ports sont libres
echo "🔍 Vérification des ports..."
if lsof -ti:8081 >/dev/null 2>&1; then
    echo "❌ Port 8081 occupé. Exécutez d'abord: ./scripts/kill-ports.sh"
    exit 1
fi

if lsof -ti:8000 >/dev/null 2>&1; then
    echo "❌ Port 8000 occupé. Exécutez d'abord: ./scripts/kill-ports.sh"
    exit 1
fi

# Aller dans le dossier frontend
cd frontend

# Démarrer le serveur frontend
echo "🌐 Démarrage du serveur frontend sur le port 8081..."
python3 -m http.server 8081 &
FRONTEND_PID=$!

# Attendre que le serveur démarre
sleep 2

# Vérifier que le serveur fonctionne
if curl -f http://localhost:8081 >/dev/null 2>&1; then
    echo "✅ Frontend démarré avec succès!"
else
    echo "❌ Erreur lors du démarrage du frontend"
    kill $FRONTEND_PID 2>/dev/null || true
    exit 1
fi

# Retourner au dossier racine
cd ..

# Démarrer le backend si disponible
if [ -f "backend/app/main.py" ]; then
    echo "🔧 Démarrage du backend API..."
    cd backend
    
    # Créer un environnement virtuel si nécessaire
    if [ ! -d "venv" ]; then
        echo "📦 Création de l'environnement virtuel..."
        python3 -m venv venv
    fi
    
    # Activer l'environnement virtuel
    source venv/bin/activate
    
    # Installer les dépendances
    echo "📦 Installation des dépendances..."
    pip install -r requirements.txt >/dev/null 2>&1
    
    # Générer les secrets si nécessaire
    if [ ! -f "../.env" ]; then
        echo "🔐 Génération des secrets..."
        cd ..
        ./scripts/generate_dev_secrets.sh
        cd backend
    fi
    
    # Démarrer l'API
    echo "🚀 Démarrage de l'API sur le port 8000..."
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
    API_PID=$!
    
    # Attendre que l'API démarre
    sleep 5
    
    # Vérifier que l'API fonctionne
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        echo "✅ Backend API démarré avec succès!"
    else
        echo "⚠️  Backend API non accessible (normal si pas encore configuré)"
    fi
    
    cd ..
else
    echo "⚠️  Backend non trouvé, démarrage frontend uniquement"
fi

echo ""
echo "🎉 KaspaZof Interface démarrée!"
echo ""
echo "📱 Accès à l'interface:"
echo "   🌐 Frontend:  http://localhost:8081"
echo "   🔧 API:       http://localhost:8000 (si disponible)"
echo "   📚 API Docs:  http://localhost:8000/docs (si disponible)"
echo ""
echo "⌨️  Raccourcis clavier dans l'interface:"
echo "   Ctrl+1: Dashboard"
echo "   Ctrl+2: Wallet"
echo "   Ctrl+3: Mining"
echo "   Ctrl+4: Charts"
echo "   Ctrl+5: News"
echo "   Ctrl+R: Refresh"
echo ""
echo "🛑 Pour arrêter:"
echo "   ./scripts/kill-ports.sh"
echo ""

# Ouvrir le navigateur automatiquement (optionnel)
if command -v xdg-open >/dev/null 2>&1; then
    echo "🌐 Ouverture automatique du navigateur..."
    sleep 2
    xdg-open http://localhost:8081 >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    echo "🌐 Ouverture automatique du navigateur..."
    sleep 2
    open http://localhost:8081 >/dev/null 2>&1 &
fi

# Garder le script en vie et afficher les logs
echo "📊 Surveillance des services (Ctrl+C pour arrêter)..."
echo ""

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt des services..."
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
    fi
    
    # Nettoyer tous les ports
    ./scripts/kill-ports.sh >/dev/null 2>&1 || true
    
    echo "✅ Services arrêtés"
    exit 0
}

# Capturer Ctrl+C
trap cleanup SIGINT SIGTERM

# Boucle de surveillance
while true; do
    # Vérifier que les services tournent
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "❌ Frontend arrêté de manière inattendue"
        break
    fi
    
    if [ ! -z "$API_PID" ] && ! kill -0 $API_PID 2>/dev/null; then
        echo "⚠️  Backend API arrêté"
    fi
    
    sleep 10
done

cleanup