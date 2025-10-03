# KaspaZof 🚀

Moniteur et wallet Kaspa sécurisé avec interface web moderne.

## 🏗️ Architecture

- **Frontend**: React + TypeScript + Vite + TailwindCSS
- **Backend**: FastAPI + Python 3.11
- **Base de données**: PostgreSQL 15
- **Cache**: Redis 7
- **Storage**: MinIO
- **Monitoring**: Prometheus + Grafana
- **Nœud**: Kaspa (kaspad)

## 🚀 Démarrage rapide

### Prérequis

- Docker & Docker Compose
- Node.js 18+ (pour le développement frontend)
- Git

### Installation

```bash
# 1. Cloner le repository
git clone https://github.com/BJATechnology/KaspaZof.git
cd KaspaZof

# 2. Générer les secrets de développement
./scripts/generate_dev_secrets.sh

# 3. Démarrer tous les services
./scripts/quick-start.sh
```

### Accès aux interfaces

- 🌐 **Frontend**: http://localhost:8081
- 🔧 **API**: http://localhost:8000
- 📊 **Grafana**: http://localhost:3000
- 📈 **Prometheus**: http://localhost:9090
- 💾 **MinIO**: http://localhost:9001

## 🔧 Développement

### Structure du projet

```
KaspaZof/
├── backend/           # API FastAPI
├── frontend/          # Interface React
├── monitoring/        # Configuration Prometheus/Grafana
├── scripts/          # Scripts d'automatisation
├── wallets/          # Stockage des wallets (gitignored)
├── docker-compose.yml # Services principaux
└── .env              # Configuration (gitignored)
```

### Commandes utiles

```bash
# Logs en temps réel
docker compose logs -f

# Redémarrer un service
docker compose restart api

# Arrêter tous les services
docker compose down

# Nettoyage complet (⚠️ supprime les données)
docker compose down -v
```

### Développement frontend

```bash
cd frontend
pnpm install
pnpm run dev    # Mode développement
pnpm run build  # Build production
```

### Développement backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 🔐 Sécurité

### Secrets

- ✅ Fichier `.env` généré automatiquement pour le dev
- ✅ Secrets gitignorés
- ✅ Wallets chiffrés localement
- ⚠️ **NE JAMAIS** committer de vrais secrets

### Production

Pour la production, utilisez:
- HashiCorp Vault ou gestionnaire de secrets cloud
- Certificats TLS valides
- Rotation automatique des secrets
- Monitoring de sécurité

## 📊 Monitoring

### Métriques disponibles

- État du nœud Kaspa
- Performance de l'API
- Utilisation des ressources
- Transactions wallet

### Alertes

Configurez des alertes pour:
- Nœud Kaspa hors ligne
- API indisponible
- Utilisation disque élevée
- Erreurs d'authentification

## 🧪 Tests

```bash
# Tests backend
cd backend
pytest

# Tests frontend
cd frontend
pnpm test
```

## 📚 API Documentation

Une fois l'API démarrée, consultez:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'feat: add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

### Conventions

- **Commits**: [Conventional Commits](https://conventionalcommits.org/)
- **Branches**: `feature/`, `fix/`, `chore/`, `hotfix/`
- **Code**: ESLint + Prettier (frontend), Black + isort (backend)

## 📄 Licence

MIT License - voir [LICENSE](LICENSE)

## 🆘 Support

- 📖 [Documentation](https://github.com/BJATechnology/KaspaZof/wiki)
- 🐛 [Issues](https://github.com/BJATechnology/KaspaZof/issues)
- 💬 [Discussions](https://github.com/BJATechnology/KaspaZof/discussions)

## ⚠️ Avertissements

- **Développement uniquement**: Cette version est pour le développement local
- **Pas de garantie**: Utilisez à vos propres risques
- **Sécurité**: Auditez le code avant utilisation en production
- **Conformité**: Vérifiez la réglementation locale pour le mining/crypto

---

Made with ❤️ by BJATechnology