#!/usr/bin/env bash
# shellcheck disable=SC1111  # srpski navodnici u porukama su namerni
# Studenti pobedili - tema za Linux (GNOME i KDE Plasma)
# Nezvanicna fan-made personalizacija. Menja samo podesavanja trenutnog korisnika (bez sudo).
#
#   ./install.sh                 meni
#   ./install.sh --bordo         tamna tema (pozadine, boje, ikonice, zakljucani ekran)
#   ./install.sh --svetla        svetla tema
#   ./install.sh --ikonice       samo tema ikonica (Bordo)
#   ./install.sh --porcelan      samo tema ikonica Porcelan (drugi stil; moze i: --svetla --porcelan)
#   ./install.sh --deinstaliraj  vraca prethodna podesavanja i brise fajlove paketa
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="$DATA/studenti-pobedili"
STATE="$STATE_DIR/stanje.env"
ICON_BORDO="StudentiPobedili"
ICON_PORCELAN="StudentiPobedili-Porcelan"
ICON_NAME="$ICON_BORDO"
ICON_LABEL="Studenti Pobedili"
ICON_DST="$DATA/icons/$ICON_NAME"
use_icons() {   # $1 = bordo | porcelan
    if [ "$1" = porcelan ]; then ICON_NAME="$ICON_PORCELAN"; ICON_LABEL="Studenti Pobedili Porcelan"
    else ICON_NAME="$ICON_BORDO"; ICON_LABEL="Studenti Pobedili"; fi
    ICON_DST="$DATA/icons/$ICON_NAME"
}
is_our_icons() { [ "$1" = "$ICON_BORDO" ] || [ "$1" = "$ICON_PORCELAN" ]; }
BG_DIR="$DATA/backgrounds/studenti-pobedili"
GNOME_PROPS="$DATA/gnome-background-properties/studenti-pobedili.xml"
KDE_WALL="$DATA/wallpapers/StudentiPobedili"
KDE_SCHEMES="$DATA/color-schemes"

BORDO_WALLS=(01-Pobeda-Cinematic-4K.jpg 03-Pobeda-Bordo-Talasi-4K.jpg 04-Beograd-4K.jpg)
SVETLA_WALLS=(02-Pobeda-Minimal-Light-4K.jpg)
LOCK_WALL=04-Beograd-4K.jpg

