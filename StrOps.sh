#===============================================================
# Retire les espaces vides présents aux extrémités d'une chaîne.
# Usage : StrOps_trim "chaîne" [côtés_ciblés=tous]
#=================================================
StrOps_trim() {
    local -r str=$1
    local side=${2,,}
    local -rA sed_regex=(['both']='s/^ *//;s/ *$//' ['left']='s/^ *//' ['right']='s/ *$//')

    [ -z "$str" ] && return
    [[ $side =~ ^(both|left|right)$ ]] || side=both

    echo "$str" | sed "${sed_regex[$side]}"
}

#=================================================================================================
# Découpe une chaîne en segments respectant une longueur maximale, sans couper au milieu des mots.
# Usage : StrOps_split "chaîne" longueur_max tableau_de_référence
#================================================================
StrOps_split() {
    local -r str=$1
    local -r max_length=$2
    local -n _result=$3 # Référence vers le tableau à remplir

    if [ "${#str}" -le "$max_length" ]; then
        _result=("$str")
    else
        # shellcheck disable=SC2034
        mapfile -t _result < <(echo "$str" | awk -v max="$max_length" '{
            line = $1
            for (i = 2; i <= NF; i++) {
                if (length(line) + length($i) + 1 >= max) {
                    print line
                    line = $i
                } else {
                    line = line " " $i
                }
            }
            print line
        }')
    fi
}

#========================================================================
# Tronque une chaîne à une longueur maximale, en ajoutant "..." à la fin.
# Usage : StrOps_truncate "chaîne" longueur_max
#==============================================
StrOps_truncate() {
    local -r str=$1
    local -r max_length=$2

    [ "${#str}" -gt "$max_length" ] && echo "${str:0:$max_length-3}..." || echo "$str"
}
