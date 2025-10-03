# Dockerfile pour Kaspa Wallet officiel
FROM ubuntu:22.04

# Métadonnées
LABEL maintainer="BJATechnology"
LABEL description="Kaspa Wallet officiel v0.12.22 dans un conteneur Docker"
LABEL version="0.12.22"

# Variables d'environnement
ENV KASPA_HOME=/kaspa
ENV KASPA_DATA_DIR=/kaspa/data
ENV KASPA_CONFIG_DIR=/kaspa/config
ENV PATH="/kaspa/bin:${PATH}"

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Créer l'utilisateur kaspa (sécurité)
RUN groupadd -r kaspa && useradd -r -g kaspa -d /kaspa -s /bin/bash kaspa

# Créer les dossiers nécessaires
RUN mkdir -p /kaspa/{bin,config,data,logs} \
    && chown -R kaspa:kaspa /kaspa

# Copier les binaires Kaspa
COPY bin/* /kaspa/bin/
RUN chmod +x /kaspa/bin/*

# Copier les fichiers de configuration
COPY config/ /kaspa/config/

# Créer le script d'entrée
COPY docker-entrypoint.sh /kaspa/
RUN chmod +x /kaspa/docker-entrypoint.sh

# Exposer les ports
EXPOSE 16210 16211 8080

# Volumes pour persistance des données
VOLUME ["/kaspa/data", "/kaspa/config"]

# Changer vers l'utilisateur kaspa
USER kaspa
WORKDIR /kaspa

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD kaspactl --rpcserver=localhost:16210 get-info || exit 1

# Point d'entrée
ENTRYPOINT ["/kaspa/docker-entrypoint.sh"]
CMD ["wallet"]