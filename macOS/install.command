#!/usr/bin/env bash
# shellcheck disable=SC1111  # srpski navodnici u porukama su namerni
# Studenti pobedili - tema za macOS (beta)
# Nezvanicna fan-made personalizacija. Menja samo podesavanja trenutnog korisnika (bez admin prava).
#
#   ./install.command                     meni (moze i dvoklik u Finder-u)
#   ./install.command --bordo             tamni rezim, Bordo pozadina, crveni akcenat, ikonice fascikli
#   ./install.command --svetla            svetli rezim, Svetla pozadina
#   ./install.command --fascikla PUTANJA  crvena "3" za fasciklu po izboru
#   ./install.command --deinstaliraj      vraca prethodna podesavanja
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPPORT="$HOME/Library/Application Support/StudentiPobedili"
STATE="$SUPPORT/stanje.txt"
FOLDERS_LOG="$SUPPORT/fascikle.txt"
WALL_DST="$HOME/Pictures/Studenti pobedili"
ICON_DST="$SUPPORT/Ikonice"

BORDO_WALL=03-Pobeda-Desktop-4K.jpg
SVETLA_WALL=02-Pobeda-Minimal-Light-4K.jpg
# fascikla u korisnickom folderu -> ikonica
FOLDER_ICONS=("Desktop:Desktop.png" "Documents:Folder-Documents.png" "Downloads:Folder-Downloads.png"
              "Pictures:Folder-Pictures.png" "Music:Folder-Music.png" "Movies:Folder-Video.png")

