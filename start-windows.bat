@echo off
REM ===================================================
REM Console de Durcissement - Lanceur Windows
REM ===================================================

setlocal enabledelayedexpansion

REM Détection du répertoire du script
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Détection de la langue système
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v InstallLanguage 2^>nul') do set LANG_ID=%%a

REM Mapping des codes de langue Windows
set SYSTEM_LANG=en
if "%LANG_ID%"=="040C" set SYSTEM_LANG=fr
if "%LANG_ID%"=="080C" set SYSTEM_LANG=fr
if "%LANG_ID%"=="0C0C" set SYSTEM_LANG=fr
if "%LANG_ID%"=="100C" set SYSTEM_LANG=fr
if "%LANG_ID%"=="0407" set SYSTEM_LANG=de
if "%LANG_ID%"=="0C07" set SYSTEM_LANG=de
if "%LANG_ID%"=="0807" set SYSTEM_LANG=de
if "%LANG_ID%"=="040A" set SYSTEM_LANG=es
if "%LANG_ID%"=="080A" set SYSTEM_LANG=es

REM Vérifier si la langue existe, sinon fallback EN
if not exist "%SCRIPT_DIR%lang\%SYSTEM_LANG%.json" set SYSTEM_LANG=en

REM Lire la config si elle existe
set CONFIG_LANG=
if exist "%SCRIPT_DIR%config.json" (
    for /f "tokens=2 delims=:," %%a in ('findstr /C:"\"language\"" "%SCRIPT_DIR%config.json"') do (
        set CONFIG_LANG=%%a
        set CONFIG_LANG=!CONFIG_LANG:"=!
        set CONFIG_LANG=!CONFIG_LANG: =!
    )
)

REM Utiliser la langue de la config si elle existe
if defined CONFIG_LANG (
    if exist "%SCRIPT_DIR%lang\!CONFIG_LANG!.json" (
        set SYSTEM_LANG=!CONFIG_LANG!
    )
)

REM Définir la variable pour PowerShell
set SCRIPT_LANG=%SYSTEM_LANG%

REM Affichage selon la langue
title Console de Durcissement / Security Hardening Console
color 0A

echo.
if "%SCRIPT_LANG%"=="fr" (
    echo  ====================================================
    echo  ^|                                                  ^|
    echo  ^|     CONSOLE DE DURCISSEMENT SECURITE v1.0        ^|
    echo  ^|                                                  ^|
    echo  ^|     Analyse et securisation Windows Server       ^|
    echo  ^|                                                  ^|
    echo  ====================================================
) else (
    echo  ====================================================
    echo  ^|                                                  ^|
    echo  ^|     SECURITY HARDENING CONSOLE v1.0              ^|
    echo  ^|                                                  ^|
    echo  ^|     Windows Server Analysis and Hardening        ^|
    echo  ^|                                                  ^|
    echo  ====================================================
)
echo.

REM Vérification des droits administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    if "%SCRIPT_LANG%"=="fr" (
        echo  [ERREUR] Ce programme doit etre execute en tant qu'administrateur
        echo.
        echo  Faites un clic droit sur start.bat et selectionnez
        echo  "Executer en tant qu'administrateur"
    ) else (
        echo  [ERROR] This program must be run as administrator
        echo.
        echo  Right-click on start.bat and select
        echo  "Run as administrator"
    )
    echo.
    pause
    exit /b 1
)

if "%SCRIPT_LANG%"=="fr" (
    echo  [OK] Droits administrateur detectes
) else (
    echo  [OK] Administrator rights detected
)
echo.

REM Vérification de PowerShell
where powershell >nul 2>&1
if %errorLevel% neq 0 (
    if "%SCRIPT_LANG%"=="fr" (
        echo  [ERREUR] PowerShell n'est pas installe
    ) else (
        echo  [ERROR] PowerShell is not installed
    )
    echo.
    pause
    exit /b 1
)

if "%SCRIPT_LANG%"=="fr" (
    echo  [OK] PowerShell detecte
) else (
    echo  [OK] PowerShell detected
)
echo.

REM Création du dossier temporaire
if not exist "%TEMP%\SecurityHardening" mkdir "%TEMP%\SecurityHardening"

if "%SCRIPT_LANG%"=="fr" (
    echo  [*] Lancement de l'analyse du systeme...
    echo      Cela peut prendre quelques instants...
) else (
    echo  [*] Starting system analysis...
    echo      This may take a few moments...
)
echo.

REM Exécution du script PowerShell d'analyse avec la langue
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%scripts\analyze-windows.ps1" -Language "%SCRIPT_LANG%" -OutputPath "%TEMP%\SecurityHardening\results.json" -VerificationsPath "%SCRIPT_DIR%verifications"

if %errorLevel% neq 0 (
    echo.
    if "%SCRIPT_LANG%"=="fr" (
        echo  [ERREUR] L'analyse a echoue
    ) else (
        echo  [ERROR] Analysis failed
    )
    echo.
    pause
    exit /b 1
)

echo.
if "%SCRIPT_LANG%"=="fr" (
    echo  [OK] Analyse terminee !
    echo.
    echo  [*] Ouverture de l'interface web...
) else (
    echo  [OK] Analysis complete!
    echo.
    echo  [*] Opening web interface...
)
echo.

REM Copie du fichier de résultats pour l'interface
copy /Y "%TEMP%\SecurityHardening\results.json" "%SCRIPT_DIR%results.json" >nul 2>&1

REM Sauvegarder la langue dans la config
echo {"language":"%SCRIPT_LANG%","lastAnalysis":"%date%"} > "%SCRIPT_DIR%config.json"

REM Ouverture de l'interface dans le navigateur par défaut
start "" "%SCRIPT_DIR%index.html"

echo.
if "%SCRIPT_LANG%"=="fr" (
    echo  ====================================================
    echo  L'interface s'est ouverte dans votre navigateur.
    echo.
    echo  Si ce n'est pas le cas, ouvrez manuellement :
    echo  %SCRIPT_DIR%index.html
    echo.
    echo  Vous pouvez fermer cette fenetre.
    echo  ====================================================
) else (
    echo  ====================================================
    echo  The interface has opened in your browser.
    echo.
    echo  If not, please open manually:
    echo  %SCRIPT_DIR%index.html
    echo.
    echo  You can close this window.
    echo  ====================================================
)
echo.
pause