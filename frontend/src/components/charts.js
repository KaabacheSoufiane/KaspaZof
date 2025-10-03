// Charts Component for Price Visualization
class ChartsManager {
    constructor() {
        this.priceChart = null;
        this.currentPeriod = 7;
        this.init();
    }

    init() {
        this.initPriceChart();
        this.loadPriceData();
    }

    initPriceChart() {
        const ctx = document.getElementById('price-chart');
        if (!ctx) return;

        this.priceChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Kaspa Price (USD)',
                    data: [],
                    borderColor: 'rgb(37, 99, 235)',
                    backgroundColor: 'rgba(37, 99, 235, 0.1)',
                    tension: 0.4,
                    fill: true,
                    pointRadius: 2,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                scales: {
                    y: {
                        beginAtZero: false,
                        title: {
                            display: true,
                            text: 'Price (USD)'
                        },
                        grid: {
                            color: 'rgba(0, 0, 0, 0.1)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        },
                        grid: {
                            color: 'rgba(0, 0, 0, 0.1)'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: 'white',
                        bodyColor: 'white',
                        borderColor: 'rgb(37, 99, 235)',
                        borderWidth: 1,
                        callbacks: {
                            label: function(context) {
                                return `Price: $${context.parsed.y.toFixed(6)}`;
                            }
                        }
                    }
                },
                animation: {
                    duration: 1000,
                    easing: 'easeInOutQuart'
                }
            }
        });
    }

    async loadPriceData(period = this.currentPeriod) {
        try {
            this.showChartLoading(true);
            
            const response = await api.getPriceHistory(period);
            const priceData = response.data;
            
            if (priceData && priceData.prices) {
                this.updatePriceChart(priceData.prices);
            } else {
                // Fallback to simulated data if API doesn't return history
                this.generateSimulatedData(period);
            }
            
            this.showChartLoading(false);
        } catch (error) {
            console.error('Failed to load price data:', error);
            this.generateSimulatedData(period);
            this.showChartLoading(false);
        }
    }

    updatePriceChart(priceData) {
        if (!this.priceChart) return;

        const labels = [];
        const prices = [];

        priceData.forEach(([timestamp, price]) => {
            const date = new Date(timestamp);
            labels.push(this.formatDateLabel(date, this.currentPeriod));
            prices.push(price);
        });

        this.priceChart.data.labels = labels;
        this.priceChart.data.datasets[0].data = prices;
        this.priceChart.update();

        // Update price statistics
        this.updatePriceStats(prices);
    }

    generateSimulatedData(period) {
        const labels = [];
        const prices = [];
        const basePrice = 0.02; // Base Kaspa price
        let currentPrice = basePrice;

        const dataPoints = this.getDataPointsForPeriod(period);
        
        for (let i = 0; i < dataPoints; i++) {
            const date = new Date();
            date.setHours(date.getHours() - (dataPoints - i) * (period === 1 ? 1 : 24));
            
            labels.push(this.formatDateLabel(date, period));
            
            // Simulate price movement
            const change = (Math.random() - 0.5) * 0.002;
            currentPrice = Math.max(0.001, currentPrice + change);
            prices.push(currentPrice);
        }

        this.priceChart.data.labels = labels;
        this.priceChart.data.datasets[0].data = prices;
        this.priceChart.update();

        this.updatePriceStats(prices);
    }

    getDataPointsForPeriod(period) {
        switch (period) {
            case 1: return 24; // 24 hours
            case 7: return 7 * 4; // 7 days, 4 points per day
            case 30: return 30; // 30 days
            case 90: return 90; // 90 days
            default: return 30;
        }
    }

    formatDateLabel(date, period) {
        if (period === 1) {
            return date.toLocaleTimeString('en-US', { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        } else {
            return date.toLocaleDateString('en-US', { 
                month: 'short', 
                day: 'numeric' 
            });
        }
    }

    updatePriceStats(prices) {
        if (prices.length === 0) return;

        const currentPrice = prices[prices.length - 1];
        const previousPrice = prices[0];
        const change = currentPrice - previousPrice;
        const changePercent = (change / previousPrice) * 100;

        const high = Math.max(...prices);
        const low = Math.min(...prices);
        const average = prices.reduce((sum, price) => sum + price, 0) / prices.length;

        // Update price display in dashboard if visible
        this.updatePriceDisplay(currentPrice, changePercent);
        
        // Show detailed stats
        this.showPriceStats({
            current: currentPrice,
            change: change,
            changePercent: changePercent,
            high: high,
            low: low,
            average: average
        });
    }

    updatePriceDisplay(price, changePercent) {
        const priceInfo = document.getElementById('price-info');
        if (!priceInfo) return;

        const changeClass = changePercent >= 0 ? 'positive' : 'negative';
        const changeIcon = changePercent >= 0 ? 'fa-arrow-up' : 'fa-arrow-down';

        priceInfo.innerHTML = `
            <div class="price-display">
                <div class="price-main">$${price.toFixed(6)}</div>
                <div class="price-change ${changeClass}">
                    <i class="fas ${changeIcon}"></i>
                    ${changePercent >= 0 ? '+' : ''}${changePercent.toFixed(2)}%
                </div>
                <div class="price-period">${this.currentPeriod}D Change</div>
            </div>
        `;
    }

    showPriceStats(stats) {
        // This could be expanded to show more detailed statistics
        console.log('Price Statistics:', stats);
    }

    showChartLoading(show) {
        const chartContainer = document.querySelector('#price-chart').parentElement;
        
        if (show) {
            if (!chartContainer.querySelector('.chart-loading')) {
                const loading = document.createElement('div');
                loading.className = 'chart-loading';
                loading.innerHTML = '<div class="loading">Loading chart data...</div>';
                chartContainer.appendChild(loading);
            }
        } else {
            const loading = chartContainer.querySelector('.chart-loading');
            if (loading) {
                loading.remove();
            }
        }
    }

    changePeriod(period) {
        this.currentPeriod = parseInt(period);
        this.loadPriceData(this.currentPeriod);
    }

    exportChart() {
        if (!this.priceChart) return;

        const url = this.priceChart.toBase64Image();
        const link = document.createElement('a');
        link.download = `kaspa-price-chart-${this.currentPeriod}d.png`;
        link.href = url;
        link.click();

        Swal.fire({
            title: 'Chart Exported',
            text: 'Price chart has been downloaded as PNG image.',
            icon: 'success',
            timer: 2000,
            showConfirmButton: false
        });
    }

    toggleChartType() {
        if (!this.priceChart) return;

        const currentType = this.priceChart.config.type;
        const newType = currentType === 'line' ? 'bar' : 'line';
        
        this.priceChart.config.type = newType;
        this.priceChart.update();
    }

    addTechnicalIndicators() {
        // TODO: Implement technical indicators like moving averages, RSI, etc.
        Swal.fire({
            title: 'Technical Indicators',
            text: 'Technical indicators feature coming soon!',
            icon: 'info'
        });
    }
}

// Global charts manager instance
const chartsManager = new ChartsManager();

// Global function for updating chart period
function updateChart() {
    const period = document.getElementById('chart-period').value;
    chartsManager.changePeriod(period);
}