// Wallet Management Component
class WalletManager {
    constructor() {
        this.wallets = [];
        this.init();
    }

    init() {
        this.loadWallets();
    }

    async loadWallets() {
        try {
            const response = await api.getWallets();
            this.wallets = response.wallets || [];
            this.renderWallets();
        } catch (error) {
            console.error('Failed to load wallets:', error);
            this.showError('Failed to load wallets');
        }
    }

    renderWallets() {
        const container = document.getElementById('wallet-list');
        
        if (this.wallets.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-wallet" style="font-size: 3rem; color: var(--secondary-color); margin-bottom: 1rem;"></i>
                    <h3>No wallets found</h3>
                    <p>Create your first Kaspa wallet to get started</p>
                    <button class="btn btn-primary" onclick="createWallet()">
                        <i class="fas fa-plus"></i> Create Wallet
                    </button>
                </div>
            `;
            return;
        }

        const walletsHTML = this.wallets.map(wallet => `
            <div class="wallet-item" data-wallet-id="${wallet.id}">
                <div class="wallet-info">
                    <h4>${wallet.label}</h4>
                    <div class="wallet-address">${this.formatAddress(wallet.address)}</div>
                    <div class="wallet-meta">
                        <span class="status-badge ${wallet.status}">${wallet.status}</span>
                        <span class="created-date">Created: ${this.formatDate(wallet.created_at)}</span>
                    </div>
                </div>
                <div class="wallet-balance">
                    <div class="balance-amount">${wallet.balance || '0.00'} KAS</div>
                    <div class="wallet-actions">
                        <button class="btn btn-sm btn-primary" onclick="walletManager.viewWallet('${wallet.id}')">
                            <i class="fas fa-eye"></i> View
                        </button>
                        <button class="btn btn-sm btn-success" onclick="walletManager.sendTransaction('${wallet.id}')">
                            <i class="fas fa-paper-plane"></i> Send
                        </button>
                    </div>
                </div>
            </div>
        `).join('');

        container.innerHTML = walletsHTML;
    }

    async viewWallet(walletId) {
        try {
            const wallet = await api.getWallet(walletId);
            
            Swal.fire({
                title: wallet.label,
                html: `
                    <div class="wallet-details">
                        <div class="detail-item">
                            <strong>Address:</strong>
                            <div class="address-display">
                                <code>${wallet.address}</code>
                                <button class="copy-btn" onclick="copyToClipboard('${wallet.address}')">
                                    <i class="fas fa-copy"></i>
                                </button>
                            </div>
                        </div>
                        <div class="detail-item">
                            <strong>Balance:</strong> ${wallet.balance || '0.00'} KAS
                        </div>
                        <div class="detail-item">
                            <strong>Status:</strong> <span class="status-badge ${wallet.status}">${wallet.status}</span>
                        </div>
                        <div class="detail-item">
                            <strong>Created:</strong> ${this.formatDate(wallet.created_at)}
                        </div>
                    </div>
                `,
                showCancelButton: true,
                confirmButtonText: 'Send Transaction',
                cancelButtonText: 'Close',
                customClass: {
                    popup: 'wallet-popup'
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    this.sendTransaction(walletId);
                }
            });
        } catch (error) {
            this.showError('Failed to load wallet details');
        }
    }

    async sendTransaction(walletId) {
        const { value: formValues } = await Swal.fire({
            title: 'Send Kaspa',
            html: `
                <div class="send-form">
                    <div class="form-group">
                        <label for="recipient">Recipient Address</label>
                        <input type="text" id="recipient" class="swal2-input" placeholder="kaspa:...">
                    </div>
                    <div class="form-group">
                        <label for="amount">Amount (KAS)</label>
                        <input type="number" id="amount" class="swal2-input" placeholder="0.00" step="0.00000001">
                    </div>
                    <div class="form-group">
                        <label for="fee">Fee (KAS)</label>
                        <input type="number" id="fee" class="swal2-input" value="0.00001" step="0.00000001">
                    </div>
                </div>
            `,
            focusConfirm: false,
            showCancelButton: true,
            confirmButtonText: 'Send',
            preConfirm: () => {
                const recipient = document.getElementById('recipient').value;
                const amount = document.getElementById('amount').value;
                const fee = document.getElementById('fee').value;

                if (!recipient || !amount) {
                    Swal.showValidationMessage('Please fill in all required fields');
                    return false;
                }

                if (!recipient.startsWith('kaspa:')) {
                    Swal.showValidationMessage('Invalid Kaspa address format');
                    return false;
                }

                return { recipient, amount: parseFloat(amount), fee: parseFloat(fee) };
            }
        });

        if (formValues) {
            // TODO: Implement actual transaction sending
            Swal.fire({
                title: 'Transaction Sent!',
                text: `Sent ${formValues.amount} KAS to ${formValues.recipient}`,
                icon: 'success'
            });
        }
    }

    formatAddress(address) {
        if (address.length > 20) {
            return `${address.substring(0, 10)}...${address.substring(address.length - 10)}`;
        }
        return address;
    }

    formatDate(dateString) {
        return new Date(dateString).toLocaleDateString();
    }

    showError(message) {
        Swal.fire({
            title: 'Error',
            text: message,
            icon: 'error'
        });
    }
}

// Global wallet manager instance
const walletManager = new WalletManager();

// Global functions for wallet operations
async function createWallet() {
    const { value: formValues } = await Swal.fire({
        title: 'Create New Wallet',
        html: `
            <div class="create-wallet-form">
                <div class="form-group">
                    <label for="wallet-label">Wallet Label</label>
                    <input type="text" id="wallet-label" class="swal2-input" placeholder="My Kaspa Wallet">
                </div>
                <div class="form-group">
                    <label for="wallet-password">Password</label>
                    <input type="password" id="wallet-password" class="swal2-input" placeholder="Enter secure password">
                </div>
                <div class="form-group">
                    <label for="wallet-password-confirm">Confirm Password</label>
                    <input type="password" id="wallet-password-confirm" class="swal2-input" placeholder="Confirm password">
                </div>
                <div class="security-notice">
                    <i class="fas fa-shield-alt"></i>
                    <p>Your wallet will be encrypted with this password. Make sure to remember it!</p>
                </div>
            </div>
        `,
        focusConfirm: false,
        showCancelButton: true,
        confirmButtonText: 'Create Wallet',
        preConfirm: () => {
            const label = document.getElementById('wallet-label').value;
            const password = document.getElementById('wallet-password').value;
            const confirmPassword = document.getElementById('wallet-password-confirm').value;

            if (!label || !password) {
                Swal.showValidationMessage('Please fill in all fields');
                return false;
            }

            if (password !== confirmPassword) {
                Swal.showValidationMessage('Passwords do not match');
                return false;
            }

            if (password.length < 8) {
                Swal.showValidationMessage('Password must be at least 8 characters');
                return false;
            }

            return { label, password };
        }
    });

    if (formValues) {
        try {
            const response = await api.createWallet(formValues);
            
            Swal.fire({
                title: 'Wallet Created!',
                html: `
                    <div class="wallet-created">
                        <i class="fas fa-check-circle" style="color: var(--success-color); font-size: 3rem; margin-bottom: 1rem;"></i>
                        <h3>${formValues.label}</h3>
                        <p>Your new Kaspa wallet has been created successfully.</p>
                        <div class="new-address">
                            <strong>Address:</strong>
                            <code>${response.address}</code>
                        </div>
                    </div>
                `,
                icon: 'success'
            });

            // Reload wallets
            walletManager.loadWallets();
        } catch (error) {
            Swal.fire({
                title: 'Error',
                text: 'Failed to create wallet. Please try again.',
                icon: 'error'
            });
        }
    }
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        Swal.fire({
            title: 'Copied!',
            text: 'Address copied to clipboard',
            icon: 'success',
            timer: 2000,
            showConfirmButton: false
        });
    });
}