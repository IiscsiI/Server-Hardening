// Results display module
const ResultsManager = {
    analysisData: null,
    currentFilter: 'all',

    // Load results from JSON file
    async loadResults() {
        try {
            // Wait a bit to ensure file is created
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            const response = await fetch('results.json?t=' + Date.now());
            if (!response.ok) {
                throw new Error('Cannot load results');
            }
            
            this.analysisData = await response.json();
            
            // Check if analysis language differs from UI language
            if (this.analysisData.metadata?.language && 
                this.analysisData.metadata.language !== TranslationManager.getCurrentLang()) {
                // Offer to switch to analysis language
                const analysisLang = this.analysisData.metadata.language;
                if (TranslationManager.availableLanguages.includes(analysisLang)) {
                    if (confirm(`Switch to ${analysisLang.toUpperCase()} language?`)) {
                        await TranslationManager.changeLanguage(analysisLang);
                    }
                }
            }
            
            return true;
        } catch (error) {
            console.error('Error loading results:', error);
            return false;
        }
    },

    // Display all results
    displayResults() {
        const content = document.getElementById('content');
        if (!this.analysisData) {
            this.showError();
            return;
        }

        let html = '';
        
        // System info
        html += this.generateSystemInfo();
        
        // Summary cards
        html += this.generateSummary();
        
        // Progress bar
        html += this.generateProgressBar();
        
        // Detailed results
        html += this.generateDetailedResults();
        
        // Actions
        html += this.generateActions();
        
        content.innerHTML = html;
        
        // Set initial filter
        this.filterResults('all');
    },

    // Generate system info section
    generateSystemInfo() {
        const system = this.analysisData.system;
        
        return `
            <div class="card">
                <h2 class="card-title">📊 ${t('interface.sections.systemInfo')}</h2>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.hostname')}</div>
                        <div class="info-value">${system.hostname || 'N/A'}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.operatingSystem')}</div>
                        <div class="info-value">${system.os || 'N/A'}</div>
                    </div>
                    ${system.distro ? `
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.distribution')}</div>
                        <div class="info-value">${system.distro} ${system.distroVersion || ''}</div>
                    </div>
                    ` : ''}
                    ${system.kernel ? `
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.kernel')}</div>
                        <div class="info-value">${system.kernel}</div>
                    </div>
                    ` : ''}
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.analysisDate')}</div>
                        <div class="info-value">${system.analysisDate || 'N/A'}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">${t('interface.labels.user')}</div>
                        <div class="info-value">${system.currentUser || 'N/A'}</div>
                    </div>
                </div>
            </div>
        `;
    },

    // Generate summary cards
    generateSummary() {
        const stats = this.analysisData.statistics;
        
        return `
            <div class="summary-section">
                <div class="summary-card passed">
                    <div class="summary-label">${t('interface.labels.passed')}</div>
                    <div class="summary-number" style="color: var(--secondary);">${stats.passed}</div>
                </div>
                <div class="summary-card failed">
                    <div class="summary-label">${t('interface.labels.failed')}</div>
                    <div class="summary-number" style="color: var(--danger);">${stats.failed}</div>
                </div>
                <div class="summary-card errors">
                    <div class="summary-label">${t('interface.labels.errors')}</div>
                    <div class="summary-number" style="color: var(--warning);">${stats.errors}</div>
                </div>
                <div class="summary-card info">
                    <div class="summary-label">${t('interface.labels.info')}</div>
                    <div class="summary-number" style="color: var(--info);">${stats.info || 0}</div>
                </div>
            </div>
        `;
    },

    // Generate progress bar
    generateProgressBar() {
        const stats = this.analysisData.statistics;
        const total = stats.total || 1;
        const percentage = Math.round((stats.passed / total) * 100);
        
        // Color based on score
        let bgColor = 'linear-gradient(90deg, var(--secondary) 0%, #22c55e 100%)';
        if (percentage < 50) {
            bgColor = 'linear-gradient(90deg, var(--danger) 0%, #e74c3c 100%)';
        } else if (percentage < 80) {
            bgColor = 'linear-gradient(90deg, var(--warning) 0%, #f39c12 100%)';
        }
        
        return `
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${percentage}%; background: ${bgColor};">
                    ${percentage}% ${t('interface.status.pass')}
                </div>
            </div>
        `;
    },

    // Generate detailed results section
    generateDetailedResults() {
        return `
            <div class="card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h2 class="card-title" style="margin-bottom: 0;">📋 ${t('interface.sections.detailedResults')}</h2>
                    <div class="filter-buttons no-print">
                        <button class="filter-btn" onclick="app.filterResults('all')">${t('interface.labels.total')}</button>
                        <button class="filter-btn" onclick="app.filterResults('pass')">✅ ${t('interface.labels.passed')}</button>
                        <button class="filter-btn" onclick="app.filterResults('fail')">❌ ${t('interface.labels.failed')}</button>
                        <button class="filter-btn" onclick="app.filterResults('error')">⚠️ ${t('interface.labels.errors')}</button>
                        <button class="filter-btn" onclick="app.filterResults('info')">ℹ️ ${t('interface.labels.info')}</button>
                    </div>
                </div>
                <div id="results-list">
                    <!-- Results will be inserted here by filterResults -->
                </div>
            </div>
        `;
    },

    // Generate action buttons
    generateActions() {
        const failedCount = this.analysisData.statistics.failed || 0;
        
        return `
            <div class="card no-print">
                <h2 class="card-title">🚀 ${t('interface.sections.availableActions')}</h2>
                <p style="text-align: center; margin-bottom: 20px;">
                    ${failedCount > 0 ? 
                        t('interface.messages.failedChecksFound', { count: failedCount }) : 
                        t('interface.messages.allChecksPassed')
                    }
                </p>
                <div class="btn-group" style="justify-content: center;">
                    <button class="btn btn-primary" onclick="app.generateRemediationScript()">
                        📝 ${t('interface.buttons.generateScript')}
                    </button>
                    <button class="btn btn-secondary" onclick="window.print()">
                        📄 ${t('interface.buttons.export')}
                    </button>
                    <button class="btn btn-danger" onclick="app.runNewAnalysis()">
                        🔄 ${t('interface.buttons.newAnalysis')}
                    </button>
                </div>
            </div>
        `;
    },

    // Filter results
    filterResults(filter) {
        this.currentFilter = filter;
        
        // Update filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
            if (btn.onclick && btn.onclick.toString().includes(filter)) {
                btn.classList.add('active');
            }
        });
        
        // Generate filtered results
        const resultsContainer = document.getElementById('results-list');
        if (!resultsContainer) return;
        
        let html = '';
        let displayCount = 0;
        
        this.analysisData.results.forEach((result, index) => {
            if (filter === 'all' || result.status === filter) {
                const check = this.analysisData.checks[index] || {};
                html += this.generateCheckResult(result, check, index);
                displayCount++;
            }
        });
        
        if (displayCount === 0) {
            html = `<p style="text-align: center; color: #666; padding: 40px;">
                ${t('interface.messages.noResults')}
            </p>`;
        }
        
        resultsContainer.innerHTML = html;
    },

    // Generate single check result
    generateCheckResult(result, check, index) {
        const statusLabel = t(`interface.status.${result.status}`);
        const hasRemediaton = check.fixCommand && result.status === 'fail';
        
        return `
            <div class="check-result ${result.status}">
                <div class="check-header">
                    <h3 class="check-title">${result.title || check.title || 'Check ' + (index + 1)}</h3>
                    <span class="check-status status-${result.status}">${statusLabel}</span>
                </div>
                ${check.description ? 
                    `<p class="check-details">${check.description}</p>` : 
                    ''
                }
                ${result.details ? 
                    `<p class="check-details"><strong>${t('interface.labels.details')}:</strong> ${this.escapeHtml(result.details)}</p>` : 
                    ''
                }
                ${result.error ? 
                    `<p class="check-details" style="color: var(--danger);">
                        <strong>${t('interface.labels.error')}:</strong> ${this.escapeHtml(result.error)}
                    </p>` : 
                    ''
                }
                ${hasRemediaton ? 
                    `<div class="check-actions no-print">
                        <button class="btn btn-primary btn-sm" onclick="app.showRemediation(${index})">
                            🔧 ${t('interface.buttons.showFix')}
                        </button>
                    </div>` : 
                    ''
                }
            </div>
        `;
    },

    // Show error message
    showError() {
        document.getElementById('content').innerHTML = `
            <div class="error-message">
                <h2>⚠️ ${t('interface.messages.errorLoading')}</h2>
                <p>${t('interface.messages.errorLoadingDetails')}</p>
                <p style="margin-top: 15px;">
                    <button class="btn btn-primary" onclick="location.reload()">
                        🔄 ${t('interface.buttons.refresh')}
                    </button>
                </p>
            </div>
        `;
    },

    // Show remediation details
    showRemediation(index) {
        const check = this.analysisData.checks[index];
        const result = this.analysisData.results[index];
        
        if (!check) return;
        
        const modal = document.getElementById('remediationModal');
        const modalTitle = document.getElementById('modalTitle');
        const modalContent = document.getElementById('modalContent');
        
        modalTitle.textContent = check.title || result.title;
        
        let content = `
            <div class="remediation-details">
                <h3>🔧 ${t('interface.sections.remediation')}</h3>
        `;
        
        if (check.description) {
            content += `<p style="margin-bottom: 20px;">${check.description}</p>`;
        }
        
        // Local fix command
        if (check.fixCommand) {
            content += `
                <h4>${t('interface.labels.command')}:</h4>
                <div class="code-block">${this.escapeHtml(check.fixCommand)}</div>
            `;
        }
        
        // GPO information for Windows
        if (check.yaml?.remediation?.windows?.gpo) {
            const gpo = check.yaml.remediation.windows.gpo;
            const lang = TranslationManager.getCurrentLang();
            
            content += `
                <h4>📋 ${t('interface.labels.gpoPath')}:</h4>
                <p>${gpo.path?.[lang] || gpo.path?.en || 'N/A'}</p>
                
                <h4>⚙️ ${t('interface.labels.gpoSetting')}:</h4>
                <p>${gpo.setting?.[lang] || gpo.setting?.en || 'N/A'}</p>
            `;
        }
        
        content += `</div>`;
        
        modalContent.innerHTML = content;
        modal.classList.add('show');
    },

    // Generate remediation script
    generateRemediationScript() {
        const failedChecks = [];
        
        this.analysisData.results.forEach((result, index) => {
            if (result.status === 'fail') {
                const check = this.analysisData.checks[index];
                if (check && check.fixCommand) {
                    failedChecks.push({ result, check, index });
                }
            }
        });
        
        if (failedChecks.length === 0) {
            alert(t('interface.messages.noFailedChecksWithFixes'));
            return;
        }
        
        const isWindows = this.analysisData.system.os?.toLowerCase().includes('windows');
        let script = '';
        
        if (isWindows) {
            script = this.generateWindowsScript(failedChecks);
        } else {
            script = this.generateLinuxScript(failedChecks);
        }
        
        this.showScriptModal(script, isWindows);
    },

    // Generate Windows PowerShell script
    generateWindowsScript(checks) {
        const date = new Date().toLocaleString();
        let script = `# Security Hardening Remediation Script
# Generated: ${date}
# Checks to fix: ${checks.length}

# Verify administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "Starting security remediation..." -ForegroundColor Green
$success = 0
$failed = 0

`;

        checks.forEach(({ check }) => {
            script += `
# ${check.title}
Write-Host "`n[*] Applying: ${check.title}" -ForegroundColor Yellow
try {
    ${check.fixCommand}
    Write-Host "[✓] Success" -ForegroundColor Green
    $success++
} catch {
    Write-Host "[✗] Failed: $_" -ForegroundColor Red
    $failed++
}
`;
        });

        script += `
Write-Host "`nRemediation complete!" -ForegroundColor Cyan
Write-Host "Success: $success" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`nAll remediations applied successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSome remediations failed. Please check the errors above." -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
`;

        return script;
    },

    // Generate Linux Bash script
    generateLinuxScript(checks) {
        const date = new Date().toLocaleString();
        let script = `#!/bin/bash
# Security Hardening Remediation Script
# Generated: ${date}
# Checks to fix: ${checks.length}

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
CYAN='\\033[0;36m'
NC='\\033[0m'

# Verify root privileges
if [ "$EUID" -ne 0 ]; then 
    echo -e "\${RED}This script must be run as root\${NC}"
    exit 1
fi

echo -e "\${GREEN}Starting security remediation...\${NC}"
success=0
failed=0

`;

        checks.forEach(({ check }) => {
            script += `
# ${check.title}
echo -e "\\n\${YELLOW}[*] Applying: ${check.title}\${NC}"
if ${check.fixCommand}; then
    echo -e "\${GREEN}[✓] Success\${NC}"
    ((success++))
else
    echo -e "\${RED}[✗] Failed\${NC}"
    ((failed++))
fi
`;
        });

        script += `
echo -e "\\n\${CYAN}Remediation complete!\${NC}"
echo -e "\${GREEN}Success: $success\${NC}"
echo -e "\${RED}Failed: $failed\${NC}"

if [ $failed -eq 0 ]; then
    echo -e "\\n\${GREEN}All remediations applied successfully!\${NC}"
else
    echo -e "\\n\${YELLOW}Some remediations failed. Please check the errors above.\${NC}"
fi

echo -e "\\nPress any key to exit..."
read -n 1 -s
`;

        return script;
    },

    // Show script in modal
    showScriptModal(script, isWindows) {
        const modal = document.getElementById('remediationModal');
        const modalTitle = document.getElementById('modalTitle');
        const modalContent = document.getElementById('modalContent');
        
        modalTitle.textContent = t('interface.messages.scriptGenerated');
        
        const extension = isWindows ? 'ps1' : 'sh';
        const filename = `remediation-${Date.now()}.${extension}`;
        const encodedScript = btoa(unescape(encodeURIComponent(script)));
        
        modalContent.innerHTML = `
            <div class="script-preview">
                <p>${t('interface.messages.scriptDescription')}</p>
                <div class="code-block">${this.escapeHtml(script)}</div>
                <div class="btn-group" style="justify-content: center; margin-top: 20px;">
                    <button class="btn btn-primary" onclick="app.downloadScript('${encodedScript}', '${filename}')">
                        💾 ${t('interface.buttons.download')}
                    </button>
                    <button class="btn btn-secondary" onclick="app.copyToClipboard('${encodedScript}')">
                        📋 ${t('interface.buttons.copy')}
                    </button>
                </div>
                <div style="margin-top: 20px; padding: 15px; background: #fff3cd; border-radius: 5px;">
                    <strong>⚠️ ${t('interface.messages.warning')}:</strong>
                    <ul style="margin: 10px 0 0 20px;">
                        <li>${t('interface.messages.testFirst')}</li>
                        <li>${t('interface.messages.makeBackup')}</li>
                        <li>${t('interface.messages.reviewScript')}</li>
                    </ul>
                </div>
            </div>
        `;
        
        modal.classList.add('show');
    },

    // Utility: Escape HTML
    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text).replace(/[&<>"']/g, m => map[m]);
    },

    // Get analysis data
    getData() {
        return this.analysisData;
    }
};