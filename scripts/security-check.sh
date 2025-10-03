#!/bin/bash

# Script d'audit de sécurité automatisé
set -e

echo "🔍 Audit de sécurité KaspaZof..."

# Créer environnement temporaire
TEMP_ENV="security_audit_$(date +%s)"
python3 -m venv "$TEMP_ENV"

# Fonction de nettoyage
cleanup() {
    echo "🧹 Nettoyage..."
    rm -rf "$TEMP_ENV"
}
trap cleanup EXIT

# Installer pip-audit
"$TEMP_ENV/bin/pip" install pip-audit > /dev/null 2>&1

echo "📦 Audit des dépendances Python..."
if "$TEMP_ENV/bin/pip-audit" --requirement backend/requirements.txt --format json > security_report.json; then
    echo "✅ Aucune vulnérabilité critique détectée"
    PYTHON_SECURE=true
else
    echo "⚠️  Vulnérabilités détectées - voir security_report.json"
    PYTHON_SECURE=false
fi

# Audit frontend si package.json existe
if [ -f "package.json" ]; then
    echo "📦 Audit des dépendances Node.js..."
    if command -v npm &> /dev/null; then
        if npm audit --audit-level=high > npm_audit.json 2>&1; then
            echo "✅ Frontend sécurisé"
            NODE_SECURE=true
        else
            echo "⚠️  Vulnérabilités frontend détectées"
            NODE_SECURE=false
        fi
    else
        echo "⚠️  npm non disponible - audit frontend ignoré"
        NODE_SECURE=true
    fi
else
    NODE_SECURE=true
fi

# Vérifier les secrets
echo "🔐 Vérification des secrets..."
if [ -f ".env" ]; then
    echo "⚠️  Fichier .env présent - vérifier qu'il n'est pas committé"
    if git ls-files --error-unmatch .env 2>/dev/null; then
        echo "❌ CRITIQUE: .env est tracké par Git!"
        SECRETS_SECURE=false
    else
        echo "✅ .env non tracké"
        SECRETS_SECURE=true
    fi
else
    echo "✅ Pas de .env en racine"
    SECRETS_SECURE=true
fi

# Rapport final
echo ""
echo "📊 Rapport de sécurité:"
echo "   Python Backend: $([ "$PYTHON_SECURE" = true ] && echo "✅ Sécurisé" || echo "❌ Vulnérable")"
echo "   Frontend Node:  $([ "$NODE_SECURE" = true ] && echo "✅ Sécurisé" || echo "❌ Vulnérable")"
echo "   Gestion secrets: $([ "$SECRETS_SECURE" = true ] && echo "✅ Sécurisé" || echo "❌ Vulnérable")"

# Code de sortie
if [ "$PYTHON_SECURE" = true ] && [ "$NODE_SECURE" = true ] && [ "$SECRETS_SECURE" = true ]; then
    echo ""
    echo "🎉 Audit de sécurité réussi!"
    exit 0
else
    echo ""
    echo "🚨 Problèmes de sécurité détectés - voir les rapports ci-dessus"
    exit 1
fi