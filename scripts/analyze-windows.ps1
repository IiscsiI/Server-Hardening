# ===================================================
# Script d'analyse de sécurité Windows - Multilingue
# ===================================================

param(
    [string]$Language = "en",
    [string]$OutputPath = "$env:TEMP\SecurityHardening\results.json",
    [string]$VerificationsPath = ".\verifications"
)

# Configuration de l'encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Chargement des traductions
$langFile = Join-Path (Split-Path $PSScriptRoot -Parent) "lang\$Language.json"
if (Test-Path $langFile) {
    $translations = Get-Content $langFile -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    # Fallback to English
    $langFile = Join-Path (Split-Path $PSScriptRoot -Parent) "lang\en.json"
    if (Test-Path $langFile) {
        $translations = Get-Content $langFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $Language = "en"
    } else {
        Write-Error "No language files found"
        exit 1
    }
}

# Helper pour obtenir une traduction
function Get-Translation {
    param([string]$key)
    
    $parts = $key -split '\.'
    $value = $translations
    
    foreach ($part in $parts) {
        if ($value.$part) {
            $value = $value.$part
        } else {
            return $key  # Retourner la clé si traduction non trouvée
        }
    }
    
    return $value
}

# Fonction pour parser les fichiers YAML (améliorée)
function ConvertFrom-Yaml {
    param([string]$YamlContent)
    
    $result = @{}
    $lines = $YamlContent -split "`n"
    $stack = @()
    $currentObj = $result
    $currentIndent = 0
    
    foreach ($line in $lines) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
        
        # Calculer l'indentation
        if ($line -match '^(\s*)(.+)$') {
            $indent = $matches[1].Length
            $content = $matches[2]
            
            # Gérer les changements d'indentation
            if ($indent -lt $currentIndent) {
                $popCount = ($currentIndent - $indent) / 2
                for ($i = 0; $i -lt $popCount; $i++) {
                    if ($stack.Count -gt 0) {
                        $stack = $stack[0..($stack.Count-2)]
                    }
                }
                $currentObj = $result
                foreach ($key in $stack) {
                    $currentObj = $currentObj[$key]
                }
            }
            
            # Parser la ligne
            if ($content -match '^([^:]+):\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                if ($value -eq '') {
                    # C'est un objet
                    $currentObj[$key] = @{}
                    $stack += $key
                    $currentObj = $currentObj[$key]
                    $currentIndent = $indent
                } else {
                    # C'est une valeur
                    $value = $value.Trim('"', "'")
                    $currentObj[$key] = $value
                }
            } elseif ($content -match '^-\s+(.+)$') {
                # C'est un élément de liste
                $listItem = $matches[1].Trim().Trim('"', "'")
                $lastKey = $stack[-1]
                $parentObj = $result
                foreach ($key in $stack[0..($stack.Count-2)]) {
                    $parentObj = $parentObj[$key]
                }
                
                if ($parentObj[$lastKey] -is [array]) {
                    $parentObj[$lastKey] += $listItem
                } else {
                    $parentObj[$lastKey] = @($listItem)
                }
            }
        }
    }
    
    return $result
}

# Fonction pour charger toutes les vérifications
function Get-AllVerifications {
    param([string]$Path, [string]$Lang = "en")
    
    $checks = @()
    $windowsPath = Join-Path $Path "windows"
    
    if (Test-Path $windowsPath) {
        Get-ChildItem -Path $windowsPath -Filter "*.yaml" | ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw -Encoding UTF8
                $yaml = ConvertFrom-Yaml -YamlContent $content
                
                # Extraction du titre dans la langue courante
                $title = if ($yaml.title -and $yaml.title.$Lang) { 
                    $yaml.title.$Lang 
                } elseif ($yaml.title -and $yaml.title.en) {
                    $yaml.title.en
                } else { 
                    $yaml.id 
                }
                
                $description = if ($yaml.description -and $yaml.description.$Lang) {
                    $yaml.description.$Lang
                } elseif ($yaml.description -and $yaml.description.en) {
                    $yaml.description.en
                } else {
                    ""
                }
                
                $check = @{
                    id = $yaml.id
                    title = $title
                    description = $description
                    severity = if ($yaml.severity) { $yaml.severity } else { "medium" }
                    category = if ($yaml.category) { $yaml.category } else { "other" }
                    level = if ($yaml.level) { $yaml.level } else { "basic" }
                    filename = $_.Name
                    yaml = $yaml  # Garder l'objet complet pour référence
                }
                
                # Extraction des commandes
                if ($yaml.check -and $yaml.check.windows -and $yaml.check.windows.command) {
                    $check.checkCommand = $yaml.check.windows.command
                }
                if ($yaml.remediation -and $yaml.remediation.windows -and $yaml.remediation.windows.local -and $yaml.remediation.windows.local.command) {
                    $check.fixCommand = $yaml.remediation.windows.local.command
                }
                
                $checks += $check
            } catch {
                Write-Warning "Error loading $($_.Name): $_"
            }
        }
    }
    
    # Si aucune vérification YAML trouvée, utiliser les vérifications par défaut
    if ($checks.Count -eq 0) {
        Write-Host (Get-Translation "scripts.powershell.usingDefaults") -ForegroundColor Yellow
        
        $checks = @(
            @{
                id = "win-firewall"
                title = Get-Translation "checks.defaultTitles.firewall"
                description = Get-Translation "checks.defaultDescriptions.firewall"
                severity = "critical"
                category = "firewall"
                level = "basic"
                checkCommand = 'Get-NetFirewallProfile | Select-Object Name, Enabled'
                fixCommand = 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True'
            },
            @{
                id = "win-defender"
                title = Get-Translation "checks.defaultTitles.antivirus"
                description = Get-Translation "checks.defaultDescriptions.antivirus"
                severity = "critical"
                category = "antivirus"
                level = "basic"
                checkCommand = 'Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated'
                fixCommand = 'Set-MpPreference -DisableRealtimeMonitoring $false'
            },
            @{
                id = "win-updates"
                title = Get-Translation "checks.defaultTitles.updates"
                description = Get-Translation "checks.defaultDescriptions.updates"
                severity = "high"
                category = "updates"
                level = "basic"
                checkCommand = '(Get-HotFix | Where-Object {$_.InstalledOn -gt (Get-Date).AddDays(-30)}).Count'
                fixCommand = 'Start-Process -FilePath "ms-settings:windowsupdate-action" -WindowStyle Normal'
            }
        )
    }
    
    # Trier par niveau puis sévérité
    return $checks | Sort-Object @{e={@{basic=1;intermediate=2;advanced=3}[$_.level]}}, 
                                 @{e={@{critical=1;high=2;medium=3;low=4}[$_.severity]}}
}

