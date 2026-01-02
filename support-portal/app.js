/**
 * NuNa Support Portal - Main Application
 */

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    initializeUptime();
    initializeAnimations();
    console.log('✅ NuNa Support Portal initialized');
});

/**
 * Open WhatsApp with pre-filled message
 */
function openWhatsApp() {
    const phone = CONFIG.whatsapp.phoneNumber;
    const message = encodeURIComponent(CONFIG.whatsapp.defaultMessage);
    
    // Check if phone number is configured
    if (phone === "YOUR_WHATSAPP_NUMBER_HERE" || !phone) {
        showNotification('⚠️ Please configure your WhatsApp number in config.js', 'warning');
        return;
    }
    
    let url;
    if (CONFIG.whatsapp.useWeb) {
        url = `https://web.whatsapp.com/send?phone=${phone}&text=${message}`;
    } else {
        url = `https://wa.me/${phone}?text=${message}`;
    }
    
    window.open(url, '_blank');
    console.log('📱 Opening WhatsApp chat...');
}

/**
 * Open Perplexity AI search
 */
function openPerplexity() {
    const query = encodeURIComponent(CONFIG.perplexity.defaultQuery);
    const url = `${CONFIG.perplexity.baseUrl}?q=${query}`;
    
    window.open(url, '_blank');
    console.log('🤖 Opening Perplexity AI...');
}

/**
 * Open documentation
 */
function openDocs() {
    if (CONFIG.docsUrl && CONFIG.docsUrl !== "https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO") {
        window.open(CONFIG.docsUrl, '_blank');
    } else {
        showNotification('📚 Configure docs URL in config.js', 'info');
    }
}

/**
 * Calculate and display uptime
 */
function initializeUptime() {
    const uptimeElement = document.getElementById('uptime');
    if (!uptimeElement) return;
    
    // Simulate uptime (in production, get from system)
    const startTime = new Date();
    startTime.setHours(startTime.getHours() - Math.floor(Math.random() * 24));
    startTime.setMinutes(startTime.getMinutes() - Math.floor(Math.random() * 60));
    
    function updateUptime() {
        const now = new Date();
        const diff = now - startTime;
        
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        
        uptimeElement.textContent = `${hours}h ${minutes}m`;
    }
    
    updateUptime();
    setInterval(updateUptime, 60000); // Update every minute
}

/**
 * Initialize scroll animations
 */
function initializeAnimations() {
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
            }
        });
    }, observerOptions);
    
    // Observe feature cards
    document.querySelectorAll('.feature-card').forEach((card, index) => {
        card.style.animationDelay = `${index * 0.1}s`;
        observer.observe(card);
    });
    
    // Observe support options
    document.querySelectorAll('.support-option').forEach((option, index) => {
        option.style.animationDelay = `${index * 0.15}s`;
        observer.observe(option);
    });
}

/**
 * Show notification toast
 */
function showNotification(message, type = 'info') {
    // Remove existing notification
    const existing = document.querySelector('.notification-toast');
    if (existing) existing.remove();
    
    // Create notification
    const toast = document.createElement('div');
    toast.className = `notification-toast ${type}`;
    toast.innerHTML = `
        <span class="toast-message">${message}</span>
        <button class="toast-close" onclick="this.parentElement.remove()">×</button>
    `;
    
    // Add styles
    toast.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        background: ${type === 'warning' ? '#f59e0b' : type === 'error' ? '#ef4444' : '#7c3aed'};
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 10px;
        display: flex;
        align-items: center;
        gap: 1rem;
        box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        z-index: 1000;
        animation: slideIn 0.3s ease;
        font-family: 'Outfit', sans-serif;
    `;
    
    // Add animation keyframes if not exists
    if (!document.querySelector('#toast-styles')) {
        const style = document.createElement('style');
        style.id = 'toast-styles';
        style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            .toast-close {
                background: transparent;
                border: none;
                color: white;
                font-size: 1.5rem;
                cursor: pointer;
                line-height: 1;
                opacity: 0.7;
            }
            .toast-close:hover { opacity: 1; }
        `;
        document.head.appendChild(style);
    }
    
    document.body.appendChild(toast);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (toast.parentElement) {
            toast.style.animation = 'slideIn 0.3s ease reverse';
            setTimeout(() => toast.remove(), 300);
        }
    }, 5000);
}

/**
 * Smooth scroll to section
 */
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.scrollIntoView({ behavior: 'smooth' });
    }
}

// Add animation class styles
const animationStyles = document.createElement('style');
animationStyles.textContent = `
    .feature-card,
    .support-option {
        opacity: 0;
        transform: translateY(30px);
        transition: opacity 0.6s ease, transform 0.6s ease;
    }
    
    .feature-card.animate-in,
    .support-option.animate-in {
        opacity: 1;
        transform: translateY(0);
    }
`;
document.head.appendChild(animationStyles);

