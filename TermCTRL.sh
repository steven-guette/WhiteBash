#==============================================
# Vérifie si le terminal est suffisamment large
# Usage : TermCTRL_is_quite_wide "largeur_minimum"
#=================================================
TermCTRL_is_quite_wide() { [ "$(TermCTRL_get_width)" -ge "$1" ]; }

# Retourne la largeur actuelle du terminal
TermCTRL_get_width()  { tput cols; }

# Retourne la hauteur actuelle du terminal
TermCTRL_get_height()  { tput lines; }

#==============================================================
# Retourne le calcul d'un ratio basé sur la largeur du terminal
# Usage : TermCTRL_get_ratio "numérateur" "dénominateur"
#=======================================================
TermCTRL_get_ratio()  { echo "$(( $(TermCTRL_get_width) * $1 / $2 ))"; }