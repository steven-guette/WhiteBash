WShield_is_installed_package() { command -v "$1" &> /dev/null; }
WShield_is_number() { [[ $1 =~ ^[0-9]+$ ]]; }
WShield_is_positive_number() { WShield_is_number "$1" && [ "$1" -gt 0 ]; }