#!/bin/bash
# ===================================================
# Script d'analyse de sécurité Linux - Multilingue
# ===================================================

# Variables par défaut
OUTPUT_PATH="/tmp/SecurityHardening/results.json"
VERIFICATIONS_PATH="./verifications"
LANGUAGE="en"

# Traitement des arguments
while getopts "o:v:l:" opt; do
    case $opt in
        o) OUTPUT_PATH="$OPTARG";;
        v) VERIFICATIONS_PATH="$OPTARG";;
        l) LANGUAGE="$OPTARG";;
        *) echo "Usage: $0 -o output_path -v verifications_path -l language"; exit 1;;
    esac
done

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Récupération du répertoire du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Chargement des traductions
LANG_FILE="$(dirname "$SCRIPT_DIR")/lang/${LANGUAGE}.json"
if [ ! -f "$LANG_FILE" ]; then
    LANG_FILE="$(dirname "$SCRIPT_DIR")/lang/en.json"
    LANGUAGE="en"
fi

# Fonction pour obtenir une traduction (utilise jq si disponible, sinon grep)
get_translation() {
    local key=$1
    if command -v jq &> /dev/null; then
        echo "$TRANSLATIONS" | jq -r ".$key // \"$key\""
    else
        # Fallback basique sans jq
        case "$key" in
            "scripts.bash.starting")
                [ "$LANGUAGE" = "fr" ] && echo "Démarrage de l'analyse de sécurité..." || echo "Starting security analysis..."
                ;;
            "scripts.bash.loadingChecks")
                [ "$LANGUAGE" = "fr" ] && echo "Chargement des vérifications..." || echo "Loading checks..."
                ;;
            "scripts.bash.checksLoaded")
                [ "$LANGUAGE" = "fr" ] && echo "vérifications chargées" || echo "checks loaded"
                ;;
            "scripts.bash.analyzing")
                [ "$LANGUAGE" = "fr" ] && echo "Vérification en cours..." || echo "Checking..."
                ;;
            "scripts.bash.analysisComplete")
                [ "$LANGUAGE" = "fr" ] && echo "Analyse terminée !" || echo "Analysis complete!"
                ;;
            "scripts.bash.summary")
                [ "$LANGUAGE" = "fr" ] && echo "Résumé:" || echo "Summary:"
                ;;
            *)
                echo "$key"
                ;;
        esac
    fi
}

# Charger les traductions si jq est disponible
if command -v jq &> /dev/null && [ -f "$LANG_FILE" ]; then
    TRANSLATIONS=$(cat "$LANG_FILE")
fi

# Fonction de détection de distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID=$ID
        DISTRO_NAME="$NAME"
        DISTRO_VERSION=$VERSION_ID
        DISTRO_FAMILY=""
        
        # Déterminer la famille
        case $DISTRO_ID in
            ubuntu|debian|mint|elementary|pop|zorin)
                DISTRO_FAMILY="debian"
                ;;
            rhel|centos|fedora|rocky|almalinux|oracle)
                DISTRO_FAMILY="rhel"
                ;;
            opensuse*|suse*)
                DISTRO_FAMILY="suse"
                ;;
            arch|manjaro|endeavouros)
                DISTRO_FAMILY="arch"
                ;;
            alpine)
                DISTRO_FAMILY="alpine"
                ;;
            *)
                DISTRO_FAMILY="unknown"
                ;;
        esac
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
        DISTRO_VERSION=""
        DISTRO_FAMILY="unknown"
    fi
    
    export DISTRO_ID DISTRO_NAME DISTRO_VERSION DISTRO_FAMILY
}

# Fonction pour parser les fichiers YAML (simplifiée)
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_-]*'
    local fs=$(echo @|tr @ '\034')
    
    # Reset des variables
    unset $(compgen -v | grep "^${prefix}")
    
    # Parser le YAML
    local yaml_content=$(cat "$yaml_file")
    
    # Extraction basique des champs principaux
    eval "${prefix}id=\"$(echo "$yaml_content" | grep "^id:" | cut -d: -f2- | xargs)\""
    eval "${prefix}severity=\"$(echo "$yaml_content" | grep "^severity:" | cut -d: -f2- | xargs)\""
    eval "${prefix}category=\"$(echo "$yaml_content" | grep "^category:" | cut -d: -f2- | xargs)\""
    eval "${prefix}level=\"$(echo "$yaml_content" | grep "^level:" | cut -d: -f2- | xargs)\""
    
    # Extraction du titre dans la langue
    local title_section=$(echo "$yaml_content" | sed -n '/^title:/,/^[a-z]/p')
    local title=$(echo "$title_section" | grep "  ${LANGUAGE}:" | cut -d: -f2- | xargs | tr -d '"')
    if [ -z "$title" ]; then
        title=$(echo "$title_section" | grep "  en:" | cut -d: -f2- | xargs | tr -d '"')
    fi
    eval "${prefix}title=\"$title\""
    
    # Extraction de la description dans la langue
    local desc_section=$(echo "$yaml_content" | sed -n '/^description:/,/^[a-z]/p')
    local desc=$(echo "$desc_section" | grep "  ${LANGUAGE}:" | cut -d: -f2- | xargs | tr -d '"')
    if [ -z "$desc" ]; then
        desc=$(echo "$desc_section" | grep "  en:" | cut -d: -f2- | xargs | tr -d '"')
    fi
    eval "${prefix}description=\"$desc\""
}