if [ -t 1 ]; then B=$'\e[1m'; R=$'\e[38;5;161m'; G=$'\e[32m'; Y=$'\e[33m'; N=$'\e[0m'; else B=''; R=''; G=''; Y=''; N=''; fi
info() { printf '%s\n' "$*"; }
ok()   { printf '%s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '%s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '%sGREŠKA:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- okruzenje
find_walls() {
    for d in "$DIR/wallpapers" "$DIR/../Wallpapers"; do
        [ -f "$d/${BORDO_WALLS[0]}" ] && { WALLS="$(cd "$d" && pwd)"; return 0; }
    done
    die "Nisu pronađene pozadine. Raspakujte ceo paket i pokrenite install.sh iz njega."
}

desktop() {
    local de="${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}"
    de="${de,,}"
    if [[ "$de" == *kde* || "$de" == *plasma* ]]; then echo kde
    elif [[ "$de" == *gnome* || "$de" == *ubuntu* || "$de" == *unity* || "$de" == *pantheon* ]]; then echo gnome
    else echo ostalo; fi
}

gnome_ok() { have gsettings && gsettings list-schemas 2>/dev/null | grep -qx 'org.gnome.desktop.background'; }
gkey_exists() { gsettings range "$1" "$2" >/dev/null 2>&1; }
kwrite() { if have kwriteconfig6; then kwriteconfig6 "$@"; elif have kwriteconfig5; then kwriteconfig5 "$@"; else return 1; fi; }
kread()  { if have kreadconfig6; then kreadconfig6 "$@"; elif have kreadconfig5; then kreadconfig5 "$@"; else return 1; fi; }
changeicons() {
    for p in /usr/lib/*/libexec/plasma-changeicons /usr/libexec/plasma-changeicons /usr/lib/libexec/plasma-changeicons /usr/lib/plasma-changeicons; do
        [ -x "$p" ] && { "$p" "$1" >/dev/null 2>&1 && return 0; }
    done
    return 1
}

# ---------------------------------------------------------------- rezervna kopija
save_state() {
    [ -f "$STATE" ] && return 0
    mkdir -p "$STATE_DIR"
    {
        echo "# Stanje pre instalacije teme Studenti pobedili"
        if gnome_ok; then
            for sk in "org.gnome.desktop.background picture-uri" "org.gnome.desktop.background picture-uri-dark" \
                      "org.gnome.desktop.background picture-options" "org.gnome.desktop.screensaver picture-uri" \
                      "org.gnome.desktop.interface color-scheme" "org.gnome.desktop.interface icon-theme" \
                      "org.gnome.desktop.interface accent-color"; do
                set -- $sk
                if gkey_exists "$1" "$2"; then printf 'G|%s|%s|%s\n' "$1" "$2" "$(gsettings get "$1" "$2")"; fi
            done
        fi
        if have kreadconfig6 || have kreadconfig5; then
            printf 'K|ColorScheme|%s\n' "$(kread --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
            printf 'K|IconTheme|%s\n' "$(kread --file kdeglobals --group Icons --key Theme 2>/dev/null || true)"
            local appletsrc="$CONFIG/plasma-org.kde.plasma.desktop-appletsrc"
            [ -f "$appletsrc" ] && printf 'K|Wallpaper|%s\n' "$(grep -m1 '^Image=' "$appletsrc" | cut -d= -f2- || true)"
            printf 'K|LockImage|%s\n' "$(kread --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image 2>/dev/null || true)"
        fi
    } > "$STATE"
}

state_get() { [ -f "$STATE" ] && grep -m1 "^$1|" "$STATE" | cut -d'|' -f2- || true; }

current_icon_theme() {
    local t=""
    case "$(desktop)" in
        kde) t="$(kread --file kdeglobals --group Icons --key Theme 2>/dev/null || true)"; [ -z "$t" ] && t=breeze ;;
        *)   gnome_ok && t="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")" ;;
    esac
    # Ako je nasa tema vec aktivna (ponovna instalacija), nasledjuje se original iz sacuvanog stanja.
    if is_our_icons "$t"; then t="$(saved_icon_theme)"; fi
    if is_our_icons "$t"; then t=""; fi
    printf '%s' "$t"
}

saved_icon_theme() {
    [ -f "$STATE" ] || return 0
    local v
    v="$(grep -m1 '^G|org.gnome.desktop.interface|icon-theme|' "$STATE" | cut -d'|' -f4- || true)"
    v="${v//\'/}"
    [ -z "$v" ] && v="$(grep -m1 '^K|IconTheme|' "$STATE" | cut -d'|' -f3- || true)"
    printf '%s' "$v"
}

# ---------------------------------------------------------------- fajlovi
install_icons() {
    local inherit; inherit="$(current_icon_theme)"
    rm -rf "$ICON_DST"; mkdir -p "$DATA/icons"
    cp -r "$DIR/icons/$ICON_NAME" "$ICON_DST"
    # Ikonice koje paket nema uzimaju se iz teme koju ste do sada koristili.
    if [ -n "$inherit" ] && [ "$inherit" != "breeze" ] && [ "$inherit" != "Adwaita" ]; then
        sed -i "s/^Inherits=.*/Inherits=$inherit,breeze,Adwaita,hicolor/" "$ICON_DST/index.theme"
    fi
    have gtk-update-icon-cache && gtk-update-icon-cache -f -q -t "$ICON_DST" 2>/dev/null || true
    ok "Tema ikonica instalirana ($ICON_DST)"
}

slideshow_xml() {   # $1 = izlazni fajl, ostalo = slike
    local out="$1"; shift
    local files=("$@") n=$#
    {
        echo '<background>'
        echo '  <starttime><year>2026</year><month>1</month><day>1</day><hour>0</hour><minute>0</minute><second>0</second></starttime>'
        for ((i = 0; i < n; i++)); do
            local a="$BG_DIR/${files[$i]}" b="$BG_DIR/${files[$(((i + 1) % n))]}"
            echo "  <static><duration>1795.0</duration><file>$a</file></static>"
            echo "  <transition type=\"overlay\"><duration>5.0</duration><from>$a</from><to>$b</to></transition>"
        done
        echo '</background>'
    } > "$out"
}

install_walls() {
    mkdir -p "$BG_DIR"
    rm -f "$BG_DIR"/*.jpg   # stare pozadine iz prethodnih verzija
    cp "$WALLS"/*.jpg "$BG_DIR/"
    slideshow_xml "$BG_DIR/bordo.xml" "${BORDO_WALLS[@]}"
    slideshow_xml "$BG_DIR/svetla.xml" "${SVETLA_WALLS[@]}"
    # GNOME: tema i pojedinacne pozadine se vide u Settings > Appearance
    mkdir -p "$(dirname "$GNOME_PROPS")"
    {
        echo '<?xml version="1.0"?>'
        echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">'
        echo '<wallpapers>'
        echo "  <wallpaper deleted=\"false\"><name>Studenti pobedili</name><filename>$BG_DIR/svetla.xml</filename><filename-dark>$BG_DIR/bordo.xml</filename-dark><options>zoom</options><shade_type>solid</shade_type><pcolor>#7e0c26</pcolor><scolor>#7e0c26</scolor></wallpaper>"
        for f in "$BG_DIR"/*.jpg; do
            echo "  <wallpaper deleted=\"false\"><name>Studenti pobedili - $(basename "$f" .jpg)</name><filename>$f</filename><options>zoom</options><shade_type>solid</shade_type><pcolor>#7e0c26</pcolor><scolor>#7e0c26</scolor></wallpaper>"
        done
        echo '</wallpapers>'
    } > "$GNOME_PROPS"
    # KDE: paket pozadine sa svetlom i tamnom verzijom (Plasma bira prema semi boja)
    rm -rf "$KDE_WALL"; mkdir -p "$KDE_WALL/contents/images" "$KDE_WALL/contents/images_dark"
    cp "$WALLS/${SVETLA_WALLS[0]}" "$KDE_WALL/contents/images/3840x2160.jpg"
    cp "$WALLS/${BORDO_WALLS[0]}" "$KDE_WALL/contents/images_dark/3840x2160.jpg"
    cp "$WALLS/${BORDO_WALLS[0]}" "$KDE_WALL/contents/screenshot.jpg"
    cat > "$KDE_WALL/metadata.json" <<'JSON'
{
    "KPlugin": {
        "Id": "StudentiPobedili",
        "Name": "Studenti pobedili",
        "Description": "Bordo pozadina (nezvanična fan-made tema)",
        "License": "CC-BY-SA-4.0",
        "Authors": [ { "Name": "Studenti pobedili tema" } ]
    }
}
JSON
    mkdir -p "$KDE_SCHEMES"
    cp "$DIR"/kde/*.colors "$KDE_SCHEMES/"
    ok "Pozadine instalirane ($BG_DIR)"
}

# ---------------------------------------------------------------- primena
apply_gnome() {   # $1 = bordo | svetla
    gnome_ok || { warn "GNOME podešavanja (gsettings) nisu dostupna."; return 0; }
    gsettings set org.gnome.desktop.background picture-uri "file://$BG_DIR/svetla.xml"
    gkey_exists org.gnome.desktop.background picture-uri-dark && gsettings set org.gnome.desktop.background picture-uri-dark "file://$BG_DIR/bordo.xml"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    gkey_exists org.gnome.desktop.screensaver picture-uri && gsettings set org.gnome.desktop.screensaver picture-uri "file://$BG_DIR/$LOCK_WALL"
    if [ "$1" = bordo ]; then gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    else gsettings set org.gnome.desktop.interface color-scheme 'default'; fi
    if gkey_exists org.gnome.desktop.interface accent-color; then
        gsettings set org.gnome.desktop.interface accent-color 'red'
        ok "Akcentna boja: crvena (najbliža bordo u GNOME paleti)"
    fi
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_NAME"
    ok "GNOME: $( [ "$1" = bordo ] && echo 'tamni režim, Bordo pozadine' || echo 'svetli režim, Svetle pozadine' ) (pozadine prate režim)"
}

# Upisuje boje iz .colors fajla direktno u kdeglobals (isto sto radi plasma-apply-colorscheme).
# Koristi se kada alat ne postoji (stariji Plasma) ili ne moze da radi (npr. bez ekrana, preko SSH).
write_scheme() {   # $1 = putanja do .colors
    local section="" line key value
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            \[*\]) section="${line#[}"; section="${section%]}" ;;
            *=*)   key="${line%%=*}"; value="${line#*=}"
                   case "$section" in
                       Colors:*|WM|ColorEffects:*|KDE)
                           local groups=() part rest="$section"
                           while [[ "$rest" == *"]["* ]]; do part="${rest%%][*}"; groups+=(--group "$part"); rest="${rest#*][}"; done
                           groups+=(--group "$rest")
                           kwrite --file kdeglobals "${groups[@]}" --key "$key" "$value" || return 1 ;;
                       General) [ "$key" = ColorScheme ] && { kwrite --file kdeglobals --group General --key ColorScheme "$value" || return 1; } ;;
                   esac ;;
        esac
    done < "$1"
}

set_kde_scheme() {   # $1 = ime seme (fajl u $KDE_SCHEMES)
    local current
    if have plasma-apply-colorscheme && plasma-apply-colorscheme "$1" >/dev/null 2>&1; then
        current="$(kread --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
        [ "$current" = "$1" ] && return 0
    fi
    [ -f "$KDE_SCHEMES/$1.colors" ] && write_scheme "$KDE_SCHEMES/$1.colors"
}

apply_kde() {   # $1 = bordo | svetla
    local scheme; [ "$1" = bordo ] && scheme=StudentiPobediliBordo || scheme=StudentiPobediliSvetla
    if set_kde_scheme "$scheme"; then ok "KDE: šema boja $scheme"
    else warn "Šema boja nije primenjena: izaberite „$scheme“ u System Settings > Colors."; fi
    if have plasma-apply-wallpaperimage; then plasma-apply-wallpaperimage "$KDE_WALL" >/dev/null 2>&1 || true; ok "KDE: pozadina"
    else warn "plasma-apply-wallpaperimage nije pronađen: izaberite pozadinu „Studenti pobedili“ ručno."; fi
    kwrite --file kdeglobals --group Icons --key Theme "$ICON_NAME" || true
    if ! changeicons "$ICON_NAME" && have dbus-send; then
        dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 >/dev/null 2>&1 || true
    fi
    ok "KDE: tema ikonica"
    local lock="file://$BG_DIR/$LOCK_WALL"
    kwrite --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$lock" || true
    kwrite --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "$lock" || true
    ok "KDE: zaključani ekran"
}

do_theme() {   # $1 = bordo | svetla
    find_walls
    save_state
    install_icons
    install_walls
    case "$(desktop)" in
        gnome) apply_gnome "$1" ;;
        kde)   apply_kde "$1" ;;
        *)     warn "Okruženje nije prepoznato kao GNOME ni KDE: fajlovi su instalirani, primenite ih ručno."
               info "  Ikonice: tema „$ICON_LABEL“   Pozadine: $BG_DIR" ;;
    esac
    echo; ok "${B}Tema je instalirana.${N} Ako se nešto ne osveži odmah, odjavite se i ponovo prijavite."
}

do_icons() {
    save_state
    install_icons
    case "$(desktop)" in
        gnome) gnome_ok && gsettings set org.gnome.desktop.interface icon-theme "$ICON_NAME" ;;
        kde)   kwrite --file kdeglobals --group Icons --key Theme "$ICON_NAME" || true; changeicons "$ICON_NAME" || true ;;
        *)     info "Izaberite temu ikonica „$ICON_LABEL“ u podešavanjima izgleda." ;;
    esac
    ok "Ikonice su postavljene ($ICON_LABEL)."
}

do_uninstall() {
    if [ -f "$STATE" ]; then
        while IFS='|' read -r kind a b c; do
            case "$kind" in
                G) gnome_ok && gkey_exists "$a" "$b" && gsettings set "$a" "$b" "$c" 2>/dev/null || true ;;
                K) case "$a" in
                       ColorScheme) if [ -z "$b" ]; then   # korisnik nije menjao semu: podrazumevana Breeze
                                        for n in BreezeLight Breeze; do [ -f "/usr/share/color-schemes/$n.colors" ] && { b="$n"; break; }; done
                                    fi
                                    if [ -n "$b" ]; then
                                        # Ugradjena sema (npr. BreezeDark) je u sistemskoj fascikli
                                        for f in "$KDE_SCHEMES/$b.colors" /usr/share/color-schemes/"$b".colors /usr/local/share/color-schemes/"$b".colors; do
                                            if [ -f "$f" ]; then
                                                { have plasma-apply-colorscheme && plasma-apply-colorscheme "$b" >/dev/null 2>&1 && [ "$(kread --file kdeglobals --group General --key ColorScheme 2>/dev/null)" = "$b" ]; } || write_scheme "$f" || true
                                                break
                                            fi
                                        done
                                    fi ;;
                       IconTheme)   if [ -n "$b" ]; then kwrite --file kdeglobals --group Icons --key Theme "$b" || true; changeicons "$b" || true
                                    else kwrite --file kdeglobals --group Icons --key Theme --delete 2>/dev/null || true; changeicons breeze || true; fi ;;
                       Wallpaper)   [ -n "$b" ] && have plasma-apply-wallpaperimage && plasma-apply-wallpaperimage "${b#file://}" >/dev/null 2>&1 || true ;;
                       LockImage)   if [ -n "$b" ]; then kwrite --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$b" || true
                                    else kwrite --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image --delete 2>/dev/null || true; fi ;;
                   esac ;;
            esac
        done < <(grep -v '^#' "$STATE")
        ok "Prethodna podešavanja su vraćena."
    else
        warn "Nema sačuvanog stanja; vraćam podrazumevane vrednosti."
        if gnome_ok; then
            for k in "org.gnome.desktop.background picture-uri" "org.gnome.desktop.background picture-uri-dark" "org.gnome.desktop.screensaver picture-uri" "org.gnome.desktop.interface icon-theme" "org.gnome.desktop.interface accent-color"; do
                set -- $k; gkey_exists "$1" "$2" && gsettings reset "$1" "$2" || true
            done
        fi
    fi
    rm -rf "$DATA/icons/$ICON_BORDO" "$DATA/icons/$ICON_PORCELAN" "$BG_DIR" "$KDE_WALL" "$GNOME_PROPS" "$KDE_SCHEMES/StudentiPobediliBordo.colors" "$KDE_SCHEMES/StudentiPobediliSvetla.colors" "$STATE_DIR"
    ok "Fajlovi paketa su uklonjeni."
}

menu() {
    echo
    echo "  ${R}${B}STUDENTI POBEDILI${N}  |  tema za Linux ($(desktop))"
    echo "  ─────────────────────────────────────────────"
    echo "   [1]  Bordo   (tamni režim, pozadine, boje, ikonice, zaključani ekran)"
    echo "   [2]  Svetla  (svetli režim)"
    echo "   [3]  Samo ikonice (Bordo)"
    echo "   [4]  Samo ikonice Porcelan (drugi stil: mat bele, grafitni simboli)"
    echo "   [5]  Deinstaliraj i vrati prethodno"
    echo "   [0]  Izlaz"
    echo
    read -r -p "  Izaberite opciju: " c
    case "$c" in
        1) do_theme bordo ;; 2) do_theme svetla ;; 3) do_icons ;; 4) use_icons porcelan; do_icons ;; 5) do_uninstall ;; *) exit 0 ;;
    esac
}

[ "$(id -u)" -eq 0 ] && die "Ne pokrećite sa sudo: tema se instalira za vašeg korisnika."
case "${1:-}" in
    --bordo|--svetla)
        if [ "${2:-}" = --porcelan ]; then use_icons porcelan; fi
        do_theme "${1#--}" ;;
    --ikonice) do_icons ;;
    --porcelan) use_icons porcelan; do_icons ;;
    --deinstaliraj|--uninstall) do_uninstall ;;
    -h|--pomoc|--help) sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//' ;;
    "") menu ;;
    *) die "Nepoznata opcija: $1 (pogledajte --pomoc)" ;;
esac