# Fonction pour exécuter une vérification
function Test-SecurityCheck {
    param($Check)
    
    $result = @{
        id = $Check.id
        title = $Check.title
        description = $Check.description
        severity = $Check.severity
        category = $Check.category
        status = "unknown"
        details = ""
        error = $null
    }
    
    if (-not $Check.checkCommand) {
        $result.status = "error"
        $result.error = "No check command defined"
        return $result
    }
    
    try {
        # Exécution de la commande
        $output = Invoke-Expression $Check.checkCommand 2>&1 | Out-String
        
        # Analyse des résultats selon le type de vérification
        switch ($Check.id) {
            {$_ -match "firewall"} {
                if ($output -match "Enabled\s*:\s*True" -and $output -notmatch "Enabled\s*:\s*False") {
                    $result.status = "pass"
                    $result.details = "Firewall enabled on all profiles"
                } else {
                    $result.status = "fail"
                    $result.details = "Firewall disabled on one or more profiles"
                }
            }
            {$_ -match "defender|antivirus"} {
                if ($output -match "AntivirusEnabled\s*:\s*True" -and $output -match "RealTimeProtectionEnabled\s*:\s*True") {
                    $result.status = "pass"
                    $result.details = "Antivirus enabled with real-time protection"
                } else {
                    $result.status = "fail"
                    $result.details = "Antivirus disabled or real-time protection inactive"
                }
            }
            {$_ -match "updates"} {
                $recentUpdates = [int]($output.Trim())
                if ($recentUpdates -gt 0) {
                    $result.status = "pass"
                    $result.details = "$recentUpdates recent updates installed"
                } else {
                    $result.status = "fail"
                    $result.details = "No recent updates found"
                }
            }
            default {
                # Pour les autres vérifications, considérer comme info
                $result.status = "info"
                $result.details = $output.Trim()
            }
        }
        
        # Limiter la taille des détails
        if ($result.details.Length -gt 500) {
            $result.details = $result.details.Substring(0, 497) + "..."
        }
        
    } catch {
        $result.status = "error"
        $result.error = $_.Exception.Message
    }
    
    return $result
}

# Fonction principale
function Start-SecurityAnalysis {
    Write-Host (Get-Translation "scripts.powershell.starting") -ForegroundColor Green
    
    # Informations système
    $os = Get-CimInstance Win32_OperatingSystem
    $systemInfo = @{
        hostname = $env:COMPUTERNAME
        os = $os.Caption
        osVersion = $os.Version
        osBuild = $os.BuildNumber
        lastBoot = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
        currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        analysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        language = $Language
    }
    
    Write-Host (Get-Translation "scripts.powershell.loadingChecks")
    $checks = Get-AllVerifications -Path $VerificationsPath -Lang $Language
    $message = (Get-Translation "scripts.powershell.checksLoaded") -replace '{count}', $checks.Count
    Write-Host "  -> $message" -ForegroundColor Yellow
    
    # Exécution des vérifications
    $results = @()
    $i = 1
    
    foreach ($check in $checks) {
        $progress = "[$i/$($checks.Count)]"
        $message = (Get-Translation "scripts.powershell.analyzing") -replace '{title}', $check.title
        Write-Host "$progress $message" -NoNewline
        
        $result = Test-SecurityCheck -Check $check
        $results += $result
        
        switch ($result.status) {
            "pass" { Write-Host " $(Get-Translation 'scripts.powershell.statusPass')" -ForegroundColor Green }
            "fail" { Write-Host " $(Get-Translation 'scripts.powershell.statusFail')" -ForegroundColor Red }
            "error" { Write-Host " $(Get-Translation 'scripts.powershell.statusError')" -ForegroundColor Yellow }
            default { Write-Host " $(Get-Translation 'scripts.powershell.statusInfo')" -ForegroundColor Cyan }
        }
        
        $i++
    }
    
    # Calcul des statistiques
    $stats = @{
        total = $results.Count
        passed = ($results | Where-Object { $_.status -eq "pass" }).Count
        failed = ($results | Where-Object { $_.status -eq "fail" }).Count
        errors = ($results | Where-Object { $_.status -eq "error" }).Count
        info = ($results | Where-Object { $_.status -eq "info" }).Count
    }
    
    # Création du rapport
    $report = @{
        system = $systemInfo
        statistics = $stats
        checks = $checks
        results = $results
        metadata = @{
            version = "1.0"
            date = Get-Date -Format "yyyy-MM-