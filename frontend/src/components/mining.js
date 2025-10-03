// Mining Control Component
class MiningManager {
    constructor() {
        this.isMining = false;
        this.miningStats = {
            hashrate: 0,
            shares: 0,
            accepted: 0,
            rejected: 0,
            uptime: 0
        };
        this.chart = null;
        this.init();
    }

    init() {
        this.loadMiningConfig();
        this.initMiningChart();
        this.startStatsUpdate();
    }

    loadMiningConfig() {
        const configContainer = document.getElementById('mining-config');
        
        configContainer.innerHTML = `
            <div class="mining-controls">
                <div class="control-group">
                    <label for="mining-pool">Mining Pool</label>
                    <select id="mining-pool">
                        <option value="solo">Solo Mining</option>
                        <option value="pool1">KaspaPool.org</option>
                        <option value="pool2">Woolypooly</option>
                        <option value="pool3">2Miners</option>
                    </select>
                </div>
                
                <div class="control-group">
                    <label for="mining-wallet">Wallet Address</label>
                    <input type="text" id="mining-wallet" placeholder="kaspa:..." value="${this.getMiningWallet()}">
                </div>
                
                <div class="control-group">
                    <label for="mining-threads">CPU Threads</label>
                    <input type="number" id="mining-threads" min="1" max="16" value="4">
                </div>
                
                <div class="control-group">
                    <label for="mining-intensity">Intensity</label>
                    <select id="mining-intensity">
                        <option value="low">Low</option>
                        <option value="medium" selected>Medium</option>
                        <option value="high">High</option>
                    </select>
                </div>
            </div>
            
            <div class="mining-status">
                <div class="status-grid">
                    <div class="status-item">
                        <div class="status-label">Status</div>
                        <div class="status-value" id="mining-status">
                            <span class="status-badge stopped">Stopped</span>
                        </div>
                    </div>
                    
                    <div class="status-item">
                        <div class="status-label">Hashrate</div>
                        <div class="status-value" id="hashrate-display">0 H/s</div>
                    </div>
                    
                    <div class="status-item">
                        <div class="status-label">Shares</div>
                        <div class="status-value" id="shares-display">0</div>
                    </div>
                    
                    <div class="status-item">
                        <div class="status-label">Accepted</div>
                        <div class="status-value success" id="accepted-display">0</div>
                    </div>
                    
                    <div class="status-item">
                        <div class="status-label">Rejected</div>
                        <div class="status-value danger" id="rejected-display">0</div>
                    </div>
                    
                    <div class="status-item">
                        <div class="status-label">Uptime</div>
                        <div class="status-value" id="uptime-display">00:00:00</div>
                    </div>
                </div>
            </div>
            
            <div class="mining-actions">
                <button class="btn btn-success" id="start-mining-btn" onclick="miningManager.startMining()">
                    <i class="fas fa-play"></i> Start Mining
                </button>
                <button class="btn btn-danger" id="stop-mining-btn" onclick="miningManager.stopMining()" style="display: none;">
                    <i class="fas fa-stop"></i> Stop Mining
                </button>
                <button class="btn btn-primary" onclick="miningManager.saveMiningConfig()">
                    <i class="fas fa-save"></i> Save Config
                </button>
            </div>
        `;
    }

