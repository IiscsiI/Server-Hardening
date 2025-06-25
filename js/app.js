// Main application controller
const app = {
    // Initialize application
    async init() {
        try {
            // Initialize translations
            const translationsReady = await TranslationManager.init();
            if (!translationsReady) {
                console.error('Failed to initialize translations');
            }
            
            // Update UI with translations
            this.updateUI();
            
            // Setup language selector
            TranslationManager.updateLanguageSelector();
            
            // Setup language change handler
            document.getElementById('languageSelect').addEventListener('change', async (e) => {
                await this.changeLanguage(e.target.value);
            });
            
            // Load and display results
            const resultsLoaded = await ResultsManager.loadResults();
            if (resultsLoaded) {
                ResultsManager.displayResults();
            } else {
                ResultsManager.showError();
            }
            
        } catch (error) {
            console.error('Application initialization error:', error);
            ResultsManager.showError();
        }
    },

    // Update UI with translations
    updateUI() {
        // Update static elements
        document.getElementById('app-title').textContent = `🛡️ ${t('interface.title')}`;
        document.getElementById('app-subtitle').textContent = t('interface.subtitle');
        document.getElementById('app-footer').textContent = 
            `${t('interface.title')} ${t('interface.version')} - ${t('interface.footer')}`;
        
        // Update loading messages
        document.getElementById('loading-message').textContent = t('interface.messages.loading');
        document.getElementById('loading-submessage').textContent = t('interface.messages.loadingChecks');
        
        // Update page title
        document.title = t('interface.title');
    },

    // Change language
    async changeLanguage(lang) {
        const success = await TranslationManager.changeLanguage(lang);
        if (success) {
            this.updateUI();
            
            // Re-display results with new language
            if (ResultsManager.analysisData) {
                ResultsManager.displayResults();
            }
        }
    },

    // Filter results wrapper
    filterResults(filter) {
        ResultsManager.filterResults(filter);
    },

    // Show remediation details wrapper
    showRemediation(index) {
        ResultsManager.showRemediation(index);
    },

    // Generate remediation script wrapper
    generateRemediationScript() {
        ResultsManager.generateRemediationScript();
    },

    // Download script
    downloadScript(encodedScript, filename) {
        try {
            const script = decodeURIComponent(escape(atob(encodedScript)));
            const blob = new Blob([script], { type: 'text/plain;charset=utf-8' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Download error:', error);
            alert(t('interface.messages.downloadError'));
        }
    },

    // Copy to clipboard
    async copyToClipboard(encodedScript) {
        try {
            const script = decodeURIComponent(escape(atob(encodedScript)));
            await navigator.clipboard.writeText(script);
            alert(t('interface.messages.scriptCopied'));
        } catch (error) {
            console.error('Copy error:', error);
            alert(t('interface.messages.copyError'));
        }
    },

    // Run new analysis
    runNewAnalysis() {
        if (confirm(t('interface.messages.confirmNewAnalysis'))) {
            window.close();
        }
    },

    // Close modal
    closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('show');
        }
    },

    // Show help
    showHelp() {
        const modal = document.getElementById('helpModal');
        const content = document.getElementById('helpContent');
        
        content.innerHTML = `
            <h3>${t('help.sections.gettingStarted')}</h3>
            <p>${t('help.content.gettingStarted')}</p>
            
            <h3>${t('help.sections.addingChecks')}</h3>
            <p>${t('help.content.addingChecks')}</p>
            
            <h3>${t('help.sections.troubleshooting')}</h3>
            <p>${t('help.content.troubleshooting')}</p>
            
            <div style="margin-top: 20px; padding: 15px; background: #e8f5e9; border-radius: 5px;">
                <strong>💡 ${t('help.tip')}:</strong>
                <p>${t('help.tipContent')}</p>
            </div>
        `;
        
        modal.classList.add('show');
    }
};

// Handle clicks outside modals
window.onclick = function(event) {
    if (event.target.classList.contains('modal')) {
        event.target.classList.remove('show');
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    app.init();
});