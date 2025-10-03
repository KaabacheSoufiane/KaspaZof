-- Base de données pour le monitoring du minage Kaspa
-- Initialisation des tables

-- Table pour stocker les statistiques de minage
CREATE TABLE IF NOT EXISTS mining_stats (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    hashrate DECIMAL(20, 2) DEFAULT 0,
    difficulty DECIMAL(30, 2) DEFAULT 0,
    block_height BIGINT DEFAULT 0,
    blocks_found INTEGER DEFAULT 0,
    shares_submitted INTEGER DEFAULT 0,
    peer_count INTEGER DEFAULT 0,
    mining_address VARCHAR(255),
    miner_id VARCHAR(100)
);

-- Table pour stocker les blocs trouvés
CREATE TABLE IF NOT EXISTS blocks_found (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    block_hash VARCHAR(255) NOT NULL,
    block_height BIGINT NOT NULL,
    difficulty DECIMAL(30, 2) NOT NULL,
    reward DECIMAL(20, 8) DEFAULT 0,
    mining_address VARCHAR(255),
    miner_id VARCHAR(100)
);

-- Table pour stocker les événements de minage
CREATE TABLE IF NOT EXISTS mining_events (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    event_type VARCHAR(50) NOT NULL, -- 'start', 'stop', 'error', 'block_found'
    description TEXT,
    miner_id VARCHAR(100),
    data JSONB
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_mining_stats_timestamp ON mining_stats(timestamp);
CREATE INDEX IF NOT EXISTS idx_mining_stats_miner_id ON mining_stats(miner_id);
CREATE INDEX IF NOT EXISTS idx_blocks_found_timestamp ON blocks_found(timestamp);
CREATE INDEX IF NOT EXISTS idx_blocks_found_height ON blocks_found(block_height);
CREATE INDEX IF NOT EXISTS idx_mining_events_timestamp ON mining_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_mining_events_type ON mining_events(event_type);

-- Vue pour les statistiques récentes (dernières 24h)
CREATE OR REPLACE VIEW mining_stats_24h AS
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    AVG(hashrate) as avg_hashrate,
    MAX(hashrate) as max_hashrate,
    AVG(difficulty) as avg_difficulty,
    MAX(block_height) as max_block_height,
    SUM(blocks_found) as total_blocks_found,
    SUM(shares_submitted) as total_shares_submitted,
    AVG(peer_count) as avg_peer_count
FROM mining_stats 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;

-- Vue pour les performances par mineur
CREATE OR REPLACE VIEW miner_performance AS
SELECT 
    miner_id,
    COUNT(*) as total_records,
    AVG(hashrate) as avg_hashrate,
    MAX(hashrate) as max_hashrate,
    SUM(blocks_found) as total_blocks_found,
    SUM(shares_submitted) as total_shares_submitted,
    MIN(timestamp) as first_seen,
    MAX(timestamp) as last_seen
FROM mining_stats 
WHERE miner_id IS NOT NULL
GROUP BY miner_id;

-- Fonction pour nettoyer les anciennes données (garder 30 jours)
CREATE OR REPLACE FUNCTION cleanup_old_mining_data()
RETURNS void AS $$
BEGIN
    DELETE FROM mining_stats WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM mining_events WHERE timestamp < NOW() - INTERVAL '30 days';
    -- Garder les blocs trouvés plus longtemps (90 jours)
    DELETE FROM blocks_found WHERE timestamp < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Insérer des données de test (optionnel)
INSERT INTO mining_events (event_type, description, miner_id, data) VALUES
('start', 'Service de monitoring démarré', 'system', '{"version": "1.0.0"}');

COMMIT;