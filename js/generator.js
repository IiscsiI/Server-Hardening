// Check Generator Module
const generator = {
    currentOS: 'windows',
    allLanguages: {
        'de': 'Deutsch',
        'es': 'Español', 
        'it': 'Italiano',
        'pt': 'Português',
        'ru': 'Русский',
        'zh': '中文',
        'ja': '日本語',
        'ar': 'العربية',
        'nl': 'Nederlands',
        'pl': 'Polski',
        'ko': '한국어',
        'tr': 'Türkçe'
    },
    activeLanguages: ['en', 'fr'], // Languages currently shown
    currentYaml: '',
    
    // Templates
    templates: {
        firewall: {
            id: 'firewall-check',
            title: {
                en: 'Firewall Status',
                fr: 'État du pare-feu'
            },
            description: {
                en: 'Checks if firewall is enabled and properly configured',
                fr: 'Vérifie que le pare-feu est activé et correctement configuré'
            },
            severity: 'critical',
            category: 'firewall',
            level: 'basic',
            commands: {
                windows: {
                    check: 'Get-NetFirewallProfile | Select-Object Name, Enabled',
                    fix: 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True'
                },
                linux: {
                    check: 'systemctl is-active firewalld || ufw status',
                    fix: 'systemctl enable --now firewalld || ufw enable'
                }
            }
        },
        service: {
            id: 'service-check',
            title: {
                en: 'Service Status Check',
                fr: 'Vérification du service'
            },
            description: {
                en: 'Checks if a specific service is running',
                fr: 'Vérifie qu\'un service spécifique est en cours d\'exécution'
            },
            severity: 'medium',
            category: 'services',
            level: 'basic'
        }
    },

    // Initialize
    init() {
        // Set up event listeners for form changes
        document.getElementById('severity').addEventListener('change', () => this.generate());
        document.getElementById('category').addEventListener('change', () => this.generate());
        document.getElementById('level').addEventListener('change', () => this.generate());
        document.getElementById('check-id').addEventListener('input', () => this.generate());
        
        // Add listeners to all text inputs and textareas
        document.querySelectorAll('input[type="text"], textarea').forEach(element => {
            element.addEventListener('input', () => this.generate());
        });
        
        // Initial generation
        this.generate();
    },

    // Show tab
    showTab(os) {
        this.currentOS = os;
        
        // Update tabs
        document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
        
        // Activate the clicked tab
        event.target.classList.add('active');
        document.getElementById(`tab-${os}`).classList.add('active');
        
        // Update OS indicator
        const indicator = document.getElementById('os-indicator');
        if (indicator) {
            indicator.textContent = os.toUpperCase();
            indicator.style.background = os === 'windows' ? '#0078d4' : '#333';
        }
        
        this.generate();
    },

    // Update Linux UI based on command type
    updateLinuxUI() {
        const type = document.getElementById('linux-cmd-type').value;
        document.getElementById('linux-universal').style.display = type === 'universal' ? 'block' : 'none';
        document.getElementById('linux-distro').style.display = type === 'distro' ? 'block' : 'none';
        this.generate();
    },

    // Load template
    loadTemplate(templateName) {
        if (!templateName) {
            this.clear();
            return;
        }
        
        // First clear everything
        this.clearForm(false); // Don't clear template selector
        
        const template = this.templates[templateName];
        if (!template) return;
        
        // Set basic fields
        document.getElementById('check-id').value = template.id;
        document.getElementById('severity').value = template.severity;
        document.getElementById('category').value = template.category;
        document.getElementById('level').value = template.level;
        
        // Set multilang fields
        Object.entries(template.title || {}).forEach(([lang, value]) => {
            const input = document.querySelector(`#title-inputs input[data-lang="${lang}"]`);
            if (input) input.value = value;
        });
        
        Object.entries(template.description || {}).forEach(([lang, value]) => {
            const textarea = document.querySelector(`#description-inputs textarea[data-lang="${lang}"]`);
            if (textarea) textarea.value = value;
        });
        
        // Set commands if available
        if (template.commands) {
            if (template.commands.windows) {
                document.getElementById('win-check-cmd').value = template.commands.windows.check || '';
                document.getElementById('win-fix-cmd').value = template.commands.windows.fix || '';
            }
            if (template.commands.linux) {
                document.getElementById('linux-check-cmd').value = template.commands.linux.check || '';
                document.getElementById('linux-fix-cmd').value = template.commands.linux.fix || '';
            }
        }
        
        this.generate();
    },

    // Add language field
    addLanguageField(type) {
        // Get available languages (not already active)
        const availableLanguages = Object.keys(this.allLanguages).filter(
            lang => !this.activeLanguages.includes(lang)
        );
        
        if (availableLanguages.length === 0) {
            alert('All languages are already added');
            return;
        }
        
        // Create language selector dialog
        const languageList = availableLanguages.map(lang => 
            `${lang} - ${this.allLanguages[lang]}`
        ).join('\n');
        
        const selectedLang = prompt(
            `Select a language to add:\n\n${languageList}\n\nEnter the language code (e.g., 'de' for Deutsch):`
        );
        
        if (!selectedLang || !availableLanguages.includes(selectedLang)) {
            return;
        }
        
        this.activeLanguages.push(selectedLang);
        
        const container = document.getElementById(`${type}-inputs`);
        const div = document.createElement('div');
        div.className = 'lang-input';
        
        if (type === 'title') {
            div.innerHTML = `
                <span class="lang-label">${selectedLang.toUpperCase()}:</span>
                <input type="text" data-lang="${selectedLang}" placeholder="${this.allLanguages[selectedLang]} title">
                <span class="remove-btn" onclick="generator.removeLanguageField(this, '${selectedLang}')">✕</span>
            `;
        } else {
            div.innerHTML = `
                <span class="lang-label">${selectedLang.toUpperCase()}:</span>
                <textarea data-lang="${selectedLang}" placeholder="${this.allLanguages[selectedLang]} description"></textarea>
                <span class="remove-btn" onclick="generator.removeLanguageField(this, '${selectedLang}')">✕</span>
            `;
        }
        
        container.appendChild(div);
        
        // Add event listener to new input/textarea
        const newInput = div.querySelector('input, textarea');
        if (newInput) {
            newInput.addEventListener('input', () => this.generate());
        }
        
        this.generate();
    },

    // Remove language field
    removeLanguageField(btn, lang) {
        btn.parentElement.remove();
        this.activeLanguages = this.activeLanguages.filter(l => l !== lang);
        this.generate();
    },

    // Generate YAML
    generate() {
        const id = document.getElementById('check-id').value;
        if (!id) {
            document.getElementById('yaml-preview').textContent = '# Please enter a unique ID';
            return;
        }
        
        const date = new Date().toISOString().split('T')[0];
        let yaml = `# verifications/${this.getOSFolder()}/${id}.yaml\n`;
        yaml += `id: ${id}\n`;
        yaml += `meta:\n`;
        yaml += `  version: "1.0"\n`;
        yaml += `  author: "Generated by Security Console"\n`;
        yaml += `  last_updated: "${date}"\n`;
        
        // Title
        yaml += `\ntitle:\n`;
        document.querySelectorAll('#title-inputs input[data-lang]').forEach(input => {
            if (input.value) {
                yaml += `  ${input.dataset.lang}: "${input.value}"\n`;
            }
        });
        
        // Description
        const hasDescription = Array.from(document.querySelectorAll('#description-inputs textarea[data-lang]'))
            .some(textarea => textarea.value);
        
        if (hasDescription) {
            yaml += `\ndescription:\n`;
            document.querySelectorAll('#description-inputs textarea[data-lang]').forEach(textarea => {
                if (textarea.value) {
                    yaml += `  ${textarea.dataset.lang}: |\n`;
                    textarea.value.split('\n').forEach(line => {
                        yaml += `    ${line}\n`;
                    });
                }
            });
        }
        
        // Properties
        yaml += `\nseverity: ${document.getElementById('severity').value}\n`;
        yaml += `category: ${document.getElementById('category').value}\n`;
        yaml += `level: ${document.getElementById('level').value}\n`;
        
        // Check commands - ONLY for current OS
        yaml += `\ncheck:\n`;
        
        if (this.currentOS === 'windows') {
            // Windows ONLY
            const winCheckCmd = document.getElementById('win-check-cmd').value;
            if (winCheckCmd) {
                yaml += `  windows:\n`;
                if (winCheckCmd.includes('\n') || winCheckCmd.length > 100) {
                    yaml += `    command: |\n`;
                    winCheckCmd.split('\n').forEach(line => {
                        yaml += `      ${line}\n`;
                    });
                } else {
                    yaml += `    command: "${winCheckCmd}"\n`;
                }
            }
        } else {
            // Linux ONLY
            const linuxType = document.getElementById('linux-cmd-type').value;
            if (linuxType === 'universal') {
                const checkCmd = document.getElementById('linux-check-cmd').value;
                if (checkCmd) {
                    yaml += `  linux:\n`;
                    if (checkCmd.includes('\n') || checkCmd.length > 100) {
                        yaml += `    command: |\n`;
                        checkCmd.split('\n').forEach(line => {
                            yaml += `      ${line}\n`;
                        });
                    } else {
                        yaml += `    command: "${checkCmd}"\n`;
                    }
                }
            } else {
                // Per distribution
                const hasDistroCommands = Array.from(document.querySelectorAll('[data-distro][data-type="check"]'))
                    .some(input => input.value);
                
                if (hasDistroCommands) {
                    yaml += `  linux:\n`;
                    ['debian', 'rhel'].forEach(distro => {
                        const checkInput = document.querySelector(`[data-distro="${distro}"][data-type="check"]`);
                        if (checkInput && checkInput.value) {
                            yaml += `    ${distro}:\n`;
                            if (checkInput.value.includes('\n') || checkInput.value.length > 100) {
                                yaml += `      command: |\n`;
                                checkInput.value.split('\n').forEach(line => {
                                    yaml += `        ${line}\n`;
                                });
                            } else {
                                yaml += `      command: "${checkInput.value}"\n`;
                            }
                        }
                    });
                }
            }
        }
        
        // Remediation - ONLY for current OS
        yaml += `\nremediation:\n`;
        
        if (this.currentOS === 'windows') {
            // Windows remediation ONLY
            const winFixCmd = document.getElementById('win-fix-cmd').value;
            const gpoPath = document.getElementById('win-gpo-path').value;
            const gpoSetting = document.getElementById('win-gpo-setting').value;
            
            if (winFixCmd || gpoPath || gpoSetting) {
                yaml += `  windows:\n`;
                if (winFixCmd) {
                    yaml += `    local:\n`;
                    if (winFixCmd.includes('\n') || winFixCmd.length > 100) {
                        yaml += `      command: |\n`;
                        winFixCmd.split('\n').forEach(line => {
                            yaml += `        ${line}\n`;
                        });
                    } else {
                        yaml += `      command: "${winFixCmd}"\n`;
                    }
                }
                
                if (gpoPath || gpoSetting) {
                    yaml += `    gpo:\n`;
                    if (gpoPath) {
                        yaml += `      path:\n`;
                        yaml += `        en: "${gpoPath}"\n`;
                    }
                    if (gpoSetting) {
                        yaml += `      setting:\n`;
                        yaml += `        en: "${gpoSetting}"\n`;
                    }
                }
            }
        } else {
            // Linux remediation ONLY
            const linuxType = document.getElementById('linux-cmd-type').value;
            if (linuxType === 'universal') {
                const fixCmd = document.getElementById('linux-fix-cmd').value;
                if (fixCmd) {
                    yaml += `  linux:\n`;
                    yaml += `    local:\n`;
                    if (fixCmd.includes('\n') || fixCmd.length > 100) {
                        yaml += `      command: |\n`;
                        fixCmd.split('\n').forEach(line => {
                            yaml += `        ${line}\n`;
                        });
                    } else {
                        yaml += `      command: "${fixCmd}"\n`;
                    }
                }
            } else {
                // Per distribution fixes
                const hasDistroFixes = Array.from(document.querySelectorAll('[data-distro][data-type="fix"]'))
                    .some(input => input.value);
                
                if (hasDistroFixes) {
                    yaml += `  linux:\n`;
                    ['debian', 'rhel'].forEach(distro => {
                        const fixInput = document.querySelector(`[data-distro="${distro}"][data-type="fix"]`);
                        if (fixInput && fixInput.value) {
                            yaml += `    ${distro}:\n`;
                            if (fixInput.value.includes('\n') || fixInput.value.length > 100) {
                                yaml += `      command: |\n`;
                                fixInput.value.split('\n').forEach(line => {
                                    yaml += `        ${line}\n`;
                                });
                            } else {
                                yaml += `      command: "${fixInput.value}"\n`;
                            }
                        }
                    });
                }
            }
        }
        
        document.getElementById('yaml-preview').textContent = yaml;
        this.currentYaml = yaml;
    },

    // Get OS folder name
    getOSFolder() {
        return this.currentOS === 'windows' ? 'windows' : 'linux';
    },

    // Download YAML
    download() {
        const yaml = this.currentYaml || document.getElementById('yaml-preview').textContent;
        if (!yaml || yaml.includes('Please enter a unique ID')) {
            alert('Please complete the form first');
            return;
        }
        
        const id = document.getElementById('check-id').value;
        const filename = `${id}.yaml`;
        
        const blob = new Blob([yaml], { type: 'text/yaml;charset=utf-8' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        
        // Visual feedback
        const btn = event.target;
        btn.textContent = '✅ Downloaded!';
        setTimeout(() => {
            btn.innerHTML = '💾 Download';
        }, 2000);
    },

    // Copy to clipboard
    async copy() {
        const yaml = this.currentYaml || document.getElementById('yaml-preview').textContent;
        if (!yaml || yaml.includes('Please enter a unique ID')) {
            alert('Please complete the form first');
            return;
        }
        
        try {
            await navigator.clipboard.writeText(yaml);
            // Visual feedback
            const btn = event.target;
            btn.classList.add('copy-success');
            btn.textContent = '✅ Copied!';
            setTimeout(() => {
                btn.classList.remove('copy-success');
                btn.innerHTML = '📋 Copy';
            }, 2000);
        } catch (err) {
            console.error('Copy failed:', err);
            alert('Failed to copy to clipboard. Please try selecting and copying manually.');
        }
    },

    // Clear form with option to keep template selector
    clearForm(clearTemplate = true) {
        document.getElementById('check-id').value = '';
        if (clearTemplate) {
            document.getElementById('templateSelect').value = '';
        }
        
        // Clear all inputs and textareas
        document.querySelectorAll('input[type="text"], textarea').forEach(el => {
            if (el.id !== 'templateSelect') {
                el.value = '';
            }
        });
        
        // Reset selects to defaults
        document.getElementById('severity').value = 'medium';
        document.getElementById('category').value = 'firewall';
        document.getElementById('level').value = 'basic';
        document.getElementById('linux-cmd-type').value = 'universal';
        
        this.updateLinuxUI();
    },

    // Clear form
    clear() {
        if (!confirm('Clear all fields?')) return;
        
        this.clearForm(true);
        this.generate();
        
        // Visual feedback
        const btn = event.target;
        btn.textContent = '✅ Cleared!';
        setTimeout(() => {
            btn.innerHTML = '🗑️ Clear';
        }, 1500);
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    generator.init();
});