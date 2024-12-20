# Nexus_dependencies : Chroma WShield TermCTRL StrOps FrameGen

# Définition des couleurs associées aux types de messages
declare -grA DISPLAYFX_MESSAGE_COLORS=(
    ["error"]=red ["warning"]=yellow ["info"]=cyan ["valid"]=green
)

# Largeur minimale requise pour le terminal
readonly DISPLAYFX_TERMINAL_MIN_WIDTH=20

DisplayFX_lolcat_is_installed() { WShield_is_installed_package lolcat; }
DisplayFX_figlet_is_installed() { WShield_is_installed_package figlet; }

# Vérifie si la largeur du terminal est trop petite.
DisplayFX_terminal_is_too_small() { [ "$(TermCTRL_get_width)" -lt "$DISPLAYFX_TERMINAL_MIN_WIDTH" ]; }

DisplayFX_use_lolcat() { [ "$1" = true ] && DisplayFX_lolcat_is_installed; }

#=================================================================================================
# Affiche un message coloré, avec un type spécifique (erreur, info, etc.) et options d'alignement.
# Usage : DisplayFX_message "type" "texte" [newlines_up=1] [newlines_down=0] [alignement=left]
#=============================================================================================
DisplayFX_message() {
    local -r message_type=$1
    local -r message_text=$2
    local -r newlines_up=${3:-1}
    local -r newlines_down=${4:-0}
    local -r text_align="${5:-left}"

    local -r message_color=$(DisplayFX_get_message_color "$message_type")
    local -r formatted_message=$(Chroma_coloration "$message_text" "$message_color")

    DisplayFX_print "$formatted_message" "$newlines_up" "$newlines_down" "$text_align"
}

#===============================================================================
# Affiche un texte avec options d'alignement et de gestion des nouvelles lignes.
# Usage : DisplayFX_print "texte" [newlines_up] [newlines_down] [alignement]
#=========================================================================
DisplayFX_print() {
    local -r text=$1
    local -r newlines_up=$2
    local -r newlines_down=$3
    local -r text_align=$4

    DisplayFX_line_breaks "$newlines_up"

    if ! DisplayFX_terminal_is_too_small; then
        local -r text_max_length=$(DisplayFX_get_max_text_length)
        if [ "${#text}" -gt "$text_max_length" ]; then
            DisplayFX_print_wrapped "$text" "$text_max_length" "$text_align"
        else
            DisplayFX_text_align "${#text}" "$text_align"
            printf '%s\n' "$text"
        fi
    else
        printf '%s\n' "$text"
    fi

    DisplayFX_line_breaks "$newlines_down"
}

#=======================================================================================
# Affiche un titre sous la forme d'un texte encadré avec une coloration gérée par lolcat
# Usage : DisplayFX_print_title "title"
#======================================
DisplayFX_print_lolcat_title() {
    local -r title=" ${1:-EMPTY} "
    local -r frame_title=$(FrameGen_generate_title "$title")
    DisplayFX_lolcat_is_installed && echo "$frame_title" | lolcat || echo "$frame_title"
}

#=====================================================
# Affiche une bannière qui utilise figlet et/ou lolcat
# Usage : DisplayFX_print_banner "texte" [figlet_font]
#=====================================================
DisplayFX_print_banner() {
    local -r text=$1
    local -ra fonts=(standard slant banner shadow)

    local font
    local banner

    [ -n "$2" ] && font=$2 || font="${fonts[RANDOM % ${#fonts[@]}]}"

    DisplayFX_figlet_is_installed && banner=$(figlet -f "$font" "$text") || banner="$text"
    DisplayFX_lolcat_is_installed && echo "$banner" | lolcat || echo "$banner"
}

#=========================================================================================
# Coupe un texte en plusieurs lignes si sa longueur dépasse la largeur maximale autorisée.
# Usage : DisplayFX_print_wrapped "texte" longueur_max [alignement]
#====================================================================
DisplayFX_print_wrapped() {
    local -r text=$1
    local -r max_length=$2
    local -r text_align=$3

    local -a wrapped_text
    StrOps_split "$text" "$max_length" wrapped_text

    for line in "${wrapped_text[@]}"; do
        DisplayFX_text_align "${#line}" "$text_align"
        printf '%s\n' "$line"
    done
}

# Insère un certain nombre de sauts de ligne.
DisplayFX_line_breaks() {
    local -r nb_lines=$1
    WShield_is_positive_number "$nb_lines" && printf '%*s' "$nb_lines" '' | tr ' ' '\n'
}

# Gère l'alignement d'un texte dans le terminal (gauche, droite, centre).
DisplayFX_text_align() {
    local -r text_length=$1
    local -r alignment=$2
    local -r terminal_width=$(TermCTRL_get_width)
    local margin=0

    # Si le terminal est trop petit ou que le texte dépasse la largeur, aucun alignement n'est fait
    if [ -z "$alignment" ] || DisplayFX_terminal_is_too_small || [ "$terminal_width" -le "$text_length" ]; then
        return
    fi

    # Calcul de la marge selon l'alignement
    if [ "$alignment" = center ]; then
        margin=$(( (terminal_width - text_length) / 2 ))
    elif [ "$alignment" = right ]; then
        margin=$(( terminal_width - text_length ))
    fi

    # Ajoute la marge à gauche si nécessaire
    [ "$margin" -gt 0 ] && printf ' %.0s' $(seq 1 "$margin")
}

# Retourne la couleur associée à un type de message.
DisplayFX_get_message_color() { echo "${DISPLAYFX_MESSAGE_COLORS[$1]:-$1}"; }

# Retourne la longueur maximale à appliquer au texte selon la largeur du terminal.
DisplayFX_get_max_text_length() { TermCTRL_get_ratio 2 3; }
