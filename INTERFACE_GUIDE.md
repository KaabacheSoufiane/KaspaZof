# 🎨 Guide de l'Interface KaspaZof

Interface graphique complète pour la gestion de wallets Kaspa, mining et suivi crypto.

## 🚀 Démarrage rapide

### Option 1: Interface seule (recommandé pour tester)
```bash
./scripts/start-frontend.sh
```

### Option 2: Écosystème complet (Frontend + Backend + Services)
```bash
./scripts/start-complete.sh
```

### Option 3: Nettoyage des ports (si problème)
```bash
./scripts/kill-ports.sh
```

## 📱 Fonctionnalités de l'interface

### 🏠 **Dashboard**
- **Vue d'ensemble système** - État des services en temps réel
- **Prix Kaspa** - Cours actuel USD/EUR avec variation 24h
- **Status nœud** - Synchronisation, blocs, peers
- **Statistiques mining** - Hashrate, shares, uptime

### 💰 **Wallet Kaspa**
- **Création sécurisée** - Wallets chiffrés avec mot de passe
- **Gestion complète** - Liste, visualisation, transactions
- **Sécurité** - Validation d'adresses, copie sécurisée
- **Interface intuitive** - SweetAlert2 pour toutes les interactions

### ⛏️ **Mining Control**
- **Configuration avancée** - Pools, solo mining, intensité
- **Monitoring temps réel** - Hashrate, shares acceptées/rejetées
- **Graphiques performance** - Évolution des performances
- **Contrôle complet** - Start/stop, sauvegarde config

### 📊 **Charts & Analytics**
- **Prix historique** - Graphiques 1D, 7D, 30D, 90D
- **Visualisation avancée** - Chart.js avec animations
- **Données temps réel** - Mise à jour automatique
- **Export** - Téléchargement des graphiques

### 📰 **Crypto News Sniffer**
- **Sources multiples** - Kaspa, crypto général, mining
- **Filtres intelligents** - Par catégorie et mots-clés
- **Auto-refresh** - Nouvelles toutes les 15 minutes
- **Partage** - Copie et partage des articles

### ℹ️ **Kaspa Information**
- **Statistiques réseau** - Blocs, peers, market cap
- **Documentation** - Informations techniques Kaspa
- **État temps réel** - Synchronisation et performance

## ⌨️ Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `Ctrl+1` | Dashboard |
| `Ctrl+2` | Wallet |
| `Ctrl+3` | Mining |
| `Ctrl+4` | Charts |
| `Ctrl+5` | News |
| `Ctrl+R` | Refresh section |

## 🔧 Configuration

### Variables d'environnement (.env)
```bash
# Généré automatiquement par generate_dev_secrets.sh
POSTGRES_PASSWORD=xxx
REDIS_URL=redis://redis:6379/0
KASPA_RPC_URL=http://kaspa:16210
MINIO_ROOT_PASSWORD=xxx
```

### Ports utilisés
- **8081** - Interface frontend
- **8000** - API backend
- **3000** - Grafana (optionnel)
- **9090** - Prometheus (optionnel)
- **16210** - Kaspa RPC

## 🛠️ Développement

### Structure des fichiers
```
frontend/
├── index.html              # Page principale
├── src/
│   ├── app.js              # Application principale
│   ├── assets/styles.css   # Styles CSS
│   ├── components/         # Composants modulaires
│   │   ├── wallet.js       # Gestion wallets
│   │   ├── mining.js       # Contrôle mining
│   │   ├── charts.js       # Graphiques
│   │   └── news.js         # Sniffeur news
│   ├── services/           # Services API
│   │   ├── api.js          # Communication backend
│   │   └── websocket.js    # Temps réel
│   └── utils/helpers.js    # Fonctions utilitaires
└── public/                 # Ressources statiques
    ├── js/                 # Librairies externes
    └── css/                # Styles externes
```

### Ajout de fonctionnalités

1. **Nouveau composant** :
   ```javascript
   // src/components/mon-composant.js
   class MonComposant {
       constructor() {
           this.init();
       }
       
       init() {
           // Initialisation
       }
   }
   ```

2. **Nouvelle section** :
   - Ajouter dans `index.html`
   - Créer le composant JS
   - Ajouter la navigation dans `app.js`

3. **Nouveau service API** :
   ```javascript
   // Dans src/services/api.js
   async monNouveauEndpoint() {
       return this.request('/mon/endpoint');
   }
   ```

## 🎨 Personnalisation

### Thème et couleurs
Modifier les variables CSS dans `src/assets/styles.css` :
```css
:root {
    --primary-color: #2563eb;    /* Bleu principal */
    --success-color: #10b981;    /* Vert succès */
    --warning-color: #f59e0b;    /* Orange warning */
    --danger-color: #ef4444;     /* Rouge danger */
}
```

### SweetAlert2 personnalisé
```javascript
Swal.fire({
    title: 'Mon titre',
    text: 'Mon message',
    icon: 'success',
    customClass: {
        popup: 'ma-classe-custom'
    }
});
```

## 🔐 Sécurité

### Bonnes pratiques implémentées
- ✅ **Validation côté client** - Toutes les entrées validées
- ✅ **Pas de secrets exposés** - Aucun secret dans le code frontend
- ✅ **HTTPS ready** - Configuration pour TLS
- ✅ **CSP headers** - Protection XSS (à configurer côté serveur)

### Wallets sécurisés
- Mots de passe minimum 8 caractères
- Chiffrement côté backend
- Validation format adresses Kaspa
- Pas de stockage local des clés privées

## 🐛 Dépannage

### Interface ne se charge pas
```bash
# Vérifier les ports
./scripts/kill-ports.sh
./scripts/start-frontend.sh
```

### Erreurs API
```bash
# Vérifier les logs backend
docker compose logs api
# ou
tail -f backend/logs/app.log
```

### Problèmes WebSocket
- Vérifier que le backend supporte WebSocket
- Contrôler la configuration CORS
- Tester la connectivité réseau

### Mining ne démarre pas
- Vérifier la configuration du pool
- Contrôler l'adresse wallet
- Vérifier les permissions système

## 📚 Ressources

### Documentation Kaspa
- [Site officiel](https://kaspa.org/)
- [Documentation développeur](https://wiki.kaspa.org/)
- [GitHub Kaspa](https://github.com/kaspanet/kaspad)

### Librairies utilisées
- [SweetAlert2](https://sweetalert2.github.io/) - Modales et alertes
- [Chart.js](https://www.chartjs.org/) - Graphiques
- [Font Awesome](https://fontawesome.com/) - Icônes

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature
3. Tester l'interface complètement
4. Soumettre une Pull Request

---

**Made with ❤️ for the Kaspa community**