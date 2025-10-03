// Main Application Controller
class KaspaZofApp {
    constructor() {
        this.currentSection = 'dashboard';
        this.refreshInterval = null;
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupEventListeners();
        this.loadDashboard();
        this.startAutoRefresh();
        
        // Initialize WebSocket connection
        wsService.connect();
        this.setupWebSocketListeners();
    }

    setupNavigation() {
        const navLinks = document.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const section = link.dataset.section;
                this.showSection(section);
            });
        });
    }

    setupEventListeners() {
        // Global keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case '1':
                        e.preventDefault();
                        this.showSection('dashboard');
                        break;
                    case '2':
                        e.preventDefault();
                        this.showSection('wallet');
                        break;
                    case '3':
                        e.preventDefault();
                        this.showSection('mining');
                        break;
                    case '4':
                        e.preventDefault();
                        this.showSection('charts');
                        break;
                    case '5':
                        e.preventDefault();
                        this.showSection('news');
                        break;
                    case 'r':
                        e.preventDefault();
                        this.refreshCurrentSection();
                        break;
                }
            }
        });

        // Handle window resize for responsive charts
        window.addEventListener('resize', () => {
            if (chartsManager && chartsManager.priceChart) {
                chartsManager.priceChart.resize();
            }
            if (miningManager && miningManager.chart) {
                miningManager.chart.resize();
            }
        });

        // Handle visibility change to pause/resume updates
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.pauseUpdates();
            } else {
                this.resumeUpdates();
            }
        });
    }

    setupWebSocketListeners() {
        // Listen for real-time price updates
        wsService.subscribe('price_update', (data) => {
            this.handlePriceUpdate(data);
        });

        // Listen for node status updates
        wsService.subscribe('node_status', (data) => {
            this.handleNodeStatusUpdate(data);
        });

        // Listen for mining updates
        wsService.subscribe('mining_update', (data) => {
            this.handleMiningUpdate(data);
        });
    }

    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.remove('active');
        });

        // Show target section
        const targetSection = document.getElementById(sectionName);
        if (targetSection) {
            targetSection.classList.add('active');
        }

        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[data-section="${sectionName}"]`).classList.add('active');

        this.currentSection = sectionName;

        // Load section-specific data
        this.loadSectionData(sectionName);
    }

    async loadSectionData(sectionName) {
        switch (sectionName) {
            case 'dashboard':
                await this.loadDashboard();
                break;
            case 'wallet':
                if (walletManager) {
                    await walletManager.loadWallets();
                }
                break;
            case 'mining':
                // Mining data is loaded automatically by MiningManager
                break;
            case 'charts':
                if (chartsManager) {
                    await chartsManager.loadPriceData();
                }
                break;
            case 'news':
                if (newsManager) {
                    await newsManager.loadNews();
                }
                break;
            case 'kaspa-info':
                await this.loadKaspaInfo();
                break;
        }
    }

    async loadDashboard() {
        try {
            // Load all dashboard components in parallel
            const promises = [
                this.loadSystemStatus(),
                this.loadPriceInfo(),
                this.loadNodeStatus(),
                this.loadMiningStats()
            ];

            await Promise.allSettled(promises);
        } catch (error) {
            console.error('Failed to load dashboard:', error);
        }
    }

    async loadSystemStatus() {
        try {
            const response = await api.getSystemInfo();
            const container = document.getElementById('system-status');
            
            if (response.success && response.data) {
                const services = response.data.services;
                const servicesHTML = services.map(service => `
                    <div class="status-item">
                        <div class="status-label">${service.name}</div>
                        <div class="status-value ${service.status ? 'success' : 'danger'}">
                            <i class="fas fa-${service.status ? 'check-circle' : 'times-circle'}"></i>
                            ${service.status ? 'Online' : 'Offline'}
                        </div>
                    </div>
                `).join('');

                container.innerHTML = `
                    <div class="system-overview">
                        <div class="status-item">
                            <div class="status-label">Environment</div>
                            <div class="status-value">${response.data.environment}</div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Version</div>
                            <div class="status-value">${response.data.version}</div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Uptime</div>
                            <div class="status-value">${this.formatUptime(response.data.uptime)}</div>
                        </div>
                    </div>
                    <div class="services-status">
                        <h4>Services Status</h4>
                        ${servicesHTML}
                    </div>
                `;
            }
        } catch (error) {
            document.getElementById('system-status').innerHTML = 
                '<div class="error">Failed to load system status</div>';
        }
    }

    async loadPriceInfo() {
        try {
            const response = await api.getCurrentPrice();
            const container = document.getElementById('price-info');
            
            if (response.success && response.data) {
                const price = response.data;
                const changeClass = price.change_24h >= 0 ? 'positive' : 'negative';
                const changeIcon = price.change_24h >= 0 ? 'fa-arrow-up' : 'fa-arrow-down';

                container.innerHTML = `
                    <div class="price-display">
                        <div class="price-main">$${price.kaspa_usd.toFixed(6)}</div>
                        <div class="price-secondary">€${price.kaspa_eur.toFixed(6)}</div>
                        <div class="price-change ${changeClass}">
                            <i class="fas ${changeIcon}"></i>
                            ${price.change_24h >= 0 ? '+' : ''}${price.change_24h.toFixed(2)}%
                        </div>
                        <div class="price-updated">
                            Updated: ${this.formatTime(price.last_updated)}
                        </div>
                    </div>
                `;
            }
        } catch (error) {
            document.getElementById('price-info').innerHTML = 
                '<div class="error">Failed to load price data</div>';
        }
    }

    async loadNodeStatus() {
        try {
            const response = await api.getNodeStatus();
            const container = document.getElementById('node-status');
            
            if (response.success && response.data) {
                const node = response.data;
                const syncClass = node.is_synced ? 'success' : 'warning';

                container.innerHTML = `
                    <div class="node-overview">
                        <div class="status-item">
                            <div class="status-label">Sync Status</div>
                            <div class="status-value ${syncClass}">
                                <i class="fas fa-${node.is_synced ? 'check-circle' : 'sync-alt'}"></i>
                                ${node.is_synced ? 'Synced' : 'Syncing'}
                            </div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Block Count</div>
                            <div class="status-value">${node.block_count.toLocaleString()}</div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Peers</div>
                            <div class="status-value">${node.peer_count}</div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Network</div>
                            <div class="status-value">${node.network}</div>
                        </div>
                        <div class="status-item">
                            <div class="status-label">Version</div>
                            <div class="status-value">${node.version}</div>
                        </div>
                        ${node.sync_progress ? `
                        <div class="status-item">
                            <div class="status-label">Sync Progress</div>
                            <div class="status-value">${node.sync_progress.toFixed(1)}%</div>
                        </div>
                        ` : ''}
                    </div>
                `;
            }
        } catch (error) {
            document.getElementById('node-status').innerHTML = 
                '<div class="error">Failed to load node status</div>';
        }
    }

    async loadMiningStats() {
        const container = document.getElementById('mining-stats');
        
        if (miningManager && miningManager.isMining) {
            const stats = miningManager.miningStats;
            container.innerHTML = `
                <div class="mining-overview">
                    <div class="status-item">
                        <div class="status-label">Status</div>
                        <div class="status-value success">
                            <i class="fas fa-play-circle"></i>
                            Mining
                        </div>
                    </div>
                    <div class="status-item">
                        <div class="status-label">Hashrate</div>
                        <div class="status-value">${stats.hashrate.toFixed(2)} H/s</div>
                    </div>
                    <div class="status-item">
                        <div class="status-label">Shares</div>
                        <div class="status-value">${stats.shares}</div>
                    </div>
                    <div class="status-item">
                        <div class="status-label">Uptime</div>
                        <div class="status-value">${this.formatMiningUptime(stats.uptime)}</div>
                    </div>
                </div>
            `;
        } else {
            container.innerHTML = `
                <div class="mining-stopped">
                    <i class="fas fa-pause-circle" style="font-size: 2rem; color: var(--secondary-color); margin-bottom: 1rem;"></i>
                    <h4>Mining Stopped</h4>
                    <p>Start mining to see statistics here</p>
                    <button class="btn btn-success" onclick="toggleMining()">
                        <i class="fas fa-play"></i> Start Mining
                    </button>
                </div>
            `;
        }
    }

    async loadKaspaInfo() {
        const container = document.getElementById('network-stats');
        
        try {
            const nodeResponse = await api.getNodeStatus();
            const priceResponse = await api.getCurrentPrice();
            
            if (nodeResponse.success && priceResponse.success) {
                const node = nodeResponse.data;
                const price = priceResponse.data;
                
                container.innerHTML = `
                    <div class="kaspa-stats">
                        <div class="stat-item">
                            <div class="stat-label">Current Price</div>
                            <div class="stat-value">$${price.kaspa_usd.toFixed(6)}</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-label">Market Cap</div>
                            <div class="stat-value">${price.market_cap ? '$' + (price.market_cap / 1000000).toFixed(2) + 'M' : 'N/A'}</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-label">24h Volume</div>
                            <div class="stat-value">${price.volume_24h ? '$' + (price.volume_24h / 1000000).toFixed(2) + 'M' : 'N/A'}</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-label">Block Height</div>
                            <div class="stat-value">${node.block_count.toLocaleString()}</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-label">Network</div>
                            <div class="stat-value">${node.network}</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-label">Active Peers</div>
                            <div class="stat-value">${node.peer_count}</div>
                        </div>
                    </div>
                `;
            }
        } catch (error) {
            container.innerHTML = '<div class="error">Failed to load network statistics</div>';
        }
    }

    // WebSocket event handlers
    handlePriceUpdate(data) {
        if (this.currentSection === 'dashboard') {
            // Update price display in real-time
            this.updatePriceDisplay(data);
        }
    }

    handleNodeStatusUpdate(data) {
        if (this.currentSection === 'dashboard') {
            // Update node status in real-time
            this.updateNodeStatusDisplay(data);
        }
    }

    handleMiningUpdate(data) {
        if (miningManager) {
            miningManager.miningStats = { ...miningManager.miningStats, ...data };
            if (this.currentSection === 'dashboard') {
                this.loadMiningStats();
            }
        }
    }

    // Utility functions
    formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        
        if (days > 0) {
            return `${days}d ${hours}h ${minutes}m`;
        } else if (hours > 0) {
            return `${hours}h ${minutes}m`;
        } else {
            return `${minutes}m`;
        }
    }

    formatMiningUptime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    formatTime(dateString) {
        return new Date(dateString).toLocaleTimeString();
    }

    refreshCurrentSection() {
        this.loadSectionData(this.currentSection);
        
        Swal.fire({
            title: 'Refreshed!',
            text: `${this.currentSection} data has been updated`,
            icon: 'success',
            timer: 1500,
            showConfirmButton: false
        });
    }

    startAutoRefresh() {
        // Refresh dashboard data every 30 seconds
        this.refreshInterval = setInterval(() => {
            if (this.currentSection === 'dashboard' && !document.hidden) {
                this.loadDashboard();
            }
        }, 30000);
    }

    pauseUpdates() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    resumeUpdates() {
        this.startAutoRefresh();
    }
}

// Global functions
function refreshDashboard() {
    if (window.kaspazofApp) {
        window.kaspazofApp.loadDashboard();
    }
}

// Initialize application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.kaspazofApp = new KaspaZofApp();
    
    // Show welcome message
    setTimeout(() => {
        Swal.fire({
            title: 'Welcome to KaspaZof!',
            text: 'Your complete Kaspa mining and wallet platform',
            icon: 'success',
            timer: 3000,
            showConfirmButton: false
        });
    }, 1000);
});