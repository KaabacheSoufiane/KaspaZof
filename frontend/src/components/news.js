// Crypto News Sniffer Component
class NewsManager {
    constructor() {
        this.news = [];
        this.currentFilter = 'all';
        this.newsCache = new Map();
        this.init();
    }

    init() {
        this.setupFilters();
        this.loadNews();
        this.startAutoRefresh();
    }

    setupFilters() {
        const filterButtons = document.querySelectorAll('.filter-btn');
        filterButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const filter = e.target.dataset.filter;
                this.setFilter(filter);
            });
        });
    }

    setFilter(filter) {
        this.currentFilter = filter;
        
        // Update filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        this.renderNews();
    }

    async loadNews() {
        try {
            this.showNewsLoading(true);
            
            // Load news from multiple sources
            const newsPromises = [
                this.fetchKaspaNews(),
                this.fetchCryptoNews(),
                this.fetchMiningNews()
            ];
            
            const newsResults = await Promise.allSettled(newsPromises);
            
            // Combine all news
            this.news = [];
            newsResults.forEach(result => {
                if (result.status === 'fulfilled' && result.value) {
                    this.news = this.news.concat(result.value);
                }
            });
            
            // Sort by date (newest first)
            this.news.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
            
            this.renderNews();
            this.showNewsLoading(false);
            
        } catch (error) {
            console.error('Failed to load news:', error);
            this.showNewsError();
        }
    }

    async fetchKaspaNews() {
        // Simulate Kaspa-specific news fetching
        // In production, this would connect to real news APIs or RSS feeds
        return this.generateSimulatedNews('kaspa', 5);
    }

    async fetchCryptoNews() {
        // Simulate general crypto news
        return this.generateSimulatedNews('crypto', 8);
    }

    async fetchMiningNews() {
        // Simulate mining-related news
        return this.generateSimulatedNews('mining', 4);
    }

    generateSimulatedNews(category, count) {
        const newsTemplates = {
            kaspa: [
                {
                    title: "Kaspa Network Reaches New All-Time High in Daily Transactions",
                    summary: "The Kaspa blockchain processed over 1 million transactions in a single day, showcasing its scalability and growing adoption.",
                    source: "Kaspa Official"
                },
                {
                    title: "Major Exchange Announces Kaspa Listing",
                    summary: "Leading cryptocurrency exchange confirms support for KAS trading pairs, expected to increase liquidity and accessibility.",
                    source: "Crypto Exchange News"
                },
                {
                    title: "Kaspa Mining Pool Efficiency Improvements",
                    summary: "New mining pool optimizations reduce latency and increase profitability for Kaspa miners worldwide.",
                    source: "Mining Pool Updates"
                },
                {
                    title: "Kaspa Developer Team Releases Network Upgrade",
                    summary: "Latest protocol upgrade enhances security and introduces new features for the Kaspa ecosystem.",
                    source: "Kaspa Development"
                },
                {
                    title: "Institutional Interest in Kaspa Grows",
                    summary: "Several institutional investors express interest in Kaspa's unique GHOSTDAG consensus mechanism.",
                    source: "Institutional News"
                }
            ],
            crypto: [
                {
                    title: "Bitcoin Reaches New Price Milestone",
                    summary: "Bitcoin continues its upward trajectory as institutional adoption increases globally.",
                    source: "CoinDesk"
                },
                {
                    title: "Ethereum 2.0 Staking Rewards Update",
                    summary: "Latest statistics show growing participation in Ethereum staking with improved rewards.",
                    source: "Ethereum Foundation"
                },
                {
                    title: "Regulatory Clarity Boosts Crypto Market",
                    summary: "New regulatory guidelines provide clearer framework for cryptocurrency operations.",
                    source: "Regulatory News"
                },
                {
                    title: "DeFi Protocol Launches New Features",
                    summary: "Popular decentralized finance platform introduces innovative yield farming mechanisms.",
                    source: "DeFi Pulse"
                }
            ],
            mining: [
                {
                    title: "GPU Mining Profitability Analysis",
                    summary: "Comprehensive analysis of current GPU mining profitability across different cryptocurrencies.",
                    source: "Mining Analytics"
                },
                {
                    title: "New ASIC Miner Released for Proof-of-Work Coins",
                    summary: "Hardware manufacturer announces next-generation ASIC miner with improved efficiency.",
                    source: "Hardware News"
                },
                {
                    title: "Mining Pool Consolidation Trends",
                    summary: "Analysis of mining pool market share changes and their impact on network decentralization.",
                    source: "Pool Statistics"
                },
                {
                    title: "Renewable Energy in Crypto Mining",
                    summary: "Growing trend of cryptocurrency mining operations powered by renewable energy sources.",
                    source: "Green Mining"
                }
            ]
        };

        const templates = newsTemplates[category] || newsTemplates.crypto;
        const news = [];

        for (let i = 0; i < Math.min(count, templates.length); i++) {
            const template = templates[i];
            const publishedAt = new Date();
            publishedAt.setHours(publishedAt.getHours() - Math.random() * 24 * 7); // Random time in last week

            news.push({
                id: `${category}-${i}-${Date.now()}`,
                title: template.title,
                summary: template.summary,
                source: template.source,
                category: category,
                publishedAt: publishedAt.toISOString(),
                url: `#news-${category}-${i}`,
                imageUrl: this.getNewsImage(category)
            });
        }

        return news;
    }

    getNewsImage(category) {
        const images = {
            kaspa: 'https://via.placeholder.com/300x200/2563eb/ffffff?text=Kaspa',
            crypto: 'https://via.placeholder.com/300x200/10b981/ffffff?text=Crypto',
            mining: 'https://via.placeholder.com/300x200/f59e0b/ffffff?text=Mining'
        };
        return images[category] || images.crypto;
    }

    renderNews() {
        const container = document.getElementById('news-feed');
        
        let filteredNews = this.news;
        if (this.currentFilter !== 'all') {
            filteredNews = this.news.filter(item => item.category === this.currentFilter);
        }

        if (filteredNews.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-newspaper" style="font-size: 3rem; color: var(--secondary-color); margin-bottom: 1rem;"></i>
                    <h3>No news found</h3>
                    <p>No news articles match the current filter.</p>
                    <button class="btn btn-primary" onclick="newsManager.loadNews()">
                        <i class="fas fa-sync-alt"></i> Refresh News
                    </button>
                </div>
            `;
            return;
        }

        const newsHTML = filteredNews.map(item => `
            <article class="news-item" data-category="${item.category}">
                <div class="news-content">
                    <h3 class="news-title">${item.title}</h3>
                    <p class="news-summary">${item.summary}</p>
                    <div class="news-meta">
                        <span class="news-source">
                            <i class="fas fa-globe"></i> ${item.source}
                        </span>
                        <span class="news-time">
                            <i class="fas fa-clock"></i> ${this.formatTimeAgo(item.publishedAt)}
                        </span>
                        <span class="news-category">
                            <i class="fas fa-tag"></i> ${item.category}
                        </span>
                    </div>
                </div>
                <div class="news-actions">
                    <button class="btn btn-sm btn-primary" onclick="newsManager.readMore('${item.id}')">
                        <i class="fas fa-external-link-alt"></i> Read More
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="newsManager.shareNews('${item.id}')">
                        <i class="fas fa-share"></i> Share
                    </button>
                </div>
            </article>
        `).join('');

        container.innerHTML = newsHTML;
    }

    readMore(newsId) {
        const newsItem = this.news.find(item => item.id === newsId);
        if (!newsItem) return;

        Swal.fire({
            title: newsItem.title,
            html: `
                <div class="news-detail">
                    <div class="news-meta-detail">
                        <span><strong>Source:</strong> ${newsItem.source}</span>
                        <span><strong>Published:</strong> ${this.formatDate(newsItem.publishedAt)}</span>
                        <span><strong>Category:</strong> ${newsItem.category}</span>
                    </div>
                    <div class="news-content-detail">
                        <p>${newsItem.summary}</p>
                        <p><em>This is a simulated news article. In a real implementation, this would contain the full article content.</em></p>
                    </div>
                </div>
            `,
            showCancelButton: true,
            confirmButtonText: 'Visit Source',
            cancelButtonText: 'Close',
            customClass: {
                popup: 'news-popup'
            }
        }).then((result) => {
            if (result.isConfirmed) {
                // In real implementation, open the actual news URL
                window.open(newsItem.url, '_blank');
            }
        });
    }

    shareNews(newsId) {
        const newsItem = this.news.find(item => item.id === newsId);
        if (!newsItem) return;

        if (navigator.share) {
            navigator.share({
                title: newsItem.title,
                text: newsItem.summary,
                url: window.location.href
            });
        } else {
            // Fallback to clipboard
            const shareText = `${newsItem.title}\n\n${newsItem.summary}\n\nSource: ${newsItem.source}`;
            navigator.clipboard.writeText(shareText).then(() => {
                Swal.fire({
                    title: 'Copied!',
                    text: 'News article copied to clipboard',
                    icon: 'success',
                    timer: 2000,
                    showConfirmButton: false
                });
            });
        }
    }

    formatTimeAgo(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffInSeconds = Math.floor((now - date) / 1000);

        if (diffInSeconds < 60) return 'Just now';
        if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
        if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
        if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
        
        return date.toLocaleDateString();
    }

    formatDate(dateString) {
        return new Date(dateString).toLocaleString();
    }

    showNewsLoading(show) {
        const container = document.getElementById('news-feed');
        
        if (show) {
            container.innerHTML = '<div class="loading">Loading latest crypto news...</div>';
        }
    }

    showNewsError() {
        const container = document.getElementById('news-feed');
        container.innerHTML = `
            <div class="error-state">
                <i class="fas fa-exclamation-triangle" style="font-size: 3rem; color: var(--danger-color); margin-bottom: 1rem;"></i>
                <h3>Failed to load news</h3>
                <p>Unable to fetch the latest crypto news. Please try again later.</p>
                <button class="btn btn-primary" onclick="newsManager.loadNews()">
                    <i class="fas fa-retry"></i> Try Again
                </button>
            </div>
        `;
    }

    startAutoRefresh() {
        // Refresh news every 15 minutes
        setInterval(() => {
            this.loadNews();
        }, 15 * 60 * 1000);
    }

    searchNews(query) {
        if (!query) {
            this.renderNews();
            return;
        }

        const filteredNews = this.news.filter(item => 
            item.title.toLowerCase().includes(query.toLowerCase()) ||
            item.summary.toLowerCase().includes(query.toLowerCase()) ||
            item.source.toLowerCase().includes(query.toLowerCase())
        );

        // Temporarily override news for search results
        const originalNews = this.news;
        this.news = filteredNews;
        this.renderNews();
        this.news = originalNews;
    }
}

// Global news manager instance
const newsManager = new NewsManager();

// Global function for refreshing news
function refreshNews() {
    newsManager.loadNews();
}