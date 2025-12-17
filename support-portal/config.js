/**
 * NuNa Support Portal Configuration
 * 
 * IMPORTANT: Update these settings with your actual WhatsApp number
 * and preferred support message.
 */

const CONFIG = {
    // WhatsApp Configuration
    whatsapp: {
        // Your WhatsApp number with country code (no + or spaces)
        // +1 (833) 436-3285
        phoneNumber: "18334363285",
        
        // Default message when user opens WhatsApp chat
        defaultMessage: "Hi! I need support with my NuNa system.",
        
        // Use WhatsApp Web (true) or WhatsApp App (false)
        useWeb: false
    },
    
    // Perplexity AI Configuration
    perplexity: {
        // Perplexity search URL
        baseUrl: "https://www.perplexity.ai/search",
        
        // Default search query
        defaultQuery: "NuNa Windows automation support"
    },
    
    // Documentation URL
    docsUrl: "https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO",
    
    // System Info (automatically updated)
    system: {
        device: "NuNa",
        os: "Windows 11 Home",
        build: "26220.7344"
    }
};

// Freeze config to prevent modifications
Object.freeze(CONFIG);
Object.freeze(CONFIG.whatsapp);
Object.freeze(CONFIG.perplexity);
Object.freeze(CONFIG.system);