if [ -t 1 ]; then B=$'\e[1m'; R=$'\e[38;5;161m'; G=$'\e[32m'; Y=$'\e[33m'; N=$'\e[0m'; else B=""; R=""; G=""; Y=""; N=""; fi
ok()   { printf '%s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '%s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '%sGREŠKA:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "Ovaj instaler je za macOS. Za Linux koristite paket StudentiPobedili-Linux."
[ "$(id -u)" -ne 0 ] || die "Ne pokrećite sa sudo: tema se instalira za vašeg korisnika."

find_dir() {   # $1 = ime u paketu, $2 = ime u repou, $3 = fajl koji mora da postoji
    local d
    for d in "$DIR/$1" "$DIR/../$2"; do [ -f "$d/$3" ] && { (cd "$d" && pwd); return 0; }; done
    return 1
}
WALLS="$(find_dir wallpapers Wallpapers "$BORDO_WALL")" || die "Nisu pronađene pozadine. Raspakujte ceo paket."
ICONS="$(find_dir icons Icons/PNG Folder-3.png)" || die "Nisu pronađene ikonice. Raspakujte ceo paket."

# ---------------------------------------------------------------- macOS pomocne
osa() { osascript -e "$1" 2>/dev/null; }

get_wallpaper() { osa 'tell application "System Events" to get picture of desktop 1' || true; }
set_wallpaper() {   # $1 = putanja
    osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
    tell application "System Events" to tell every desktop to set picture to (item 1 of argv)
end run
APPLESCRIPT
}
get_dark() { osa 'tell application "System Events" to tell appearance preferences to get dark mode' || echo false; }
set_dark() { osa "tell application \"System Events\" to tell appearance preferences to set dark mode to $1" >/dev/null; }

# Ikonica fascikle preko NSWorkspace (isto sto radi Finder > Get Info > nalepi ikonicu).
set_folder_icon() {   # $1 = fascikla, $2 = png ili prazno za uklanjanje
    osascript -l JavaScript - "$1" "${2:-}" >/dev/null 2>&1 <<'JXA'
function run(argv) {
    ObjC.import('AppKit');
    var img = argv[1] ? $.NSImage.alloc.initWithContentsOfFile(argv[1]) : null;
    if (argv[1] && img.isNil()) { return false; }
    var ok = $.NSWorkspace.sharedWorkspace.setIconForFileOptions(img, argv[0], 0);
    if (!ok) { throw new Error('setIcon failed'); }
    return true;
}
JXA
}

defaults_get() { defaults read -g "$1" 2>/dev/null || echo "__NEMA__"; }

# ---------------------------------------------------------------- stanje
save_state() {
    [ -f "$STATE" ] && return 0
    mkdir -p "$SUPPORT"
    {
        printf 'wallpaper=%s\n' "$(get_wallpaper)"
        printf 'dark=%s\n' "$(get_dark)"
        printf 'accent=%s\n' "$(defaults_get AppleAccentColor)"
        printf 'highlight=%s\n' "$(defaults_get AppleHighlightColor)"
    } > "$STATE"
}
state() { grep -m1 "^$1=" "$STATE" 2>/dev/null | cut -d= -f2- || true; }

remember_folder() { mkdir -p "$SUPPORT"; touch "$FOLDERS_LOG"; grep -qxF "$1" "$FOLDERS_LOG" || printf '%s\n' "$1" >> "$FOLDERS_LOG"; }

# ---------------------------------------------------------------- akcije
install_files() {
    mkdir -p "$WALL_DST" "$ICON_DST"
    cp "$WALLS"/*.jpg "$WALL_DST/"
    cp "$ICONS"/*.png "$ICON_DST/"
    ok "Pozadine kopirane u: $WALL_DST"
}

apply_folder_icons() {
    local item folder icon okc=0 failed=()
    for item in "${FOLDER_ICONS[@]}"; do
        folder="$HOME/${item%%:*}"; icon="$ICON_DST/${item#*:}"
        [ -d "$folder" ] || continue
        if set_folder_icon "$folder" "$icon"; then remember_folder "$folder"; okc=$((okc + 1)); else failed+=("${item%%:*}"); fi
    done
    [ "$okc" -gt 0 ] && ok "Ikonice postavljene za $okc fascikli"
    if [ "${#failed[@]}" -gt 0 ]; then
        warn "Nije moguće promeniti: ${failed[*]}. macOS traži dozvolu: System Settings › Privacy & Security ›"
        warn "Files and Folders (ili Full Disk Access) › uključite Terminal, pa pokrenite instaler ponovo."
    fi
    return 0
}

do_theme() {   # $1 = bordo | svetla
    save_state
    install_files
    if [ "$1" = bordo ]; then
        set_wallpaper "$WALL_DST/$BORDO_WALL" && ok "Pozadina: Bordo" || warn "Pozadina nije promenjena (dozvolite Terminalu da upravlja aplikacijom System Events)."
        set_dark true && ok "Tamni režim" || warn "Tamni režim nije uključen."
    else
        set_wallpaper "$WALL_DST/$SVETLA_WALL" && ok "Pozadina: Svetla" || warn "Pozadina nije promenjena (dozvolite Terminalu da upravlja aplikacijom System Events)."
        set_dark false && ok "Svetli režim" || warn "Svetli režim nije uključen."
    fi
    # Crvena je najbliza bordo u Apple paleti; vazi posle ponovnog pokretanja aplikacija.
    defaults write -g AppleAccentColor -int 0
    defaults write -g AppleHighlightColor -string "1.000000 0.733333 0.721569 Red"
    ok "Akcentna boja: crvena (aplikacije je prikazuju posle ponovnog pokretanja)"
    apply_folder_icons
    killall Finder >/dev/null 2>&1 || true
    echo; ok "${B}Tema je instalirana.${N} Zaključani ekran koristi istu pozadinu."
    echo "  Sve pozadine: $WALL_DST (System Settings › Wallpaper › Add Folder)"
}

do_folder() {   # $1 = putanja
    local f="${1:-}"
    if [ -z "$f" ]; then read -r -p "  Prevucite fasciklu ovde i pritisnite Enter: " f; fi
    f="${f%/}"; f="${f//\\ / }"; f="${f%\"}"; f="${f#\"}"; f="${f%\'}"; f="${f#\'}"
    [ -d "$f" ] || die "Fascikla ne postoji: $f"
    install_files >/dev/null
    if set_folder_icon "$f" "$ICON_DST/Folder-3.png"; then remember_folder "$f"; killall Finder >/dev/null 2>&1 || true; ok "Crvena „3“ postavljena: $f"
    else die "Ikonica nije postavljena (proverite dozvole za Terminal u Privacy & Security)."; fi
}

do_uninstall() {
    if [ -f "$FOLDERS_LOG" ]; then
        while IFS= read -r f; do [ -d "$f" ] && set_folder_icon "$f" "" || true; done < "$FOLDERS_LOG"
        ok "Originalne ikonice fascikli su vraćene."
    fi
    if [ -f "$STATE" ]; then
        local w d a h
        w="$(state wallpaper)"; d="$(state dark)"; a="$(state accent)"; h="$(state highlight)"
        # Dinamicke i "aerial" pozadine nemaju uvek obican fajl, pa uvek pokusamo i javimo ako ne uspe.
        if [ -n "$w" ] && ! set_wallpaper "$w"; then warn "Prethodnu pozadinu izaberite ručno: System Settings › Wallpaper."; fi
        if [ "$d" = true ]; then set_dark true || true; else set_dark false || true; fi
        if [ "$a" = "__NEMA__" ] || [ -z "$a" ]; then defaults delete -g AppleAccentColor >/dev/null 2>&1 || true
        else defaults write -g AppleAccentColor -int "$a"; fi
        if [ "$h" = "__NEMA__" ] || [ -z "$h" ]; then defaults delete -g AppleHighlightColor >/dev/null 2>&1 || true
        else defaults write -g AppleHighlightColor -string "$h"; fi
        ok "Pozadina, režim i akcentna boja su vraćeni."
    else
        warn "Nema sačuvanog stanja: vraćam podrazumevanu akcentnu boju."
        defaults delete -g AppleAccentColor >/dev/null 2>&1 || true
        defaults delete -g AppleHighlightColor >/dev/null 2>&1 || true
    fi
    rm -rf "$SUPPORT" "$WALL_DST"
    killall Finder >/dev/null 2>&1 || true
    ok "Fajlovi paketa su uklonjeni."
}

menu() {
    echo
    echo "  ${R}${B}STUDENTI POBEDILI${N}  |  tema za macOS (beta)"
    echo "  ─────────────────────────────────────────────"
    echo "   [1]  Bordo   (tamni režim, pozadina, crveni akcenat, ikonice fascikli)"
    echo "   [2]  Svetla  (svetli režim)"
    echo "   [3]  Crvena „3“ za fasciklu po izboru"
    echo "   [4]  Deinstaliraj i vrati prethodno"
    echo "   [0]  Izlaz"
    echo
    read -r -p "  Izaberite opciju: " c
    case "$c" in 1) do_theme bordo ;; 2) do_theme svetla ;; 3) do_folder "" ;; 4) do_uninstall ;; *) exit 0 ;; esac
}

case "${1:-}" in
    --bordo) do_theme bordo ;;
    --svetla) do_theme svetla ;;
    --fascikla) do_folder "${2:-}" ;;
    --deinstaliraj|--uninstall) do_uninstall ;;
    -h|--pomoc|--help) sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//' ;;
    "") menu ;;
    *) die "Nepoznata opcija: $1 (pogledajte --pomoc)" ;;
esac