    initMiningChart() {
        const ctx = document.getElementById('mining-chart');
        if (!ctx) return;

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Hashrate (H/s)',
                    data: [],
                    borderColor: 'rgb(37, 99, 235)',
                    backgroundColor: 'rgba(37, 99, 235, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Hashrate (H/s)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    }
                }
            }
        });
    }

    async startMining() {
        const config = this.getMiningConfig();
        
        if (!config.wallet) {
            Swal.fire({
                title: 'Missing Wallet',
                text: 'Please enter a valid Kaspa wallet address',
                icon: 'warning'
            });
            return;
        }

        const result = await Swal.fire({
            title: 'Start Mining?',
            html: `
                <div class="mining-confirm">
                    <p>Are you sure you want to start mining with the following configuration?</p>
                    <div class="config-summary">
                        <div><strong>Pool:</strong> ${config.pool}</div>
                        <div><strong>Wallet:</strong> ${this.formatAddress(config.wallet)}</div>
                        <div><strong>Threads:</strong> ${config.threads}</div>
                        <div><strong>Intensity:</strong> ${config.intensity}</div>
                    </div>
                    <div class="warning-notice">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Mining will use significant CPU resources and may affect system performance.</p>
                    </div>
                </div>
            `,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Start Mining',
            cancelButtonText: 'Cancel'
        });

        if (result.isConfirmed) {
            try {
                // TODO: Implement actual mining start
                this.isMining = true;
                this.updateMiningUI();
                this.simulateMining();
                
                Swal.fire({
                    title: 'Mining Started!',
                    text: 'Your mining operation has begun successfully.',
                    icon: 'success',
                    timer: 3000,
                    showConfirmButton: false
                });
            } catch (error) {
                Swal.fire({
                    title: 'Mining Error',
                    text: 'Failed to start mining. Please check your configuration.',
                    icon: 'error'
                });
            }
        }
    }

    async stopMining() {
        const result = await Swal.fire({
            title: 'Stop Mining?',
            text: 'Are you sure you want to stop the mining operation?',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Stop Mining',
            cancelButtonText: 'Continue Mining'
        });

        if (result.isConfirmed) {
            this.isMining = false;
            this.updateMiningUI();
            
            Swal.fire({
                title: 'Mining Stopped',
                text: 'Mining operation has been stopped successfully.',
                icon: 'info',
                timer: 2000,
                showConfirmButton: false
            });
        }
    }

    getMiningConfig() {
        return {
            pool: document.getElementById('mining-pool')?.value || 'solo',
            wallet: document.getElementById('mining-wallet')?.value || '',
            threads: parseInt(document.getElementById('mining-threads')?.value) || 4,
            intensity: document.getElementById('mining-intensity')?.value || 'medium'
        };
    }

    getMiningWallet() {
        // Get first wallet address if available
        if (walletManager && walletManager.wallets.length > 0) {
            return walletManager.wallets[0].address;
        }
        return '';
    }

    saveMiningConfig() {
        const config = this.getMiningConfig();
        localStorage.setItem('mining-config', JSON.stringify(config));
        
        Swal.fire({
            title: 'Configuration Saved',
            text: 'Mining configuration has been saved successfully.',
            icon: 'success',
            timer: 2000,
            showConfirmButton: false
        });
    }

    updateMiningUI() {
        const statusElement = document.getElementById('mining-status');
        const startBtn = document.getElementById('start-mining-btn');
        const stopBtn = document.getElementById('stop-mining-btn');

        if (this.isMining) {
            statusElement.innerHTML = '<span class="status-badge running">Running</span>';
            startBtn.style.display = 'none';
            stopBtn.style.display = 'inline-flex';
        } else {
            statusElement.innerHTML = '<span class="status-badge stopped">Stopped</span>';
            startBtn.style.display = 'inline-flex';
            stopBtn.style.display = 'none';
        }
    }

    simulateMining() {
        if (!this.isMining) return;

        // Simulate mining stats
        this.miningStats.hashrate = Math.random() * 1000 + 500;
        this.miningStats.shares += Math.random() > 0.7 ? 1 : 0;
        this.miningStats.accepted += Math.random() > 0.9 ? 1 : 0;
        this.miningStats.rejected += Math.random() > 0.95 ? 1 : 0;
        this.miningStats.uptime += 1;

        this.updateMiningStats();
        this.updateMiningChart();

        setTimeout(() => this.simulateMining(), 2000);
    }

    updateMiningStats() {
        document.getElementById('hashrate-display').textContent = 
            `${this.miningStats.hashrate.toFixed(2)} H/s`;
        document.getElementById('shares-display').textContent = 
            this.miningStats.shares.toString();
        document.getElementById('accepted-display').textContent = 
            this.miningStats.accepted.toString();
        document.getElementById('rejected-display').textContent = 
            this.miningStats.rejected.toString();
        document.getElementById('uptime-display').textContent = 
            this.formatUptime(this.miningStats.uptime);
    }

    updateMiningChart() {
        if (!this.chart) return;

        const now = new Date().toLocaleTimeString();
        this.chart.data.labels.push(now);
        this.chart.data.datasets[0].data.push(this.miningStats.hashrate);

        // Keep only last 20 data points
        if (this.chart.data.labels.length > 20) {
            this.chart.data.labels.shift();
            this.chart.data.datasets[0].data.shift();
        }

        this.chart.update('none');
    }

    formatUptime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    formatAddress(address) {
        if (address.length > 20) {
            return `${address.substring(0, 10)}...${address.substring(address.length - 10)}`;
        }
        return address;
    }

    startStatsUpdate() {
        // Update mining stats display every 5 seconds
        setInterval(() => {
            if (this.isMining) {
                this.updateMiningStats();
            }
        }, 5000);
    }
}

// Global mining manager instance
const miningManager = new MiningManager();

// Global function for toggle mining (used by main nav button)
function toggleMining() {
    if (miningManager.isMining) {
        miningManager.stopMining();
    } else {
        miningManager.startMining();
    }
}