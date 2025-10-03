#!/bin/bash

# Script de démarrage rapide KaspaZof
set -e

echo "🚀 Démarrage de KaspaZof..."

# Vérifications préalables
check_requirements() {
    echo "🔍 Vérification des prérequis..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker n'est pas installé"
        exit 1
    fi
    
    # Docker Compose
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose n'est pas disponible"
        exit 1
    fi
    
    # Fichier .env
    if [ ! -f ".env" ]; then
        echo "❌ Fichier .env manquant"
        echo "💡 Exécutez: ./scripts/generate_dev_secrets.sh"
        exit 1
    fi
    
    echo "✅ Prérequis OK"
}

# Installation des dépendances frontend
install_frontend_deps() {
    echo "📦 Installation des dépendances frontend..."
    
    if command -v pnpm &> /dev/null; then
        cd frontend && pnpm install && cd ..
    elif command -v npm &> /dev/null; then
        cd frontend && npm install && cd ..
    else
        echo "❌ npm ou pnpm requis pour le frontend"
        exit 1
    fi
    
    echo "✅ Dépendances frontend installées"
}

# Build du frontend
build_frontend() {
    echo "🏗️  Build du frontend..."
    
    cd frontend
    if command -v pnpm &> /dev/null; then
        pnpm run build
    else
        npm run build
    fi
    cd ..
    
    echo "✅ Frontend buildé"
}

# Démarrage des services
start_services() {
    echo "🐳 Démarrage des services Docker..."
    
    # Arrêter les services existants
    docker compose down --remove-orphans
    
    # Build et démarrage
    docker compose up -d --build
    
    echo "✅ Services démarrés"
}

# Vérification de la santé des services
check_health() {
    echo "🏥 Vérification de la santé des services..."
    
    # Attendre que les services soient prêts
    echo "⏳ Attente du démarrage des services..."
    sleep 10
    
    # Vérifier l'API
    for i in {1..30}; do
        if curl -f http://localhost:8000/health &> /dev/null; then
            echo "✅ API backend opérationnelle"
            break
        fi
        
        if [ $i -eq 30 ]; then
            echo "❌ Timeout: API backend non accessible"
            docker compose logs api
            exit 1
        fi
        
        sleep 2
    done
    
    # Vérifier le frontend
    if curl -f http://localhost:8081 &> /dev/null; then
        echo "✅ Frontend accessible"
    else
        echo "⚠️  Frontend non accessible (vérifiez les logs)"
    fi
}

# Affichage des informations de connexion
show_info() {
    echo ""
    echo "🎉 KaspaZof démarré avec succès!"
    echo ""
    echo "📱 Interfaces disponibles:"
    echo "   🌐 Frontend:    http://localhost:8081"
    echo "   🔧 API:         http://localhost:8000"
    echo "   📊 Grafana:     http://localhost:3000 (admin/$(grep GRAFANA_PASSWORD .env | cut -d'=' -f2))"
    echo "   📈 Prometheus:  http://localhost:9090"
    echo "   💾 MinIO:       http://localhost:9001"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   📋 Logs:        docker compose logs -f"
    echo "   🛑 Arrêt:       docker compose down"
    echo "   🔄 Restart:     docker compose restart"
    echo "   🧹 Nettoyage:   docker compose down -v"
    echo ""
    echo "📚 Documentation: README.md"
}

# Fonction principale
main() {
    check_requirements
    
    # Si le dossier frontend existe, installer et builder
    if [ -d "frontend" ]; then
        install_frontend_deps
        build_frontend
    fi
    
    start_services
    check_health
    show_info
}

# Gestion des erreurs
trap 'echo "❌ Erreur lors du démarrage. Vérifiez les logs: docker compose logs"' ERR

# Exécution
main "$@"