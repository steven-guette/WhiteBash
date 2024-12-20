# Nexus_dependencies : WShield Chroma StrOps

declare -grA FRAMEGEN_SYMBOLS=(
    ['border_x']='═'
    ['border_y']='║'
    ['corner_tl']='╔'
    ['corner_tr']='╗'
    ['corner_bl']='╚'
    ['corner_br']='╝'
    ['link_top']='╦'
    ['link_bottom']='╩'
    ['link_left']='╠'
    ['link_center']='╬'
    ['link_right']='╣'
)

FrameGen_generate_title() {
    local -r title=" ${1:-EMPTY} "
    local -r title_color=$2
    local -r frame_color=$3

    local -r title_length=${#title}

    local border_y
    local top_line
    local bottom_line
    local middle_line

    border_y="${FRAMEGEN_SYMBOLS['border_y']}"
    top_line=$(FrameGen_get_top_line "$title_length")
    bottom_line=$(FrameGen_get_bottom_line "$title_length")

    if [ -n "$frame_color" ]; then
        border_y=$(Chroma_coloration "$border_y" "$frame_color")
        top_line=$(Chroma_coloration "$top_line" "$frame_color")
        bottom_line=$(Chroma_coloration "$bottom_line" "$frame_color")
    fi

    if [ -n "$title_color" ]; then
        middle_line="${border_y}$(Chroma_stylize "$title" --fg "$title_color" --styles bold)${border_y}"
    else
        middle_line="${border_y}$(Chroma_font_style "$title" bold)${border_y}"
    fi

    echo -e "$top_line\n$middle_line\n$bottom_line"
}

FrameGen_get_horizontal_line() {
    local line_length=$1

    WShield_is_positive_number "$line_length" || return

    local -r symbol=${2:-${FRAMEGEN_SYMBOLS['border_x']}}
    local -r color=$3

    local line
    for ((i=0; i<line_length; i++)); do line+="$symbol"; done
    [ -n "$color" ] && line=$(Chroma_coloration "$line" "$color")

    echo "$line"
}

FrameGen_get_top_line() { echo "${FRAMEGEN_SYMBOLS['corner_tl']}$(FrameGen_get_horizontal_line "$1")${FRAMEGEN_SYMBOLS['corner_tr']}"; }
FrameGen_get_bottom_line() { echo "${FRAMEGEN_SYMBOLS['corner_bl']}$(FrameGen_get_horizontal_line "$1")${FRAMEGEN_SYMBOLS['corner_br']}"; }








