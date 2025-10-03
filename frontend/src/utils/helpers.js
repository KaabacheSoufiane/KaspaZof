// Utility Helper Functions
class Helpers {
    // Format numbers with appropriate suffixes
    static formatNumber(num, decimals = 2) {
        if (num === 0) return '0';
        
        const k = 1000;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['', 'K', 'M', 'B', 'T'];
        
        const i = Math.floor(Math.log(Math.abs(num)) / Math.log(k));
        
        return parseFloat((num / Math.pow(k, i)).toFixed(dm)) + sizes[i];
    }

    // Format currency values
    static formatCurrency(amount, currency = 'USD', decimals = 2) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: currency,
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals
        }).format(amount);
    }

    // Format Kaspa addresses for display
    static formatKaspaAddress(address, startChars = 10, endChars = 10) {
        if (!address || address.length <= startChars + endChars) {
            return address;
        }
        
        return `${address.substring(0, startChars)}...${address.substring(address.length - endChars)}`;
    }

    // Validate Kaspa address format
    static isValidKaspaAddress(address) {
        if (!address || typeof address !== 'string') {
            return false;
        }
        
        // Basic Kaspa address validation
        const kaspaRegex = /^kaspa:[a-z0-9]{61}$/;
        return kaspaRegex.test(address);
    }

    // Format hash rates
    static formatHashRate(hashRate) {
        const units = ['H/s', 'KH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s'];
        let unitIndex = 0;
        let rate = hashRate;
        
        while (rate >= 1000 && unitIndex < units.length - 1) {
            rate /= 1000;
            unitIndex++;
        }
        
        return `${rate.toFixed(2)} ${units[unitIndex]}`;
    }

    // Format time durations
    static formatDuration(seconds) {
        const units = [
            { name: 'year', seconds: 31536000 },
            { name: 'month', seconds: 2592000 },
            { name: 'day', seconds: 86400 },
            { name: 'hour', seconds: 3600 },
            { name: 'minute', seconds: 60 },
            { name: 'second', seconds: 1 }
        ];
        
        for (const unit of units) {
            const count = Math.floor(seconds / unit.seconds);
            if (count >= 1) {
                return `${count} ${unit.name}${count > 1 ? 's' : ''}`;
            }
        }
        
        return '0 seconds';
    }

    // Format relative time (time ago)
    static formatTimeAgo(date) {
        const now = new Date();
        const diffInSeconds = Math.floor((now - new Date(date)) / 1000);
        
        if (diffInSeconds < 60) return 'just now';
        if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
        if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
        if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
        
        return new Date(date).toLocaleDateString();
    }

    // Copy text to clipboard
    static async copyToClipboard(text) {
        try {
            await navigator.clipboard.writeText(text);
            return true;
        } catch (error) {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = text;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            return true;
        }
    }

    // Generate random ID
    static generateId(length = 8) {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    }

    // Debounce function calls
    static debounce(func, wait, immediate = false) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                timeout = null;
                if (!immediate) func(...args);
            };
            const callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) func(...args);
        };
    }

    // Throttle function calls
    static throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    // Local storage helpers
    static setLocalStorage(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
            return true;
        } catch (error) {
            console.error('Failed to save to localStorage:', error);
            return false;
        }
    }

    static getLocalStorage(key, defaultValue = null) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue;
        } catch (error) {
            console.error('Failed to read from localStorage:', error);
            return defaultValue;
        }
    }

    static removeLocalStorage(key) {
        try {
            localStorage.removeItem(key);
            return true;
        } catch (error) {
            console.error('Failed to remove from localStorage:', error);
            return false;
        }
    }

    // Color helpers for charts and UI
    static getStatusColor(status) {
        const colors = {
            success: '#10b981',
            warning: '#f59e0b',
            danger: '#ef4444',
            info: '#3b82f6',
            primary: '#2563eb',
            secondary: '#64748b'
        };
        return colors[status] || colors.secondary;
    }

    // Generate gradient colors for charts
    static generateGradient(ctx, color1, color2) {
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, color1);
        gradient.addColorStop(1, color2);
        return gradient;
    }

    // Validate form inputs
    static validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    static validatePassword(password) {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
        return passwordRegex.test(password);
    }

    // Network status helpers
    static async checkNetworkStatus() {
        try {
            const response = await fetch('/health', { method: 'HEAD' });
            return response.ok;
        } catch (error) {
            return false;
        }
    }

    // Error handling helpers
    static handleApiError(error) {
        let message = 'An unexpected error occurred';
        
        if (error.response) {
            // Server responded with error status
            message = error.response.data?.message || `Server error: ${error.response.status}`;
        } else if (error.request) {
            // Request was made but no response received
            message = 'Network error: Unable to connect to server';
        } else {
            // Something else happened
            message = error.message || message;
        }
        
        return message;
    }

    // Performance helpers
    static measurePerformance(name, func) {
        const start = performance.now();
        const result = func();
        const end = performance.now();
        console.log(`${name} took ${(end - start).toFixed(2)} milliseconds`);
        return result;
    }

    // Device detection
    static isMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }

    static isTablet() {
        return /iPad|Android/i.test(navigator.userAgent) && window.innerWidth >= 768;
    }

    // Animation helpers
    static animateValue(element, start, end, duration, formatter = (val) => val) {
        const startTime = performance.now();
        
        function animate(currentTime) {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function (ease-out)
            const easeOut = 1 - Math.pow(1 - progress, 3);
            const current = start + (end - start) * easeOut;
            
            element.textContent = formatter(current);
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        }
        
        requestAnimationFrame(animate);
    }

    // Notification helpers
    static showNotification(title, message, type = 'info') {
        if ('Notification' in window && Notification.permission === 'granted') {
            new Notification(title, {
                body: message,
                icon: '/favicon.ico'
            });
        } else {
            // Fallback to SweetAlert2
            Swal.fire({
                title: title,
                text: message,
                icon: type,
                timer: 3000,
                showConfirmButton: false
            });
        }
    }

    static async requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            const permission = await Notification.requestPermission();
            return permission === 'granted';
        }
        return Notification.permission === 'granted';
    }
}

// Export for use in other modules
window.Helpers = Helpers;