#!/bin/bash
# ===================================================
# Console de Durcissement - Lanceur Linux
# ===================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Récupération du répertoire du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Détection de la langue système
SYSTEM_LANG=${LANG:0:2}
if [ -z "$SYSTEM_LANG" ]; then
    SYSTEM_LANG=${LC_ALL:0:2}
fi
if [ -z "$SYSTEM_LANG" ]; then
    SYSTEM_LANG="en"
fi

# Vérifier si le fichier de langue existe, sinon fallback EN
if [ ! -f "$SCRIPT_DIR/lang/${SYSTEM_LANG}.json" ]; then
    SYSTEM_LANG="en"
fi

# Lire la config si elle existe
if [ -f "$SCRIPT_DIR/config.json" ]; then
    CONFIG_LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' "$SCRIPT_DIR/config.json" 2>/dev/null | cut -d'"' -f4)
    if [ -n "$CONFIG_LANG" ] && [ -f "$SCRIPT_DIR/lang/${CONFIG_LANG}.json" ]; then
        SYSTEM_LANG=$CONFIG_LANG
    fi
fi

# Export pour les sous-scripts
export SCRIPT_LANG=$SYSTEM_LANG

clear

echo ""
if [ "$SCRIPT_LANG" = "fr" ]; then
    echo " ===================================================="
    echo " |                                                  |"
    echo " |     CONSOLE DE DURCISSEMENT SECURITE v1.0        |"
    echo " |                                                  |"
    echo " |        Analyse et securisation Linux             |"
    echo " |                                                  |"
    echo " ===================================================="
else
    echo " ===================================================="
    echo " |                                                  |"
    echo " |       SECURITY HARDENING CONSOLE v1.0            |"
    echo " |                                                  |"
    echo " |         Linux Analysis and Hardening             |"
    echo " |                                                  |"
    echo " ===================================================="
fi
echo ""

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then 
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo -e " ${RED}[ERREUR]${NC} Ce programme doit être exécuté en tant que root"
        echo ""
        echo " Utilisez: sudo ./start.sh"
    else
        echo -e " ${RED}[ERROR]${NC} This program must be run as root"
        echo ""
        echo " Use: sudo ./start.sh"
    fi
    echo ""
    exit 1
fi

if [ "$SCRIPT_LANG" = "fr" ]; then
    echo -e " ${GREEN}[OK]${NC} Droits root détectés"
else
    echo -e " ${GREEN}[OK]${NC} Root privileges detected"
fi
echo ""

# Vérification de bash
if [ ! -x "$(command -v bash)" ]; then
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo -e " ${RED}[ERREUR]${NC} Bash n'est pas installé"
    else
        echo -e " ${RED}[ERROR]${NC} Bash is not installed"
    fi
    echo ""
    exit 1
fi

if [ "$SCRIPT_LANG" = "fr" ]; then
    echo -e " ${GREEN}[OK]${NC} Bash détecté"
else
    echo -e " ${GREEN}[OK]${NC} Bash detected"
fi
echo ""

# Création du dossier temporaire
TEMP_DIR="/tmp/SecurityHardening"
mkdir -p "$TEMP_DIR"

if [ "$SCRIPT_LANG" = "fr" ]; then
    echo -e " ${YELLOW}[*]${NC} Lancement de l'analyse du système..."
    echo "     Cela peut prendre quelques instants..."
else
    echo -e " ${YELLOW}[*]${NC} Starting system analysis..."
    echo "     This may take a few moments..."
fi
echo ""

# Exécution du script d'analyse avec la langue
if bash "$SCRIPT_DIR/scripts/analyze-linux.sh" -l "$SCRIPT_LANG" -o "$TEMP_DIR/results.json" -v "$SCRIPT_DIR/verifications"; then
    echo ""
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo -e " ${GREEN}[OK]${NC} Analyse terminée !"
    else
        echo -e " ${GREEN}[OK]${NC} Analysis complete!"
    fi
    echo ""
    
    # Copie des résultats
    cp "$TEMP_DIR/results.json" "$SCRIPT_DIR/results.json" 2>/dev/null
    
    # Sauvegarder la langue dans la config
    echo "{\"language\":\"$SCRIPT_LANG\",\"lastAnalysis\":\"$(date +%Y-%m-%d)\"}" > "$SCRIPT_DIR/config.json"
    
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo -e " ${YELLOW}[*]${NC} Ouverture de l'interface web..."
    else
        echo -e " ${YELLOW}[*]${NC} Opening web interface..."
    fi
    echo ""
    
    # Détection du navigateur
    if command -v xdg-open > /dev/null; then
        xdg-open "$SCRIPT_DIR/index.html" 2>/dev/null &
    elif command -v gnome-open > /dev/null; then
        gnome-open "$SCRIPT_DIR/index.html" 2>/dev/null &
    elif command -v firefox > /dev/null; then
        firefox "$SCRIPT_DIR/index.html" 2>/dev/null &
    elif command -v chromium > /dev/null; then
        chromium "$SCRIPT_DIR/index.html" 2>/dev/null &
    else
        if [ "$SCRIPT_LANG" = "fr" ]; then
            echo -e " ${YELLOW}[!]${NC} Impossible d'ouvrir automatiquement le navigateur"
        else
            echo -e " ${YELLOW}[!]${NC} Could not automatically open browser"
        fi
    fi
    
    echo " ===================================================="
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo " L'interface devrait s'être ouverte dans votre navigateur."
        echo ""
        echo " Si ce n'est pas le cas, ouvrez manuellement :"
        echo " $SCRIPT_DIR/index.html"
        echo ""
        echo " Vous pouvez fermer cette fenêtre."
    else
        echo " The interface should have opened in your browser."
        echo ""
        echo " If not, please open manually:"
        echo " $SCRIPT_DIR/index.html"
        echo ""
        echo " You can close this window."
    fi
    echo " ===================================================="
    echo ""
else
    echo ""
    if [ "$SCRIPT_LANG" = "fr" ]; then
        echo -e " ${RED}[ERREUR]${NC} L'analyse a échoué"
    else
        echo -e " ${RED}[ERROR]${NC} Analysis failed"
    fi
    echo ""
    exit 1
fi

# Attendre que l'utilisateur appuie sur une touche
if [ "$SCRIPT_LANG" = "fr" ]; then
    read -n 1 -s -r -p "Appuyez sur une touche pour fermer..."
else
    read -n 1 -s -r -p "Press any key to close..."
fi
echo ""