# 💰 Guide Wallet Kaspa Officiel - KaspaZof

Intégration complète du wallet officiel Kaspa v0.12.22 dans un environnement Docker sécurisé.

## 🚀 Démarrage rapide

### 1. Builder l'image Kaspa
```bash
./scripts/kaspa-wallet-manager.sh build
```

### 2. Générer les secrets
```bash
./scripts/generate_dev_secrets.sh
```

### 3. Démarrer les services
```bash
./scripts/kaspa-wallet-manager.sh start
```

## 📋 Commandes disponibles

### Gestion des services
```bash
# Démarrer tous les services
./scripts/kaspa-wallet-manager.sh start

# Démarrer avec mining
./scripts/kaspa-wallet-manager.sh start-mining kaspa:qz1234...

# Arrêter les services
./scripts/kaspa-wallet-manager.sh stop

# Redémarrer
./scripts/kaspa-wallet-manager.sh restart

# Voir les logs
./scripts/kaspa-wallet-manager.sh logs
./scripts/kaspa-wallet-manager.sh logs kaspa-node

# Statut des services
./scripts/kaspa-wallet-manager.sh status
```

### Gestion des wallets
```bash
# Créer un nouveau wallet
./scripts/kaspa-wallet-manager.sh wallet create mywallet

# Lister les wallets
./scripts/kaspa-wallet-manager.sh wallet list

# Voir le solde
./scripts/kaspa-wallet-manager.sh wallet balance mywallet

# Envoyer des KAS
./scripts/kaspa-wallet-manager.sh wallet send mywallet kaspa:qz5678... 10.5
```

### Informations du nœud
```bash
# Informations générales
./scripts/kaspa-wallet-manager.sh node info

# Peers connectés
./scripts/kaspa-wallet-manager.sh node peers

# Statut de synchronisation
./scripts/kaspa-wallet-manager.sh node sync
```

### Gestion du mining
```bash
# Démarrer le mining
./scripts/kaspa-wallet-manager.sh miner start kaspa:qz1234...

# Arrêter le mining
./scripts/kaspa-wallet-manager.sh miner stop

# Statut du mining
./scripts/kaspa-wallet-manager.sh miner status
```

## 🏗️ Architecture

### Services Docker
- **kaspa-node** - Nœud Kaspa officiel (kaspad)
- **kaspa-wallet** - Wallet Kaspa officiel
- **kaspa-miner** - Miner Kaspa (optionnel)
- **postgres** - Base de données
- **redis** - Cache
- **minio** - Stockage objets
- **api** - Backend KaspaZof
- **frontend** - Interface web
- **prometheus** - Monitoring
- **grafana** - Dashboards

### Ports exposés
- **16210** - RPC Kaspa (localhost uniquement)
- **16211** - P2P Kaspa (localhost uniquement)
- **8000** - API Backend
- **8081** - Frontend web
- **3000** - Grafana
- **9090** - Prometheus

## 🔐 Sécurité

### Isolation réseau
- Réseau Docker interne `kaspa_network`
- RPC Kaspa accessible uniquement en localhost
- Pas d'exposition publique des ports sensibles

### Gestion des secrets
- Mots de passe générés automatiquement
- Fichier `.env` gitignored
- Wallets chiffrés dans le conteneur

### Utilisateur non-root
- Conteneur Kaspa utilise l'utilisateur `kaspa`
- Permissions minimales
- Volumes sécurisés

## 📊 Monitoring

### Métriques disponibles
- État du nœud Kaspa
- Synchronisation blockchain
- Performance du wallet
- Statistiques mining

### Dashboards Grafana
- Vue d'ensemble système
- Métriques Kaspa
- Performance mining
- Alertes automatiques

## 🛠️ Configuration avancée

### Variables d'environnement
```bash
# Dans .env
KASPA_RPC_PASSWORD=your_secure_password
KASPA_NETWORK=mainnet  # ou testnet
MINING_ADDRESS=kaspa:qz...
POSTGRES_PASSWORD=secure_db_password
```

### Configuration personnalisée
```bash
# Modifier la config Kaspa
vim kaspa-wallet/config/kaspa.conf

# Rebuild après modification
./scripts/kaspa-wallet-manager.sh build
./scripts/kaspa-wallet-manager.sh restart
```

## 🧪 Tests et développement

### Mode testnet
```bash
# Modifier dans .env
KASPA_NETWORK=testnet

# Redémarrer
./scripts/kaspa-wallet-manager.sh restart
```

### Commandes de debug
```bash
# Shell interactif dans le conteneur
docker exec -it kaspazof-kaspa-node bash
docker exec -it kaspazof-kaspa-wallet bash

# Logs détaillés
docker logs -f kaspazof-kaspa-node
docker logs -f kaspazof-kaspa-wallet

# Commandes kaspactl directes
docker exec kaspazof-kaspa-node kaspactl get-info
docker exec kaspazof-kaspa-node kaspactl get-block-dag-info
```

## 🔧 Dépannage

### Problèmes courants

#### Nœud ne démarre pas
```bash
# Vérifier les logs
./scripts/kaspa-wallet-manager.sh logs kaspa-node

# Vérifier l'espace disque
df -h

# Nettoyer et redémarrer
./scripts/kaspa-wallet-manager.sh clean  # ⚠️ DESTRUCTIF
./scripts/kaspa-wallet-manager.sh build
./scripts/kaspa-wallet-manager.sh start
```

#### Wallet non accessible
```bash
# Vérifier que le nœud est synchronisé
./scripts/kaspa-wallet-manager.sh node sync

# Redémarrer le wallet
docker restart kaspazof-kaspa-wallet

# Vérifier les permissions
docker exec kaspazof-kaspa-wallet ls -la /kaspa/data/wallets/
```

#### Mining ne fonctionne pas
```bash
# Vérifier l'adresse de mining
echo $MINING_ADDRESS

# Vérifier les logs du miner
docker logs kaspazof-kaspa-miner

# Redémarrer le mining
./scripts/kaspa-wallet-manager.sh miner stop
./scripts/kaspa-wallet-manager.sh miner start kaspa:qz...
```

## 📚 Ressources

### Documentation officielle
- [Kaspa.org](https://kaspa.org/)
- [Kaspa GitHub](https://github.com/kaspanet/kaspad)
- [Kaspa Wiki](https://wiki.kaspa.org/)

### Communauté
- [Discord Kaspa](https://discord.gg/kaspa)
- [Reddit r/kaspa](https://reddit.com/r/kaspa)
- [Telegram Kaspa](https://t.me/KaspaCurrency)

### Outils
- [Explorateur Kaspa](https://explorer.kaspa.org/)
- [Pools de mining](https://miningpoolstats.stream/kaspa)
- [Calculateur mining](https://minerstat.com/coin/KAS)

## ⚠️ Avertissements

### Sécurité
- **Sauvegardez vos seeds de wallet** - Perte = perte définitive des fonds
- **Utilisez des mots de passe forts** - Générés automatiquement recommandé
- **Ne partagez jamais vos clés privées** - Même avec le support

### Performance
- **Synchronisation initiale** - Peut prendre plusieurs heures
- **Espace disque** - Blockchain Kaspa ~50GB+ et croissante
- **Ressources** - Mining consomme beaucoup de CPU/GPU

### Légal
- **Vérifiez la réglementation locale** - Mining et crypto peuvent être réglementés
- **Déclaration fiscale** - Gains de mining peuvent être imposables
- **Consommation électrique** - Impact environnemental du mining

---

**Made with ❤️ for the Kaspa community**