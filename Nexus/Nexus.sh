#!/bin/bash

# Initialisation du mode debug et de ses variables
if [ "$1" = "--debug" ]; then
    declare -ra NEXUS_DEBUG_MODULES=("${@:2}")
    NEXUS_DEBUG=true
    NEXUS_CALLED_BY=debug
else
    NEXUS_DEBUG=false
    NEXUS_CALLED_BY=$(basename "${BASH_SOURCE[1]%.sh}")
fi

# Définition du chemin racine de Nexus.sh
NEXUS_ROOTPATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")

readonly NEXUS_DEBUG
readonly NEXUS_CALLED_BY
readonly NEXUS_ROOTPATH

# Vérifie si le script est exécuté directement sans passer par le debug mode
if [ -z "$NEXUS_CALLED_BY" ]; then
    log_msg=(
        "Nexus.sh n'est pas conçu pour être exécuté mais pour être sourcé."
        "Pour une utilisation en mode debug : ./Nexus.sh --debug"
    )
    Logger_write_simple_line "${log_msg[*]}"
    Logger_display_error "${log_msg[0]}"
    Logger_display_infos "${log_msg[1]}"
    exit 1
fi

# Chemin d'accès aux modules du framework
readonly NEXUS_MODULES_PATH="$NEXUS_ROOTPATH/.."

# Déclaration des structures pour gérer les modules
declare -A NEXUS_MODULE_DEPENDENCIES    # Dépendances des modules
declare -A NEXUS_AVAILABLE_MODULES      # Modules disponibles
declare -A NEXUS_REQUIRED_MODULES       # Modules requis
declare -a NEXUS_MISSING_MODULES        # Modules manquants
declare -a NEXUS_MODULES_USED           # Modules qui seront utilisés
declare -a NEXUS_LOADING_ORDER          # Ordre de chargement des modules

# Importation des dépendances internes
. "$NEXUS_ROOTPATH/.Logger"
. "$NEXUS_ROOTPATH/.Cache"

Logger_init
Cache_init "$NEXUS_CALLED_BY"

# Vérifie si un module est disponible
Nexus_module_is_available() { [[ -v "${NEXUS_AVAILABLE_MODULES[$1]}" ]]; }

# Vérifie si la liste des modules manquants est vide
Nexus_missing_is_empty() { [ "${#NEXUS_MISSING_MODULES[@]}" -eq 0 ]; }

#==============================================================
# Vérifie les modules manquants et affiche une erreur si besoin
# Journalise également la liste des modules manquants
#====================================================
Nexus_check_missing_modules() {
    if ! Nexus_missing_is_empty; then
        local log="Des dépendances sont manquantes :\n"

        for module_name in "${NEXUS_MISSING_MODULES[@]}"; do
            log+="- $module_name.sh\n"
        done

        Logger_write_several_lines "$log"
        Logger_display_error "Nexus :: Certaines dépendances sont manquantes."
        Logger_display_infos "Pour plus d'informations, consultez le fichier des logs :"
        Logger_display_links "⫸ $(Logger_get_filepath)"
        exit 1
    fi
}

# Initialise les modules Nexus et vérifie leurs dépendances
Nexus_init_modules() {
    for module_name in "${NEXUS_MODULES_USED[@]}"; do
        local dependencies

        ! Nexus_module_is_available "$module_name" && NEXUS_MISSING_MODULES+=("$module_name") && continue

        dependencies=$(Nexus_get_module_dependencies "$module_name")
        Nexus_set_missing_modules "$dependencies"

        if Nexus_missing_is_empty; then
            NEXUS_MODULE_DEPENDENCIES["$module_name"]="$dependencies"
            Nexus_set_required_modules "$module_name $dependencies"
        fi
    done

    Nexus_check_missing_modules
}

