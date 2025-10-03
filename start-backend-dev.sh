#!/bin/bash
set -e

# Script de démarrage rapide du backend pour développement

echo "🚀 Démarrage du backend KaspaZof en mode développement"

cd backend

# Créer le dossier wallets
mkdir -p /tmp/kaspazof-wallets

# Variables d'environnement pour le développement
export REDIS_URL="redis://localhost:6379"
export DATABASE_URL="postgresql://postgres:devpass@localhost:5432/kaspazof"
export KASPA_RPC_URL="http://localhost:16210"
export ENVIRONMENT="development"

# Démarrer le serveur
echo "📡 Démarrage de l'API sur http://localhost:8000"
echo "📚 Documentation: http://localhost:8000/docs"

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000