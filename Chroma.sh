#!/bin/bash

# Déclaration des couleurs de texte (foreground) pour le formatage ANSI (256 couleurs)
declare -grA CHROMA_FG_COLORS_ID=(
    ["black"]=0 ["red"]=196 ["green"]=82 ["yellow"]=226 ["blue"]=39 ["purple"]=201 ["cyan"]=51 ["orange"]=208 ["white"]=15
)

# Déclaration des couleurs de fond (background) pour le formatage ANSI (256 couleurs)
declare -grA CHROMA_BG_COLORS_ID=(
    ["black"]=0 ["red"]=160 ["green"]=40 ["yellow"]=220 ["blue"]=21 ["purple"]=90 ["cyan"]=44 ["orange"]=202 ["white"]=255
)

# Déclaration des styles de texte (gras, italique, etc.)
declare -grA CHROMA_STYLES_ID=(
    ["bold"]=1 ["dim"]=2 ["italic"]=3 ["underline"]=4 ["blink"]=5 ["overline"]=9
)

# Codes ANSI de début et de fin pour l'application des styles/couleurs
readonly CHROMA_ANSI_START='\e['
readonly CHROMA_ANSI_END='\e[0m'

# Vérifie si le paramètre reçu est bien un code de couleur valide (0 à 256)
Chroma_is_color_number() { [[ $1 =~ ^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-6])$ ]]; }

#=========================================================
# Applique un style à un texte donné (ex : gras, souligné)
# Usage : Chroma_font_style "Texte" "style1" "style2" ...
#======================================================
Chroma_font_style() {
    local -r text=$1
    local -ra styles=("${@:2}")
    local -r ansi_code=$(Chroma_get_compiled_style_code "${styles[@]}")

    # Formate le texte avec les couleurs
    echo -e "$(Chroma_get_formatted_string "$text" "$ansi_code")"
}

#=================================================================
# Applique une coloration (foreground et/ou background) à un texte
# Usage : Chroma_coloration "Texte" "foreground" "background"
#==========================================================
Chroma_coloration() {
    local -r text="$1"
    local -r foreground=$2
    local -r background=$3

    local ansi_code
    ansi_code="$(Chroma_get_compiled_color_code "$foreground" "$background")"

    # Formate le texte avec les couleurs
    echo -e "$(Chroma_get_formatted_string "$text" "$ansi_code")"
}

#===================================================================
# Applique à la fois styles, couleurs de texte et de fond à un texte
# Usage : Chroma_stylize "Texte" [--fg "foreground"] [--bg "background"] [--styles "style1" "style2"]
#==================================================================================================
Chroma_stylize() {
    local -r text="$1"
    local -a styles
    local foreground
    local background
    local ansi_style_code
    local ansi_color_code
    local ansi_code

    shift

    # Parcourt les options pour récupérer les couleurs et styles
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --fg) foreground="$2"; shift 2 ;;
            --bg) background="$2"; shift 2 ;;
            --styles) styles=("${@:2}"); break ;;
            *) shift ;;
        esac
    done

    ansi_style_code=$(Chroma_get_compiled_style_code "${styles[@]}")
    ansi_color_code=$(Chroma_get_compiled_color_code "$foreground" "$background")

    # Combine les styles et couleurs s'ils existent
    [ -n "$ansi_style_code" ] && ansi_code="$ansi_style_code"
    if [ -n "$ansi_color_code" ]; then
        [ -n "$ansi_code" ] && ansi_code+=";$ansi_color_code" || ansi_code="$ansi_color_code"
    fi

    echo -e "$(Chroma_get_formatted_string "$text" "$ansi_code")"
}

# Récupère l'ID du style (ex : bold -> 1)
Chroma_get_style_ID() {
    local -r style_name=$1
    [[ -v CHROMA_STYLES_ID["$style_name"] ]] && echo "${CHROMA_STYLES_ID[$style_name]}"
}

#=======================================================
# Récupère l'ID de la couleur (foreground ou background)
# Usage : Chroma_get_color_ID "fg|bg" "color_name|color_number"
# Si un numéro de couleur est renseigné à la place d'un nom, le numéro de couleur sera utilisé
# Il est donc possible d'utiliser une couleur de son choix au lieu de l'une des couleurs pré-définies
#=====================================================================================================
Chroma_get_color_ID() {
    local -r color_type=$1
    local -r color_name=$2

    # Vérifie si la couleur est un code numérique ou un nom
    if Chroma_is_color_number "$color_name"; then
        echo "$color_name"
    else
        [ "$color_type" = fg ] && [[ -v CHROMA_FG_COLORS_ID["$color_name"] ]] && echo "${CHROMA_FG_COLORS_ID[$color_name]}"
        [ "$color_type" = bg ] && [[ -v CHROMA_BG_COLORS_ID["$color_name"] ]] && echo "${CHROMA_BG_COLORS_ID[$color_name]}"
    fi
}

#==============================================
# Compile plusieurs styles en un seul code ANSI
# Usage : Chroma_get_compiled_style_code "style1" "style2" ...
#===========================================================
Chroma_get_compiled_style_code() {
    local style_id
    local compiled_code

    for style in "$@"; do
        style_id=$(Chroma_get_style_ID "$style")
        if [ -n "$style_id" ]; then
            [ -n "$compiled_code" ] && compiled_code+=";$style_id" || compiled_code="$style_id"
        fi
    done
    echo "$compiled_code"
}

#==============================================================
# Compile les couleurs de texte et de fond en un seul code ANSI
# Usage : Chroma_get_compiled_color_code "foreground" "background"
#===============================================================
Chroma_get_compiled_color_code() {
    local fg_id
    local bg_id
    local compiled_code
    
    [ -n "$1" ] && fg_id="$(Chroma_get_color_ID fg "$1")"
    [ -n "$2" ] && bg_id="$(Chroma_get_color_ID bg "$2")"

    [ -n "$fg_id" ] && compiled_code+="38;5;$fg_id"
    if [ -n "$bg_id" ]; then
        [ -n "$compiled_code" ] && compiled_code+=";48;5;$bg_id" || compiled_code="48;5;$bg_id"
    fi
    echo "$compiled_code"
}

#=====================================
# Formate le texte avec les codes ANSI
# Usage : Chroma_get_formatted_string "Texte" "ansi_code"
#======================================================
Chroma_get_formatted_string() {
    local -r text=$1
    local -r ansi_code=$2

    # Applique le code ANSI uniquement si ansi_code est défini
    if [ -n "$ansi_code" ]; then
        echo "${CHROMA_ANSI_START}${ansi_code}m${text}${CHROMA_ANSI_END}"
    else
        echo "$text"
    fi
}

# Permet d'afficher les couleurs et les styles disponibles.
if [ "$#" -eq 1 ]; then
    [ "$1" = "--colors" ] && echo "Couleurs disponibles par nommage : ${!CHROMA_FG_COLORS_ID[*]}"
    [ "$1" = "--styles" ] && echo "Styles disponibles : ${!CHROMA_STYLES_ID[*]}"
fi









