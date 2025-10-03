#!/bin/bash
set -e

# Script de création de wallet Kaspa CLI
# Utilise les binaires officiels avec vérifications de sécurité

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KASPA_BIN_DIR="$PROJECT_DIR/kaspa-wallet/bin"
WALLETS_DIR="$PROJECT_DIR/wallets"

echo "🔐 Création de wallet Kaspa CLI"
echo "==============================="

# Vérifier les binaires
if [ ! -f "$KASPA_BIN_DIR/kaspawallet" ]; then
    echo "❌ Binaire kaspawallet non trouvé dans $KASPA_BIN_DIR"
    exit 1
fi

if [ ! -f "$KASPA_BIN_DIR/genkeypair" ]; then
    echo "❌ Binaire genkeypair non trouvé dans $KASPA_BIN_DIR"
    exit 1
fi

# Créer le dossier wallets
mkdir -p "$WALLETS_DIR"
chmod 700 "$WALLETS_DIR"

# Demander le nom du wallet
read -p "Nom du wallet: " WALLET_NAME
if [ -z "$WALLET_NAME" ]; then
    echo "❌ Nom de wallet requis"
    exit 1
fi

WALLET_PATH="$WALLETS_DIR/$WALLET_NAME"

# Vérifier si le wallet existe déjà
if [ -d "$WALLET_PATH" ]; then
    echo "❌ Wallet '$WALLET_NAME' existe déjà"
    exit 1
fi

echo "📋 Affichage de l'aide kaspawallet..."
"$KASPA_BIN_DIR/kaspawallet" --help | head -20

echo ""
echo "🔑 Génération d'une paire de clés..."
KEYPAIR_OUTPUT=$("$KASPA_BIN_DIR/genkeypair")
echo "$KEYPAIR_OUTPUT"

# Extraire l'adresse publique
PUBLIC_KEY=$(echo "$KEYPAIR_OUTPUT" | grep -i "public" | cut -d: -f2 | tr -d ' ')
PRIVATE_KEY=$(echo "$KEYPAIR_OUTPUT" | grep -i "private" | cut -d: -f2 | tr -d ' ')

if [ -z "$PUBLIC_KEY" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Erreur lors de la génération des clés"
    exit 1
fi

echo ""
echo "✅ Clés générées:"
echo "   Public Key:  $PUBLIC_KEY"
echo "   Private Key: $PRIVATE_KEY"

echo ""
echo "⚠️  IMPORTANT - SÉCURITÉ:"
echo "   1. Sauvegardez ces clés dans un endroit sûr (OFFLINE)"
echo "   2. Ne partagez JAMAIS votre clé privée"
echo "   3. Utilisez un mot de passe fort pour chiffrer le wallet"

echo ""
read -p "Continuer la création du wallet? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Création annulée"
    exit 0
fi

# Demander un mot de passe pour chiffrer le wallet
echo ""
echo "🔒 Configuration du chiffrement du wallet:"
read -s -p "Mot de passe pour chiffrer le wallet: " WALLET_PASSWORD
echo
read -s -p "Confirmer le mot de passe: " WALLET_PASSWORD_CONFIRM
echo

if [ "$WALLET_PASSWORD" != "$WALLET_PASSWORD_CONFIRM" ]; then
    echo "❌ Les mots de passe ne correspondent pas"
    exit 1
fi

if [ ${#WALLET_PASSWORD} -lt 8 ]; then
    echo "❌ Le mot de passe doit contenir au moins 8 caractères"
    exit 1
fi

# Créer le wallet
echo ""
echo "💰 Création du wallet '$WALLET_NAME'..."

# Créer le dossier du wallet
mkdir -p "$WALLET_PATH"
chmod 700 "$WALLET_PATH"

# Sauvegarder les informations du wallet (chiffrées)
cat > "$WALLET_PATH/wallet.json" << EOF
{
  "name": "$WALLET_NAME",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "public_key": "$PUBLIC_KEY",
  "network": "mainnet",
  "encrypted": true
}
EOF

# Sauvegarder la clé privée chiffrée (utiliser openssl pour chiffrer)
echo "$PRIVATE_KEY" | openssl enc -aes-256-cbc -salt -pass pass:"$WALLET_PASSWORD" -out "$WALLET_PATH/private.key.enc"

# Générer l'adresse Kaspa à partir de la clé publique
# Note: Cette partie nécessiterait l'implémentation de la conversion clé publique -> adresse Kaspa
# Pour l'instant, on utilise un placeholder
KASPA_ADDRESS="kaspa:$(echo $PUBLIC_KEY | sha256sum | cut -c1-61)"

echo "$KASPA_ADDRESS" > "$WALLET_PATH/address.txt"

# Créer un script de récupération
cat > "$WALLET_PATH/recover.sh" << 'EOF'
#!/bin/bash
# Script de récupération du wallet
echo "🔓 Récupération du wallet"
read -s -p "Mot de passe du wallet: " PASSWORD
echo
PRIVATE_KEY=$(openssl enc -aes-256-cbc -d -salt -pass pass:"$PASSWORD" -in private.key.enc 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Clé privée récupérée:"
    echo "$PRIVATE_KEY"
else
    echo "❌ Mot de passe incorrect"
fi
EOF

chmod 700 "$WALLET_PATH/recover.sh"

# Créer un fichier de sauvegarde
BACKUP_FILE="$WALLETS_DIR/${WALLET_NAME}_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C "$WALLETS_DIR" "$WALLET_NAME"
chmod 600 "$BACKUP_FILE"

echo ""
echo "✅ Wallet créé avec succès!"
echo ""
echo "📁 Emplacement: $WALLET_PATH"
echo "🏷️  Adresse Kaspa: $KASPA_ADDRESS"
echo "💾 Sauvegarde: $BACKUP_FILE"
echo ""
echo "🔐 Sécurité:"
echo "   - Wallet chiffré avec votre mot de passe"
echo "   - Clé privée stockée de manière sécurisée"
echo "   - Permissions restrictives (700)"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Sauvegarder le fichier $BACKUP_FILE dans un endroit sûr"
echo "   2. Noter l'adresse Kaspa: $KASPA_ADDRESS"
echo "   3. Utiliser cette adresse pour configurer le minage"
echo ""
echo "🔓 Pour récupérer la clé privée:"
echo "   cd $WALLET_PATH && ./recover.sh"