# Fonction pour extraire la commande Linux appropriée
get_linux_command() {
    local yaml_file=$1
    local yaml_content=$(cat "$yaml_file")
    local command=""
    
    # Chercher la section check.linux
    local linux_section=$(echo "$yaml_content" | sed -n '/^check:/,/^[a-z]/p' | sed -n '/  linux:/,/^  [a-z]/p')
    
    # Essayer de trouver une commande spécifique à la distribution
    if [ -n "$linux_section" ]; then
        # Chercher commande spécifique à la distro
        command=$(echo "$linux_section" | grep -A1 "    ${DISTRO_ID}:" | tail -1 | grep "      command:" | cut -d: -f2- | xargs | tr -d '"')
        
        # Si pas trouvé, chercher par famille
        if [ -z "$command" ]; then
            command=$(echo "$linux_section" | grep -A1 "    ${DISTRO_FAMILY}:" | tail -1 | grep "      command:" | cut -d: -f2- | xargs | tr -d '"')
        fi
        
        # Si pas trouvé, chercher universal
        if [ -z "$command" ]; then
            command=$(echo "$linux_section" | grep -A1 "    universal:" | tail -1 | grep "      command:" | cut -d: -f2- | xargs | tr -d '"')
        fi
        
        # Si pas trouvé, chercher command direct
        if [ -z "$command" ]; then
            command=$(echo "$linux_section" | grep "    command:" | head -1 | cut -d: -f2- | xargs | tr -d '"')
        fi
    fi
    
    echo "$command"
}