# Trie les dépendances pour déterminer l'ordre de chargement
Nexus_sort_dependencies() {
    local -a already_seen

    sort() {
        local module=$1

        # Évite de traiter plusieurs fois le même module
        [[ " ${already_seen[*]} " != *" $module "* ]] && already_seen+=("$module") || return
        for dependency in ${NEXUS_MODULE_DEPENDENCIES[$module]}; do sort "$dependency"; done

        NEXUS_LOADING_ORDER+=("$module")
    }

    for module_name in "${!NEXUS_MODULE_DEPENDENCIES[@]}"; do sort "$module_name"; done
}

# Charge les modules dans l'ordre déterminé
Nexus_load_modules() {
    for module in "${NEXUS_LOADING_ORDER[@]}"; do
        # shellcheck disable=SC1090
        . "$NEXUS_MODULES_PATH/$module.sh"
    done
}

# Initialise Nexus et charge les modules avec dépendances
Nexus_init() {
    Nexus_set_available_modules

    # Détermine les modules à utiliser
    if [ "$#" -gt 0 ]; then
        NEXUS_MODULES_USED=("$@")
    else
        NEXUS_MODULES_USED=("${!NEXUS_AVAILABLE_MODULES[@]}")
    fi

    Nexus_init_modules

    # Vérifie si le cache est valide, sinon trie les dépendances
    if Cache_is_up_to_date "${!NEXUS_REQUIRED_MODULES[@]}"; then
        read -ra NEXUS_LOADING_ORDER <<< "$(Cache_get_data)"
    else
        Nexus_sort_dependencies
    fi
}

#====================================================
# Utiliser Nexus pour charger des modules spécifiques
# Usage : Nexus_link_with "module1" "module2" ...
#================================================
Nexus_link_with() {
    Nexus_init "$@"
    Nexus_load_modules
}

# Utiliser Nexus pour charger tous les modules disponibles
Nexus_link() {
    Nexus_init
    Nexus_load_modules
}

# Récupère la liste des modules disponibles
Nexus_set_available_modules() {
    for module in "$NEXUS_MODULES_PATH"/*.sh; do
        local module_name
        module_name=$(basename "${module%.sh}")
        NEXUS_AVAILABLE_MODULES["$module_name"]=1
    done
}

# Met à jour la liste des modules requis
Nexus_set_required_modules() {
    local required_modules
    read -ra required_modules <<< "$1"

    for module in "${required_modules[@]}"; do
        [ -z "${NEXUS_REQUIRED_MODULES[$module]}" ] && NEXUS_REQUIRED_MODULES["$module"]=1
    done
}

# Détermine les modules manquants
Nexus_set_missing_modules() {
    local dependencies
    read -ra dependencies <<< "$1"

    for module in "${dependencies[@]}"; do
        Nexus_module_is_available "$module" || NEXUS_MISSING_MODULES+=("$module")
    done
}

# Récupère les dépendances d'un module donné
Nexus_get_module_dependencies() { grep -oP "# Nexus_dependencies : \K.*" "$NEXUS_MODULES_PATH/$1.sh"; }

#=================================================
# Affiche les dépendances et l'ordre de chargement
# Utilisation : ./Nexus --debug
#==============================
if [ "$NEXUS_DEBUG" = true ]; then
    if [ "${#NEXUS_DEBUG_MODULES[@]}" -gt 0 ]; then
        Nexus_link_with "${NEXUS_DEBUG_MODULES[@]}"
    else
        Nexus_link
    fi

    title_display() { [ "$(command -v lolcat)" ] && echo -e "$1" | lolcat || echo -e "$1"; }

    title_display "\nDépendances des modules_list utilisés :"
    for module_name in "${!NEXUS_MODULE_DEPENDENCIES[@]}"; do
        declare -a dependencies
        read -ra dependencies <<< "${NEXUS_MODULE_DEPENDENCIES[$module_name]}"

        echo "# Dépendances de $module_name.sh :"
        [ "${#dependencies[@]}" -eq 0 ] && echo '- Aucune dépendance' && echo && continue
        for dependency in "${dependencies[@]}"; do echo "- $dependency"; done
        echo
    done

    title_display "# Ordre de chargement des modules_list :"
    for order in "${NEXUS_LOADING_ORDER[@]}"; do echo "- $order"; done
    echo
fi