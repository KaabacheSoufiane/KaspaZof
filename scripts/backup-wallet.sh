#!/bin/bash
set -e

# Script de sauvegarde sécurisée des wallets Kaspa

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WALLETS_DIR="$PROJECT_DIR/wallets"
BACKUP_DIR="$PROJECT_DIR/backups"

echo "💾 Sauvegarde des wallets Kaspa"
echo "==============================="

# Créer le dossier de sauvegarde
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Vérifier si des wallets existent
if [ ! -d "$WALLETS_DIR" ] || [ -z "$(ls -A "$WALLETS_DIR" 2>/dev/null)" ]; then
    echo "❌ Aucun wallet trouvé dans $WALLETS_DIR"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/kaspa_wallets_backup_$TIMESTAMP.tar.gz"

echo "📁 Wallets trouvés:"
ls -la "$WALLETS_DIR"

echo ""
echo "🔐 Création de la sauvegarde chiffrée..."

# Demander un mot de passe pour chiffrer la sauvegarde
read -s -p "Mot de passe pour chiffrer la sauvegarde: " BACKUP_PASSWORD
echo
read -s -p "Confirmer le mot de passe: " BACKUP_PASSWORD_CONFIRM
echo

if [ "$BACKUP_PASSWORD" != "$BACKUP_PASSWORD_CONFIRM" ]; then
    echo "❌ Les mots de passe ne correspondent pas"
    exit 1
fi

if [ ${#BACKUP_PASSWORD} -lt 8 ]; then
    echo "❌ Le mot de passe doit contenir au moins 8 caractères"
    exit 1
fi

# Créer l'archive tar.gz
echo "📦 Création de l'archive..."
tar -czf "$BACKUP_FILE.tmp" -C "$PROJECT_DIR" wallets/

# Chiffrer l'archive
echo "🔒 Chiffrement de l'archive..."
openssl enc -aes-256-cbc -salt -pass pass:"$BACKUP_PASSWORD" -in "$BACKUP_FILE.tmp" -out "$BACKUP_FILE.enc"

# Supprimer l'archive temporaire non chiffrée
rm "$BACKUP_FILE.tmp"

# Créer un fichier d'informations
cat > "$BACKUP_FILE.info" << EOF
Sauvegarde des wallets Kaspa KaspaZof
=====================================

Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Fichier: $(basename "$BACKUP_FILE.enc")
Wallets inclus: $(ls "$WALLETS_DIR" | wc -l)
Taille: $(du -h "$BACKUP_FILE.enc" | cut -f1)

Wallets sauvegardés:
$(ls -1 "$WALLETS_DIR")

Pour restaurer:
1. openssl enc -aes-256-cbc -d -salt -pass pass:VOTRE_MOT_DE_PASSE -in $(basename "$BACKUP_FILE.enc") -out wallets_restore.tar.gz
2. tar -xzf wallets_restore.tar.gz
3. Vérifier l'intégrité des wallets

⚠️  IMPORTANT:
- Gardez ce fichier et le mot de passe en sécurité
- Testez la restauration sur une machine de test
- Ne stockez jamais le mot de passe avec la sauvegarde
EOF

# Sécuriser les permissions
chmod 600 "$BACKUP_FILE.enc"
chmod 600 "$BACKUP_FILE.info"

# Calculer le hash pour vérification d'intégrité
BACKUP_HASH=$(sha256sum "$BACKUP_FILE.enc" | cut -d' ' -f1)
echo "Hash SHA256: $BACKUP_HASH" >> "$BACKUP_FILE.info"

echo ""
echo "✅ Sauvegarde créée avec succès!"
echo ""
echo "📁 Fichiers créés:"
echo "   Sauvegarde chiffrée: $BACKUP_FILE.enc"
echo "   Informations: $BACKUP_FILE.info"
echo ""
echo "🔐 Sécurité:"
echo "   - Archive chiffrée avec AES-256-CBC"
echo "   - Hash SHA256: $BACKUP_HASH"
echo "   - Permissions restrictives (600)"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Copier les fichiers vers un stockage sécurisé (USB, cloud chiffré)"
echo "   2. Tester la restauration sur une machine de test"
echo "   3. Noter le mot de passe dans un gestionnaire de mots de passe"
echo ""
echo "🔓 Pour restaurer:"
echo "   openssl enc -aes-256-cbc -d -salt -pass pass:VOTRE_MOT_DE_PASSE -in $(basename "$BACKUP_FILE.enc") -out wallets_restore.tar.gz"
echo "   tar -xzf wallets_restore.tar.gz"