# Fonction pour charger toutes les vérifications
load_all_checks() {
    local checks_json="["
    local count=0
    local linux_path="$VERIFICATIONS_PATH/linux"
    
    if [ -d "$linux_path" ]; then
        for yaml_file in "$linux_path"/*.yaml; do
            if [ -f "$yaml_file" ]; then
                # Parser le YAML
                parse_yaml "$yaml_file" "check_"
                
                # Obtenir la commande appropriée
                local command=$(get_linux_command "$yaml_file")
                
                # Créer l'objet JSON
                [ $count -gt 0 ] && checks_json+=","
                checks_json+="{
                    \"id\": \"${check_id:-unknown}\",
                    \"title\": \"${check_title:-Unknown check}\",
                    \"description\": \"${check_description:-}\",
                    \"severity\": \"${check_severity:-medium}\",
                    \"category\": \"${check_category:-other}\",
                    \"level\": \"${check_level:-basic}\",
                    \"filename\": \"$(basename "$yaml_file")\",
                    \"checkCommand\": \"$command\"
                }"
                ((count++))
            fi
        done
    fi
    
    # Si aucune vérification trouvée, utiliser les défauts
    if [ $count -eq 0 ]; then
        checks_json+="{
            \"id\": \"linux-firewall\",
            \"title\": \"$([ "$LANGUAGE" = "fr" ] && echo "État du pare-feu" || echo "Firewall status")\",
            \"description\": \"$([ "$LANGUAGE" = "fr" ] && echo "Vérifie qu'un pare-feu est actif" || echo "Checks if firewall is active")\",
            \"severity\": \"critical\",
            \"category\": \"firewall\",
            \"level\": \"basic\",
            \"checkCommand\": \"systemctl is-active ufw 2>/dev/null || systemctl is-active firewalld 2>/dev/null || echo 'inactive'\"
        },{
            \"id\": \"linux-updates\",
            \"title\": \"$([ "$LANGUAGE" = "fr" ] && echo "Mises à jour système" || echo "System updates")\",
            \"description\": \"$([ "$LANGUAGE" = "fr" ] && echo "Vérifie les mises à jour disponibles" || echo "Checks for available updates")\",
            \"severity\": \"high\",
            \"category\": \"updates\",
            \"level\": \"basic\",
            \"checkCommand\": \"apt list --upgradable 2>/dev/null | grep -c upgradable || yum check-update 2>/dev/null | grep -c '^[[:alnum:]]' || echo 0\"
        },{
            \"id\": \"linux-ssh-root\",
            \"title\": \"$([ "$LANGUAGE" = "fr" ] && echo "Connexion SSH root" || echo "SSH root login")\",
            \"description\": \"$([ "$LANGUAGE" = "fr" ] && echo "Vérifie que la connexion root est désactivée" || echo "Checks if root login is disabled")\",
            \"severity\": \"critical\",
            \"category\": \"ssh\",
            \"level\": \"basic\",
            \"checkCommand\": \"grep '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null || echo 'PermitRootLogin yes'\"
        }"
        count=3
    fi
    
    checks_json+="]"
    echo "$checks_json"
    return $count
}

# Fonction pour exécuter une vérification
execute_check() {
    local check_json="$1"
    local check_id=$(echo "$check_json" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    local check_cmd=$(echo "$check_json" | grep -o '"checkCommand"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    local result_status="unknown"
    local result_details=""
    local result_error=""
    
    if [ -z "$check_cmd" ] || [ "$check_cmd" = "null" ]; then
        result_status="error"
        result_error="No check command defined"
    else
        # Exécution de la commande
        local output=$(eval "$check_cmd" 2>&1)
        local exit_code=$?
        
        # Analyse des résultats selon le type de vérification
        case "$check_id" in
            *firewall*)
                if [[ "$output" == "active" ]] || [[ "$output" == "running" ]]; then
                    result_status="pass"
                    result_details="Firewall is active"
                else
                    result_status="fail"
                    result_details="Firewall is inactive or not installed"
                fi
                ;;
            *ssh*root*)
                if [[ "$output" =~ "PermitRootLogin no" ]] || [[ "$output" =~ "PermitRootLogin prohibit-password" ]]; then
                    result_status="pass"
                    result_details="Root SSH login is disabled"
                else
                    result_status="fail"
                    result_details="Root SSH login is allowed"
                fi
                ;;
            *updates*)
                if [[ "$output" == "0" ]] || [[ -z "$output" ]]; then
                    result_status="pass"
                    result_details="System is up to date"
                else
                    result_status="fail"
                    result_details="$output updates available"
                fi
                ;;
            *)
                # Autres vérifications
                if [ $exit_code -eq 0 ]; then
                    result_status="info"
                else
                    result_status="error"
                fi
                result_details="${output:0:500}"
                ;;
        esac
    fi
    
    # Créer l'objet résultat
    echo "{
        \"id\": \"$check_id\",
        \"status\": \"$result_status\",
        \"details\": \"$result_details\",
        \"error\": \"$result_error\"
    }"
}

# Fonction principale
main() {
    echo -e "${GREEN}$(get_translation "scripts.bash.starting")${NC}"
    
    # Détection de la distribution
    detect_distro
    
    # Informations système
    local hostname=$(hostname)
    local kernel=$(uname -r)
    local uptime=$(uptime -p 2>/dev/null || uptime)
    local current_user=$(whoami)
    local is_root=$([[ $EUID -eq 0 ]] && echo "true" || echo "false")
    local analysis_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Chargement des vérifications
    echo "$(get_translation "scripts.bash.loadingChecks")"
    local checks_json=$(load_all_checks)
    local check_count=$?
    echo -e "  -> ${YELLOW}$check_count $(get_translation "scripts.bash.checksLoaded")${NC}"
    
    # Exécution des vérifications
    local results_json="["
    local total=0
    local passed=0
    local failed=0
    local errors=0
    local info=0
    
    # Traiter chaque vérification
    if command -v jq &> /dev/null; then
        # Avec jq
        while IFS= read -r check; do
            ((total++))
            echo -ne "[$total/$check_count] $(get_translation "scripts.bash.analyzing")"
            
            local result=$(execute_check "$check")
            local status=$(echo "$result" | jq -r '.status')
            
            case "$status" in
                "pass")
                    echo -e " ${GREEN}[OK]${NC}"
                    ((passed++))
                    ;;
                "fail")
                    echo -e " ${RED}[FAIL]${NC}"
                    ((failed++))
                    ;;
                "error")
                    echo -e " ${YELLOW}[ERROR]${NC}"
                    ((errors++))
                    ;;
                *)
                    echo -e " ${CYAN}[INFO]${NC}"
                    ((info++))
                    ;;
            esac
            
            [ $total -gt 1 ] && results_json+=","
            results_json+="$result"
        done < <(echo "$checks_json" | jq -c '.[]')
    else
        # Sans jq - utiliser les vérifications par défaut
        local default_checks=("linux-firewall" "linux-updates" "linux-ssh-root")
        for check_id in "${default_checks[@]}"; do
            ((total++))
            echo -ne "[$total/3] $(get_translation "scripts.bash.analyzing")"
            
            case "$check_id" in
                "linux-firewall")
                    local status=$(systemctl is-active ufw 2>/dev/null || systemctl is-active firewalld 2>/dev/null || echo 'inactive')
                    if [[ "$status" == "active" ]]; then
                        echo -e " ${GREEN}[OK]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"pass\",\"details\":\"Firewall active\"}"
                        ((passed++))
                    else
                        echo -e " ${RED}[FAIL]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"fail\",\"details\":\"Firewall inactive\"}"
                        ((failed++))
                    fi
                    ;;
                "linux-updates")
                    local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable || yum check-update 2>/dev/null | grep -c '^[[:alnum:]]' || echo 0)
                    if [[ "$updates" == "0" ]]; then
                        echo -e " ${GREEN}[OK]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"pass\",\"details\":\"System up to date\"}"
                        ((passed++))
                    else
                        echo -e " ${RED}[FAIL]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"fail\",\"details\":\"$updates updates available\"}"
                        ((failed++))
                    fi
                    ;;
                "linux-ssh-root")
                    local ssh_root=$(grep '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null || echo 'PermitRootLogin yes')
                    if [[ "$ssh_root" =~ "PermitRootLogin no" ]]; then
                        echo -e " ${GREEN}[OK]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"pass\",\"details\":\"Root SSH disabled\"}"
                        ((passed++))
                    else
                        echo -e " ${RED}[FAIL]${NC}"
                        [ $total -gt 1 ] && results_json+=","
                        results_json+="{\"id\":\"$check_id\",\"status\":\"fail\",\"details\":\"Root SSH enabled\"}"
                        ((failed++))
                    fi
                    ;;
            esac
        done
    fi
    
    results_json+="]"
    
    echo -e "\n${GREEN}$(get_translation "scripts.bash.analysisComplete")${NC}"
    echo -e "\n${CYAN}$(get_translation "scripts.bash.summary")${NC}"
    echo -e "  - $([ "$LANGUAGE" = "fr" ] && echo "Conformes" || echo "Passed"): ${GREEN}$passed${NC}"
    echo -e "  - $([ "$LANGUAGE" = "fr" ] && echo "Non conformes" || echo "Failed"): ${RED}$failed${NC}"
    echo -e "  - $([ "$LANGUAGE" = "fr" ] && echo "Erreurs" || echo "Errors"): ${YELLOW}$errors${NC}"
    echo -e "  - $([ "$LANGUAGE" = "fr" ] && echo "Informatifs" || echo "Info"): ${CYAN}$info${NC}"
    
    # Création du rapport final
    local report_json="{
    \"system\": {
        \"hostname\": \"$hostname\",
        \"os\": \"$DISTRO_NAME\",
        \"distro\": \"$DISTRO_ID\",
        \"distroFamily\": \"$DISTRO_FAMILY\",
        \"distroVersion\": \"$DISTRO_VERSION\",
        \"kernel\": \"$kernel\",
        \"uptime\": \"$uptime\",
        \"currentUser\": \"$current_user\",
        \"isRoot\": $is_root,
        \"analysisDate\": \"$analysis_date\",
        \"language\": \"$LANGUAGE\"
    },
    \"statistics\": {
        \"total\": $total,
        \"passed\": $passed,
        \"failed\": $failed,
        \"errors\": $errors,
        \"info\": $info
    },
    \"checks\": $checks_json,
    \"results\": $results_json,
    \"metadata\": {
        \"version\": \"1.0\",
        \"date\": \"$analysis_date\",
        \"language\": \"$LANGUAGE\"
    }
}"
    
    # Assurer que le dossier de sortie existe
    local output_dir=$(dirname "$OUTPUT_PATH")
    mkdir -p "$output_dir"
    
    # Sauvegarder les résultats
    echo "$report_json" > "$OUTPUT_PATH"
    
    echo -e "${YELLOW}$([ "$LANGUAGE" = "fr" ] && echo "Résultats sauvegardés dans:" || echo "Results saved to:") $OUTPUT_PATH${NC}"
}

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}$([ "$LANGUAGE" = "fr" ] && echo "Ce script doit être exécuté en tant que root" || echo "This script must be run as root")${NC}"
    exit 1
fi

# Lancement de l'analyse
main

exit 0