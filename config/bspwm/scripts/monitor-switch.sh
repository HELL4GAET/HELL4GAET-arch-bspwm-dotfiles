#!/usr/bin/env bash
set -euo pipefail

# Preferred outputs from `xrandr --query`. If unavailable, matching connected
# outputs are detected automatically.
LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP}"
# Leave empty for automatic HDMI/DisplayPort detection, or set a preferred port.
EXTERNAL_OUTPUT="${EXTERNAL_OUTPUT:-}"
EXTERNAL_MODE="${EXTERNAL_MODE:-3840x2160}"
EXTERNAL_RATE="${EXTERNAL_RATE:-60}"
EXTERNAL_SCALE="${EXTERNAL_SCALE:-1.75}"

DESKTOPS="${DESKTOPS:-1 2 3 4 5}"

LAPTOP_XFT_DPI="${LAPTOP_XFT_DPI:-120}"
EXTERNAL_XFT_DPI="${EXTERNAL_XFT_DPI:-168}"
LAPTOP_GTK_FONT="${LAPTOP_GTK_FONT:-JetBrainsMono Nerd Font 12}"
EXTERNAL_GTK_FONT="${EXTERNAL_GTK_FONT:-JetBrainsMono Nerd Font 13}"
LAPTOP_ROFI_FONT="${LAPTOP_ROFI_FONT:-JetBrainsMono Nerd Font 14}"
EXTERNAL_ROFI_FONT="${EXTERNAL_ROFI_FONT:-JetBrainsMono Nerd Font 17}"
LAPTOP_CURSOR_SIZE="${LAPTOP_CURSOR_SIZE:-24}"
EXTERNAL_CURSOR_SIZE="${EXTERNAL_CURSOR_SIZE:-32}"
CURSOR_THEME="${CURSOR_THEME:-Bibata-Modern-Ice}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
PROFILE_FILE="$CACHE_DIR/monitor-profile"
LOCK_FILE="$CACHE_DIR/monitor-switch-v2.lock"
TOP_PADDING=44
BOTTOM_PADDING=0

connected_outputs() {
    xrandr --query | awk '$2 == "connected" {print $1}'
}

known_outputs() {
    xrandr --query | awk '$2 == "connected" || $2 == "disconnected" {print $1}'
}

active_geometry() {
    local output="$1"
    xrandr --query | awk -v output="$output" '
        $1 == output && $2 == "connected" {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
                    print $i
                    exit
                }
            }
        }
    '
}

detect_laptop_output() {
    connected_outputs | awk '/^(eDP|LVDS)/ {print; exit}'
}

detect_external_output() {
    connected_outputs | awk '!/^(eDP|LVDS)/ {print; exit}'
}

select_output() {
    local preferred="$1" detected="$2"

    if is_connected "$preferred"; then
        printf '%s\n' "$preferred"
    else
        printf '%s\n' "$detected"
    fi
}

is_connected() {
    local output="$1"
    [[ -n "$output" ]] || return 1
    connected_outputs | grep -qx "$output"
}

set_ini_value() {
    local file="$1" key="$2" value="$3"
    [[ -f "$file" ]] || return 0

    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >>"$file"
    fi
}

set_xresources_dpi() {
    local dpi="$1" cursor_size="$2"
    local file="$HOME/.Xresources"
    [[ -f "$file" ]] || return 0

    if grep -q '^Xft\.dpi:' "$file"; then
        sed -i "s|^Xft\\.dpi:.*|Xft.dpi:   ${dpi}|" "$file"
    else
        printf '\nXft.dpi:   %s\n' "$dpi" >>"$file"
    fi

    if grep -q '^Xcursor\.size:' "$file"; then
        sed -i "s|^Xcursor\\.size:.*|Xcursor.size:   ${cursor_size}|" "$file"
    else
        printf 'Xcursor.size:   %s\n' "$cursor_size" >>"$file"
    fi

    xrdb -merge "$file" 2>/dev/null || true
}

set_rofi_font() {
    local font="$1"
    local file="$HOME/.config/rofi/config.rasi"
    [[ -f "$file" ]] || return 0

    if grep -q '^[[:space:]]*font:' "$file"; then
        sed -i "s|^[[:space:]]*font:.*|    font: \"${font}\";|" "$file"
    fi
}

