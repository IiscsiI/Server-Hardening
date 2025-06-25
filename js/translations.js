// Translation management module
const TranslationManager = {
    currentLang: 'en',
    translations: {},
    availableLanguages: [],
    config: {},

    // Initialize translation system
    async init() {
        try {
            // Load config
            this.config = await this.loadConfig();
            
            // Get available languages
            this.availableLanguages = await this.getAvailableLanguages();
            
            // Determine current language
            this.currentLang = this.determineLanguage();
            
            // Load translations
            await this.loadTranslations(this.currentLang);
            
            return true;
        } catch (error) {
            console.error('Translation init error:', error);
            return false;
        }
    },

    // Load configuration file
    async loadConfig() {
        try {
            const response = await fetch('config.json?t=' + Date.now());
            if (response.ok) {
                return await response.json();
            }
        } catch (error) {
            console.log('No config file, using defaults');
        }
        return { language: null };
    },

    // Get list of available languages
    async getAvailableLanguages() {
        // Try to load from a manifest file first
        try {
            const response = await fetch('lang/languages.json');
            if (response.ok) {
                return await response.json();
            }
        } catch (error) {
            console.log('No language manifest, using defaults');
        }
        
        // Default language list
        const languages = ['en', 'fr', 'de', 'es'];
        const available = [];
        
        // Check which language files exist
        for (const lang of languages) {
            try {
                const response = await fetch(`lang/${lang}.json`);
                if (response.ok) {
                    available.push(lang);
                }
            } catch (error) {
                console.log(`Language ${lang} not available`);
            }
        }
        
        return available.length > 0 ? available : ['en'];
    },

    // Determine which language to use
    determineLanguage() {
        // Priority: config > URL parameter > browser > default
        
        // Check URL parameter
        const urlParams = new URLSearchParams(window.location.search);
        const urlLang = urlParams.get('lang');
        if (urlLang && this.availableLanguages.includes(urlLang)) {
            return urlLang;
        }
        
        // Check saved config
        if (this.config.language && this.availableLanguages.includes(this.config.language)) {
            return this.config.language;
        }
        
        // Check browser language
        const browserLang = navigator.language.substring(0, 2).toLowerCase();
        if (this.availableLanguages.includes(browserLang)) {
            return browserLang;
        }
        
        // Default to English
        return 'en';
    },

    // Load translations for a specific language
    async loadTranslations(lang) {
        try {
            const response = await fetch(`lang/${lang}.json?t=` + Date.now());
            if (response.ok) {
                this.translations = await response.json();
                this.currentLang = lang;
                return true;
            }
        } catch (error) {
            console.error(`Error loading language ${lang}:`, error);
        }
        
        // Fallback to English
        if (lang !== 'en') {
            return this.loadTranslations('en');
        }
        
        // Ultimate fallback - embedded minimal translations
        this.translations = {
            locale: 'en',
            name: 'English',
            interface: {
                title: 'Security Hardening Console',
                subtitle: 'Analyze and strengthen server security',
                messages: {
                    loading: 'Loading...',
                    errorLoading: 'Error loading results'
                }
            }
        };
        return false;
    },

    // Get translation by key path
    t(key, replacements = {}) {
        const keys = key.split('.');
        let value = this.translations;
        
        for (const k of keys) {
            if (value && typeof value === 'object' && k in value) {
                value = value[k];
            } else {
                console.warn(`Translation key not found: ${key}`);
                return key;
            }
        }
        
        // Replace placeholders
        if (typeof value === 'string') {
            Object.keys(replacements).forEach(placeholder => {
                const regex = new RegExp(`\\{${placeholder}\\}`, 'g');
                value = value.replace(regex, replacements[placeholder]);
            });
        }
        
        return value;
    },

    // Change language
    async changeLanguage(lang) {
        if (lang === this.currentLang || !this.availableLanguages.includes(lang)) {
            return false;
        }
        
        const success = await this.loadTranslations(lang);
        if (success) {
            // Save preference
            this.config.language = lang;
            this.saveConfig();
            
            // Update URL
            const url = new URL(window.location);
            url.searchParams.set('lang', lang);
            window.history.replaceState({}, '', url);
            
            return true;
        }
        return false;
    },

    // Save configuration
    saveConfig() {
        // In a real app, this would save to backend
        // For now, just update localStorage
        try {
            localStorage.setItem('securityConsoleConfig', JSON.stringify(this.config));
        } catch (error) {
            console.log('Cannot save config to localStorage');
        }
    },

    // Update language selector UI
    updateLanguageSelector() {
        const select = document.getElementById('languageSelect');
        if (!select) return;
        
        select.innerHTML = '';
        
        this.availableLanguages.forEach(async (lang) => {
            const option = document.createElement('option');
            option.value = lang;
            option.selected = lang === this.currentLang;
            
            // Try to get native name from translations
            if (lang === this.currentLang) {
                option.textContent = `${this.translations.flag || ''} ${this.translations.name || lang.toUpperCase()}`.trim();
            } else {
                // Load just the metadata for other languages
                try {
                    const response = await fetch(`lang/${lang}.json`);
                    if (response.ok) {
                        const data = await response.json();
                        option.textContent = `${data.flag || ''} ${data.name || lang.toUpperCase()}`.trim();
                    } else {
                        option.textContent = lang.toUpperCase();
                    }
                } catch {
                    option.textContent = lang.toUpperCase();
                }
            }
        });
    },

    // Get current language
    getCurrentLang() {
        return this.currentLang;
    },

    // Get all translations
    getTranslations() {
        return this.translations;
    }
};

// Shortcut function
function t(key, replacements) {
    return TranslationManager.t(key, replacements);
}