// API Service for KaspaZof
class ApiService {
    constructor() {
        this.baseURL = 'http://localhost:8000/api/v1';
        this.timeout = 10000;
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        };

        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), this.timeout);
            
            const response = await fetch(url, {
                ...config,
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error(`API Error [${endpoint}]:`, error);
            throw error;
        }
    }

    // System endpoints
    async getSystemInfo() {
        return this.request('/system/info');
    }

    async getHealthCheck() {
        return this.request('/system/health');
    }

    async getCacheStats() {
        return this.request('/system/cache/stats');
    }

    // Price endpoints
    async getCurrentPrice() {
        return this.request('/prices/current');
    }

    async getPriceHistory(days = 7) {
        return this.request(`/prices/history?days=${days}`);
    }

    // Node endpoints
    async getNodeStatus() {
        return this.request('/node/status');
    }

    async getBlockInfo(blockHash = null) {
        const endpoint = blockHash ? `/node/block?block_hash=${blockHash}` : '/node/block';
        return this.request(endpoint);
    }

    // Wallet endpoints
    async getWallets() {
        return this.request('/wallets/');
    }

    async createWallet(walletData) {
        return this.request('/wallets/create', {
            method: 'POST',
            body: JSON.stringify(walletData)
        });
    }

    async getWallet(walletId) {
        return this.request(`/wallets/${walletId}`);
    }
}

// Global API instance
const api = new ApiService();