apply_scale_profile() {
    local profile="$1" xft_dpi gtk_dpi gtk_font rofi_font cursor_size qt_scale

    case "$profile" in
        external)
            xft_dpi="$EXTERNAL_XFT_DPI"
            gtk_font="$EXTERNAL_GTK_FONT"
            rofi_font="$EXTERNAL_ROFI_FONT"
            cursor_size="$EXTERNAL_CURSOR_SIZE"
            qt_scale="$EXTERNAL_SCALE"
            TOP_PADDING=58
            BOTTOM_PADDING=0
            ;;
        laptop)
            xft_dpi="$LAPTOP_XFT_DPI"
            gtk_font="$LAPTOP_GTK_FONT"
            rofi_font="$LAPTOP_ROFI_FONT"
            cursor_size="$LAPTOP_CURSOR_SIZE"
            qt_scale=1
            TOP_PADDING=44
            BOTTOM_PADDING=0
            ;;
        *)
            printf 'monitor-switch: unknown scale profile: %s\n' "$profile" >&2
            return 1
            ;;
    esac

    gtk_dpi=$((xft_dpi * 1024))
    set_xresources_dpi "$xft_dpi" "$cursor_size"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-font-name "$gtk_font"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-xft-dpi "$gtk_dpi"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-cursor-theme-size "$cursor_size"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-font-name "$gtk_font"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-xft-dpi "$gtk_dpi"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-cursor-theme-size "$cursor_size"
    set_rofi_font "$rofi_font"

    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    export QT_SCALE_FACTOR="$qt_scale"
    export XCURSOR_THEME="$CURSOR_THEME"
    export XCURSOR_SIZE="$cursor_size"
    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment --systemd \
            QT_AUTO_SCREEN_SCALE_FACTOR QT_SCALE_FACTOR \
            XCURSOR_THEME XCURSOR_SIZE 2>/dev/null || true
    fi
}

turn_off_other_outputs() {
    local keep="$1"

    known_outputs | while read -r output; do
        if [[ "$output" != "$keep" ]]; then
            xrandr --output "$output" --off || true
        fi
    done
}

assign_bspwm_desktops() {
    local monitor="$1" current_monitor desktop geometry

    command -v bspc >/dev/null 2>&1 || return 0
    sleep 0.4

    if ! bspc query -M --names 2>/dev/null | grep -qx "$monitor"; then
        current_monitor="$(bspc query -M --names 2>/dev/null | head -n 1 || true)"
        if [[ -n "$current_monitor" ]]; then
            bspc monitor "$current_monitor" -n "$monitor" 2>/dev/null || true
        fi
    fi

    geometry="$(active_geometry "$monitor" || true)"
    [[ -z "$geometry" ]] || bspc monitor "$monitor" -g "$geometry" 2>/dev/null || true

    for desktop in $DESKTOPS; do
        if bspc query -D --names 2>/dev/null | grep -qx "$desktop"; then
            bspc desktop "$desktop" -m "$monitor" 2>/dev/null || true
        else
            bspc monitor "$monitor" -a "$desktop" 2>/dev/null || true
        fi
    done

    bspc monitor "$monitor" -f || true
}

restart_polybar() {
    local launcher="$HOME/.config/polybar/launch.sh"
    [[ -x "$launcher" ]] || return 0
    "$launcher" 9>&- >/tmp/monitor-switch-polybar.log 2>&1 || true
}

reload_dunst() {
    command -v dunstctl >/dev/null 2>&1 || return 0
    dunstctl reload 2>/dev/null || true
}

apply_bspwm_padding() {
    local monitor="$1"
    command -v bspc >/dev/null 2>&1 || return 0
    bspc config -m "$monitor" top_padding "$TOP_PADDING" || true
    bspc config -m "$monitor" bottom_padding "$BOTTOM_PADDING" || true
}

main() {
    local mode="${1:-auto}"

    command -v xrandr >/dev/null 2>&1 || {
        printf 'monitor-switch: xrandr not found\n' >&2
        exit 1
    }

    mkdir -p "$CACHE_DIR"
    exec 9>"$LOCK_FILE"
    flock -n 9 || exit 0

    LAPTOP_OUTPUT="$(select_output "$LAPTOP_OUTPUT" "$(detect_laptop_output || true)")"
    EXTERNAL_OUTPUT="$(select_output "$EXTERNAL_OUTPUT" "$(detect_external_output || true)")"

    if [[ "$mode" == "--toggle" ]] &&
        is_connected "$LAPTOP_OUTPUT" &&
        [[ -n "$(active_geometry "$EXTERNAL_OUTPUT" || true)" ]]; then
        target=laptop
    elif is_connected "$EXTERNAL_OUTPUT"; then
        target=external
    elif is_connected "$LAPTOP_OUTPUT"; then
        target=laptop
    else
        printf 'monitor-switch: no usable connected outputs found\n' >&2
        exit 1
    fi

    if [[ "$target" == external ]]; then
        xrandr --output "$EXTERNAL_OUTPUT" --primary --mode "$EXTERNAL_MODE" --rate "$EXTERNAL_RATE" ||
            xrandr --output "$EXTERNAL_OUTPUT" --primary --auto
        turn_off_other_outputs "$EXTERNAL_OUTPUT"
        printf 'external\n' >"$PROFILE_FILE"
        assign_bspwm_desktops "$EXTERNAL_OUTPUT"
        apply_scale_profile external
        active_monitor="$EXTERNAL_OUTPUT"
    else
        xrandr --output "$LAPTOP_OUTPUT" --primary --auto
        turn_off_other_outputs "$LAPTOP_OUTPUT"
        printf 'laptop\n' >"$PROFILE_FILE"
        assign_bspwm_desktops "$LAPTOP_OUTPUT"
        apply_scale_profile laptop
        active_monitor="$LAPTOP_OUTPUT"
    fi

    command -v wallpaper >/dev/null 2>&1 && wallpaper 9>&- || true
    restart_polybar
    apply_bspwm_padding "$active_monitor"
    reload_dunst
}

main "$@"
