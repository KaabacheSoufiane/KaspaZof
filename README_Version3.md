```markdown
# KaspaZof — Moniteur Kaspa local (dev/test)

But
----
KaspaZof est un moniteur local léger pour Kaspa : wallet sécurisé local, graphiques KAS vs USD/EUR/BTC, statut du nœud et outils d'administration. Conçu pour usage local et tests seulement.

Structure
---------
- backend/        FastAPI API (http://localhost:8000)
- frontend/       UI statique (http://localhost:8081)
- docker-compose.yml  Orchestration (Postgres, Redis, MinIO, kaspa placeholder, api, frontend)
- .env.example    Variables d'environnement (dev)
- scripts/        utilitaires (generate_dev_secrets.sh, quick-start.sh)

Important (sécurité)
--------------------
- Ce dépôt est pour tests **locaux uniquement**. Ne publiez pas .env ni les seeds du wallet.
- Par défaut les secrets peuvent être en clair pour un usage local, mais ne les committez jamais.
```