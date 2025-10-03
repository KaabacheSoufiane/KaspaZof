# 🚀 Guide de Minage Kaspa - KaspaZof

Guide complet pour configurer et utiliser le système de minage Kaspa intégré à KaspaZof.

## 📋 Prérequis

### Matériel recommandé
- **CPU**: 4+ cœurs (Intel/AMD récent)
- **RAM**: 8GB minimum, 16GB recommandé
- **Stockage**: 100GB+ SSD libre
- **Réseau**: Connexion stable (10+ Mbps)

### Logiciels
- Docker & Docker Compose
- Git
- 4GB+ RAM disponible pour les conteneurs

## 🚀 Installation rapide

### 1. Cloner et configurer
```bash
git clone https://github.com/BJATechnology/KaspaZof.git
cd KaspaZof

# Générer la configuration
./scripts/generate_dev_secrets.sh
```

### 2. Configurer l'adresse de minage
```bash
# Éditer le fichier .env
nano .env

# Modifier cette ligne avec votre adresse Kaspa:
MINING_ADDRESS=kaspa:votre_adresse_kaspa_ici
```

### 3. Démarrer le minage
```bash
# Démarrage complet avec minage
./scripts/start-mining.sh

# Ou avec une adresse spécifique
./scripts/start-mining.sh kaspa:votre_adresse_kaspa
```

## 🎛️ Gestion du minage

### Commandes principales
```bash
# Gestionnaire de minage
./scripts/mining-manager.sh

# Démarrer le minage
./scripts/mining-manager.sh start

# Arrêter le minage
./scripts/mining-manager.sh stop

# Statut des services
./scripts/mining-manager.sh status

# Voir les logs du mineur
./scripts/mining-manager.sh logs

# Statistiques de minage
./scripts/mining-manager.sh stats

# Minage multi-instances
./scripts/mining-manager.sh multi
```

### Surveillance en temps réel
```bash
# Logs du mineur principal
docker compose -f docker-compose-mining.yml logs -f kaspa-miner-1

# Logs du nœud Kaspa
docker compose -f docker-compose-mining.yml logs -f kaspa-node

# Statistiques via API
curl http://localhost:8080/stats | jq
```

## 📊 Interfaces de monitoring

### Dashboards disponibles
- **Frontend KaspaZof**: http://localhost:8081
- **API Documentation**: http://localhost:8000/docs
- **Grafana**: http://localhost:3000 (admin/[mot_de_passe_généré])
- **Prometheus**: http://localhost:9090
- **Mining Monitor**: http://localhost:8080

### Métriques surveillées
- Hashrate en temps réel
- Difficulté du réseau
- Blocs trouvés
- Shares soumises
- Statut du nœud
- Nombre de peers
- Temps de fonctionnement

## ⚙️ Configuration avancée

### Minage multi-instances
```bash
# Démarrer plusieurs mineurs
./scripts/mining-manager.sh multi

# Ou manuellement
docker compose -f docker-compose-mining.yml --profile multi-mining up -d
```

### Optimisation des performances
```yaml
# Dans docker-compose-mining.yml
deploy:
  resources:
    limits:
      cpus: '4.0'      # Ajuster selon votre CPU
      memory: 2G       # Ajuster selon votre RAM
```

### Variables d'environnement importantes
```bash
# Dans .env
MINING_ADDRESS=kaspa:votre_adresse     # Obligatoire
MINERS_COUNT=2                         # Nombre de mineurs
KASPA_NETWORK=mainnet                  # Réseau (mainnet/testnet)
KASPA_LOG_LEVEL=info                   # Niveau de logs
```

## 🔧 Dépannage

### Problèmes courants

#### Le nœud ne se synchronise pas
```bash
# Vérifier les logs
docker compose -f docker-compose-mining.yml logs kaspa-node

# Redémarrer le nœud
docker compose -f docker-compose-mining.yml restart kaspa-node
```

#### Hashrate faible ou nul
```bash
# Vérifier la configuration du mineur
docker compose -f docker-compose-mining.yml logs kaspa-miner-1

# Vérifier l'adresse de minage
echo $MINING_ADDRESS
```

#### Services inaccessibles
```bash
# Vérifier les ports
netstat -tlnp | grep -E "(8000|8080|8081|3000|9090)"

# Redémarrer tous les services
docker compose -f docker-compose-mining.yml restart
```

### Commandes de diagnostic
```bash
# Statut complet du système
./scripts/mining-manager.sh status

# Informations du nœud Kaspa
docker exec kaspazof-kaspa-node kaspactl --rpcserver=localhost:16210 get-info

# Test de connectivité RPC
curl -u kaspa:password http://localhost:16210 -d '{"method":"getInfo","params":[],"id":1}'
```

## 📈 Optimisation des performances

### Configuration CPU
- Allouer 50-70% des cœurs CPU au minage
- Laisser des ressources pour le système et le nœud
- Surveiller la température CPU

### Configuration mémoire
- Minimum 2GB par instance de mineur
- 4GB pour le nœud Kaspa
- Surveiller l'utilisation swap

### Configuration réseau
- Connexion stable requise
- Ouvrir les ports si nécessaire (16211 pour P2P)
- Surveiller la latence réseau

## 🔐 Sécurité

### Bonnes pratiques
- ✅ Utiliser une adresse de minage dédiée
- ✅ Surveiller les logs régulièrement
- ✅ Sauvegarder la configuration
- ✅ Mettre à jour régulièrement
- ❌ Ne jamais exposer les ports RPC publiquement
- ❌ Ne jamais partager les clés privées

### Monitoring de sécurité
- Alertes sur les déconnexions
- Surveillance des performances anormales
- Logs d'accès et d'erreurs
- Métriques de sécurité

## 📊 Métriques et KPIs

### Métriques clés à surveiller
- **Hashrate**: Performance de minage
- **Uptime**: Disponibilité du système
- **Blocks Found**: Blocs découverts
- **Network Difficulty**: Difficulté du réseau
- **Peer Count**: Connectivité réseau

### Alertes recommandées
- Hashrate < 1 MH/s
- Nœud déconnecté > 2 minutes
- Aucun bloc trouvé > 6 heures
- Peers < 3 connectés
- Utilisation CPU > 90%

## 🆘 Support et ressources

### Documentation
- [Kaspa Official Docs](https://kaspa.org)
- [Docker Documentation](https://docs.docker.com)
- [Prometheus Monitoring](https://prometheus.io/docs)

### Communauté
- [Kaspa Discord](https://discord.gg/kaspa)
- [GitHub Issues](https://github.com/BJATechnology/KaspaZof/issues)

### Logs utiles
```bash
# Tous les logs
docker compose -f docker-compose-mining.yml logs

# Logs spécifiques
docker compose -f docker-compose-mining.yml logs kaspa-miner-1
docker compose -f docker-compose-mining.yml logs kaspa-node
docker compose -f docker-compose-mining.yml logs mining-monitor
```

---

## ⚠️ Avertissements importants

- **Développement**: Cette configuration est optimisée pour le développement local
- **Production**: Auditez et sécurisez avant utilisation en production
- **Électricité**: Le minage consomme de l'électricité, calculez la rentabilité
- **Réglementation**: Vérifiez la légalité du minage dans votre juridiction
- **Risques**: Le minage de cryptomonnaies comporte des risques financiers

---

Made with ❤️ by BJATechnology