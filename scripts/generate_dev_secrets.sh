#!/bin/bash

# Script de génération des secrets pour développement local
# NE PAS UTILISER EN PRODUCTION

set -e

ENV_FILE=".env"
BACKUP_FILE=".env.backup.$(date +%s)"

echo "🔐 Génération des secrets de développement pour KaspaZof..."

# Backup de l'ancien .env si existe
if [ -f "$ENV_FILE" ]; then
    echo "📋 Sauvegarde de l'ancien .env vers $BACKUP_FILE"
    cp "$ENV_FILE" "$BACKUP_FILE"
fi

# Génération des mots de passe aléatoirement sécurisés
generate_password() {
    local password
    password=$(openssl rand -base64 32 2>/dev/null | tr -d "=+/" | cut -c1-25)
    if [ -z "$password" ] || [ ${#password} -lt 20 ]; then
        echo "❌ Erreur lors de la génération du mot de passe" >&2
        exit 1
    fi
    echo "$password"
}

generate_key() {
    local key
    key=$(openssl rand -hex 32 2>/dev/null)
    if [ -z "$key" ] || [ ${#key} -ne 64 ]; then
        echo "❌ Erreur lors de la génération de la clé" >&2
        exit 1
    fi
    echo "$key"
}

# Création du fichier .env
cat > "$ENV_FILE" << EOF
# KaspaZof - Configuration de développement local
# ⚠️  NE PAS COMMITTER CE FICHIER ⚠️

# Base de données
POSTGRES_PASSWORD=$(generate_password)
DATABASE_URL=postgresql://postgres:$(generate_password)@postgres:5432/kaspazof

# Cache Redis
REDIS_URL=redis://redis:6379/0

# Storage MinIO
MINIO_ROOT_USER=kaspazof
MINIO_ROOT_PASSWORD=$(generate_password)
MINIO_ENDPOINT=http://minio:9000

# API Keys
DASHBOARD_API_KEY=$(generate_key)
JWT_SECRET_KEY=$(generate_key)

# Kaspa Node
KASPA_RPC_URL=http://kaspa-node:16210
KASPA_RPC_USER=kaspa
KASPA_RPC_PASSWORD=$(generate_password)
KASPA_NETWORK=mainnet

# Minage Kaspa
MINING_ADDRESS=kaspa:qz0000000000000000000000000000000000000000000000000000000000
MINING_ENABLED=false
MINERS_COUNT=1

# Monitoring
GRAFANA_PASSWORD=$(generate_password)

# Environnement
ENVIRONMENT=development
DEBUG=true

# Sécurité (dev uniquement)
CORS_ORIGINS=http://localhost:8081,http://localhost:3000
ALLOWED_HOSTS=localhost,127.0.0.1

EOF

# Sécuriser le fichier
chmod 600 "$ENV_FILE"

echo "✅ Fichier .env généré avec succès"
echo "🔒 Permissions définies à 600 (lecture/écriture propriétaire uniquement)"
echo ""
echo "📝 Variables générées:"
echo "   - POSTGRES_PASSWORD"
echo "   - DATABASE_URL" 
echo "   - MINIO_ROOT_PASSWORD"
echo "   - DASHBOARD_API_KEY"
echo "   - JWT_SECRET_KEY"
echo "   - GRAFANA_PASSWORD"
echo "   - KASPA_RPC_PASSWORD"
echo "   - MINING_ADDRESS (exemple)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Ce fichier contient des secrets de DÉVELOPPEMENT uniquement"
echo "   - Ne jamais committer le fichier .env"
echo "   - Régénérer les secrets pour la production"
echo "   - Utiliser un gestionnaire de secrets en production (Vault, etc.)"
echo ""
echo "🚀 Vous pouvez maintenant lancer: ./scripts/quick-start.sh"