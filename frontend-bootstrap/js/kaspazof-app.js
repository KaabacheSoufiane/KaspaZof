// KaspaZof Application - Bootstrap 5 Version
class KaspaZofApp {
    constructor() {
        this.currentSection = 'dashboard';
        this.isMining = false;
        this.charts = {};
        this.init();
    }

    init() {
        this.initCharts();
        this.loadDashboardData();
        this.startAutoRefresh();
    }

    // Navigation
    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show target section
        const targetSection = document.getElementById(`${sectionName}-section`);
        if (targetSection) {
            targetSection.style.display = 'block';
        }

        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        event.target.classList.add('active');

        this.currentSection = sectionName;
        this.loadSectionData(sectionName);
    }

    // Initialize Charts
    initCharts() {
        // Main price chart
        const mainCtx = document.getElementById('main-chart');
        if (mainCtx) {
            this.charts.main = new Chart(mainCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Prix Kaspa (USD)',
                        data: [],
                        borderColor: '#2563eb',
                        backgroundColor: 'rgba(37, 99, 235, 0.1)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: { beginAtZero: false }
                    }
                }
            });
        }

        // Mining chart
        const miningCtx = document.getElementById('mining-chart');
        if (miningCtx) {
            this.charts.mining = new Chart(miningCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Hashrate (H/s)',
                        data: [],
                        borderColor: '#10b981',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        }
    }

    // Load section data
    async loadSectionData(sectionName) {
        switch (sectionName) {
            case 'dashboard':
                await this.loadDashboardData();
                break;
            case 'wallet':
                await this.loadWallets();
                break;
            case 'mining':
                this.loadMiningConfig();
                break;
            case 'charts':
                this.updatePriceChart();
                break;
            case 'news':
                await this.loadNews();
                break;
        }
    }

    // Dashboard data
    async loadDashboardData() {
        try {
            // Simulate API calls
            await this.updatePrice();
            await this.updateNodeStatus();
            await this.updateMiningStats();
            await this.updateWalletBalance();
            this.updateMainChart();
        } catch (error) {
            console.error('Error loading dashboard:', error);
        }
    }

    async updatePrice() {
        // Simulate price data
        const price = (Math.random() * 0.05 + 0.02).toFixed(6);
        document.getElementById('kaspa-price').textContent = `$${price}`;
    }

    async updateNodeStatus() {
        const blocks = Math.floor(Math.random() * 1000000 + 500000);
        document.getElementById('node-blocks').textContent = blocks.toLocaleString();
    }

    async updateMiningStats() {
        if (this.isMining) {
            const hashrate = (Math.random() * 1000 + 500).toFixed(2);
            document.getElementById('mining-hashrate').textContent = `${hashrate} H/s`;
        } else {
            document.getElementById('mining-hashrate').textContent = '0 H/s';
        }
    }

    async updateWalletBalance() {
        const balance = (Math.random() * 100).toFixed(2);
        document.getElementById('wallet-balance').textContent = `${balance} KAS`;
    }

    updateMainChart() {
        if (!this.charts.main) return;

        const now = new Date();
        const labels = [];
        const data = [];

        for (let i = 23; i >= 0; i--) {
            const time = new Date(now.getTime() - i * 60 * 60 * 1000);
            labels.push(time.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }));
            data.push((Math.random() * 0.01 + 0.02).toFixed(6));
        }

        this.charts.main.data.labels = labels;
        this.charts.main.data.datasets[0].data = data;
        this.charts.main.update();
    }

    // Wallet functions
    async loadWallets() {
        const container = document.getElementById('wallet-list');
        // Simulate empty wallet list
        container.innerHTML = `
            <div class="text-center py-5">
                <i class="display-4 text-muted">💰</i>
                <h5 class="mt-3">Aucun wallet trouvé</h5>
                <p class="text-muted">Créez votre premier wallet Kaspa pour commencer</p>
                <button class="btn btn-primary" onclick="app.createWallet()">Créer Wallet</button>
            </div>
        `;
    }

    async createWallet() {
        const { value: formValues } = await Swal.fire({
            title: 'Créer un Wallet Kaspa',
            html: `
                <div class="mb-3">
                    <label class="form-label">Nom du wallet</label>
                    <input type="text" id="wallet-name" class="form-control" placeholder="Mon Wallet Kaspa">
                </div>
                <div class="mb-3">
                    <label class="form-label">Mot de passe</label>
                    <input type="password" id="wallet-password" class="form-control" placeholder="Mot de passe sécurisé">
                </div>
            `,
            focusConfirm: false,
            showCancelButton: true,
            confirmButtonText: 'Créer',
            cancelButtonText: 'Annuler',
            preConfirm: () => {
                const name = document.getElementById('wallet-name').value;
                const password = document.getElementById('wallet-password').value;
                
                if (!name || !password) {
                    Swal.showValidationMessage('Veuillez remplir tous les champs');
                    return false;
                }
                
                if (password.length < 8) {
                    Swal.showValidationMessage('Le mot de passe doit contenir au moins 8 caractères');
                    return false;
                }
                
                return { name, password };
            }
        });

        if (formValues) {
            // Simulate wallet creation
            const address = `kaspa:qz${Math.random().toString(36).substring(2, 15)}${Math.random().toString(36).substring(2, 15)}`;
            
            Swal.fire({
                title: 'Wallet créé!',
                html: `
                    <div class="alert alert-success">
                        <h5>${formValues.name}</h5>
                        <p class="wallet-address">${address}</p>
                        <small>Votre wallet a été créé avec succès</small>
                    </div>
                `,
                icon: 'success'
            });
            
            this.loadWallets();
        }
    }

    // Mining functions
    loadMiningConfig() {
        // Mining config is already in HTML
    }

    toggleMining() {
        const button = document.getElementById('start-mining');
        
        if (!this.isMining) {
            // Start mining
            this.isMining = true;
            button.textContent = 'Arrêter Mining';
            button.className = 'btn btn-danger';
            
            Swal.fire({
                title: 'Mining démarré!',
                text: 'Votre opération de mining a commencé',
                icon: 'success',
                timer: 2000,
                showConfirmButton: false
            });
            
            this.simulateMining();
        } else {
            // Stop mining
            this.isMining = false;
            button.textContent = 'Démarrer Mining';
            button.className = 'btn btn-success';
            
            Swal.fire({
                title: 'Mining arrêté',
                text: 'Votre opération de mining a été arrêtée',
                icon: 'info',
                timer: 2000,
                showConfirmButton: false
            });
        }
    }

    simulateMining() {
        if (!this.isMining || !this.charts.mining) return;

        const now = new Date().toLocaleTimeString();
        const hashrate = Math.random() * 1000 + 500;

        this.charts.mining.data.labels.push(now);
        this.charts.mining.data.datasets[0].data.push(hashrate);

        // Keep only last 20 points
        if (this.charts.mining.data.labels.length > 20) {
            this.charts.mining.data.labels.shift();
            this.charts.mining.data.datasets[0].data.shift();
        }

        this.charts.mining.update('none');

        setTimeout(() => this.simulateMining(), 2000);
    }

    // News functions
    async loadNews() {
        const container = document.getElementById('news-feed');
        
        const newsItems = [
            {
                title: "Kaspa atteint un nouveau record de transactions quotidiennes",
                summary: "Le réseau Kaspa a traité plus d'1 million de transactions en une seule journée.",
                time: "Il y a 2 heures"
            },
            {
                title: "Nouvelle mise à jour du protocole Kaspa",
                summary: "L'équipe de développement annonce des améliorations de sécurité.",
                time: "Il y a 5 heures"
            },
            {
                title: "Intérêt institutionnel croissant pour Kaspa",
                summary: "Plusieurs investisseurs institutionnels s'intéressent au protocole GHOSTDAG.",
                time: "Il y a 1 jour"
            }
        ];

        const newsHTML = newsItems.map(item => `
            <div class="card mb-3">
                <div class="card-body">
                    <h5 class="card-title">${item.title}</h5>
                    <p class="card-text">${item.summary}</p>
                    <small class="text-muted">${item.time}</small>
                </div>
            </div>
        `).join('');

        container.innerHTML = newsHTML;
    }

    // Auto refresh
    startAutoRefresh() {
        setInterval(() => {
            if (this.currentSection === 'dashboard') {
                this.loadDashboardData();
            }
        }, 30000); // 30 seconds
    }
}

// Global functions
function showSection(sectionName) {
    if (window.app) {
        window.app.showSection(sectionName);
    }
}

function createWallet() {
    if (window.app) {
        window.app.createWallet();
    }
}

function toggleMining() {
    if (window.app) {
        window.app.toggleMining();
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new KaspaZofApp();
    
    // Welcome message
    setTimeout(() => {
        Swal.fire({
            title: 'Bienvenue sur KaspaZof!',
            text: 'Votre plateforme complète pour Kaspa',
            icon: 'success',
            timer: 3000,
            showConfirmButton: false
        });
    }, 1000);
});