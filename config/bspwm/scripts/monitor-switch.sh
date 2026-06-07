#!/usr/bin/env bash
set -euo pipefail

# Outputs from `xrandr --query`. Override via env if the hardware changes.
LAPTOP_OUTPUT="${LAPTOP_OUTPUT:-eDP-1}"
EXTERNAL_OUTPUT="${EXTERNAL_OUTPUT:-DP-1}"
EXTERNAL_MODE="${EXTERNAL_MODE:-3840x2160}"

DESKTOPS="${DESKTOPS:-1 2 3 4 5}"

LAPTOP_XFT_DPI="${LAPTOP_XFT_DPI:-120}"
EXTERNAL_XFT_DPI="${EXTERNAL_XFT_DPI:-168}"
LAPTOP_GTK_FONT="${LAPTOP_GTK_FONT:-JetBrainsMono Nerd Font 12}"
EXTERNAL_GTK_FONT="${EXTERNAL_GTK_FONT:-JetBrainsMono Nerd Font 13}"
LAPTOP_ROFI_FONT="${LAPTOP_ROFI_FONT:-JetBrainsMono Nerd Font 14}"
EXTERNAL_ROFI_FONT="${EXTERNAL_ROFI_FONT:-JetBrainsMono Nerd Font 17}"
LAPTOP_CURSOR_SIZE="${LAPTOP_CURSOR_SIZE:-0}"
EXTERNAL_CURSOR_SIZE="${EXTERNAL_CURSOR_SIZE:-32}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
PROFILE_FILE="$CACHE_DIR/monitor-profile"
LOCK_DIR="$CACHE_DIR/monitor-switch.lock"
POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"

connected_outputs() {
    xrandr --query | awk '$2 == "connected" {print $1}'
}

active_outputs() {
    xrandr --query | awk '$2 == "connected" && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1}'
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
    local dpi="$1"
    local file="$HOME/.Xresources"
    [[ -f "$file" ]] || return 0

    if grep -q '^Xft\.dpi:' "$file"; then
        sed -i "s|^Xft\\.dpi:.*|Xft.dpi:   ${dpi}|" "$file"
    else
        printf '\nXft.dpi:   %s\n' "$dpi" >>"$file"
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

set_polybar_profile() {
    local profile="$1" height font_size font_offset icon_size icon_offset
    [[ -f "$POLYBAR_CONFIG" ]] || return 0

    case "$profile" in
        external)
            height=40
            font_size=16
            font_offset=4
            icon_size=22
            icon_offset=6
            ;;
        laptop)
            height=31
            font_size=13
            font_offset=3
            icon_size=18
            icon_offset=5
            ;;
        *)
            return 1
            ;;
    esac

    sed -i \
        -e "s|^height = .*|height = ${height}|" \
        -e "s|^font-0 = .*|font-0 = JetBrainsMono Nerd Font:style=Bold:pixelsize=${font_size};${font_offset}|" \
        -e "s|^font-1 = .*|font-1 = JetBrainsMono Nerd Font:size=${icon_size};${icon_offset}|" \
        -e "s|^font-2 = .*|font-2 = JetBrainsMono Nerd Font:style=Bold:size=${font_size};${font_offset}|" \
        -e "s|^font-3 = .*|font-3 = unifont:fontformat=truetype:size=${font_size}:antialias=true;${font_offset}|" \
        "$POLYBAR_CONFIG"
}

apply_scale_profile() {
    local profile="$1" xft_dpi gtk_dpi gtk_font rofi_font cursor_size

    case "$profile" in
        external)
            xft_dpi="$EXTERNAL_XFT_DPI"
            gtk_font="$EXTERNAL_GTK_FONT"
            rofi_font="$EXTERNAL_ROFI_FONT"
            cursor_size="$EXTERNAL_CURSOR_SIZE"
            ;;
        laptop)
            xft_dpi="$LAPTOP_XFT_DPI"
            gtk_font="$LAPTOP_GTK_FONT"
            rofi_font="$LAPTOP_ROFI_FONT"
            cursor_size="$LAPTOP_CURSOR_SIZE"
            ;;
        *)
            printf 'monitor-switch: unknown scale profile: %s\n' "$profile" >&2
            return 1
            ;;
    esac

    gtk_dpi=$((xft_dpi * 1024))
    set_xresources_dpi "$xft_dpi"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-font-name "$gtk_font"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-xft-dpi "$gtk_dpi"
    set_ini_value "$HOME/.config/gtk-3.0/settings.ini" gtk-cursor-theme-size "$cursor_size"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-font-name "$gtk_font"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-xft-dpi "$gtk_dpi"
    set_ini_value "$HOME/.config/gtk-4.0/settings.ini" gtk-cursor-theme-size "$cursor_size"
    set_rofi_font "$rofi_font"
    set_polybar_profile "$profile"
}

turn_off_other_outputs() {
    local keep="$1"

    connected_outputs | while read -r output; do
        if [[ "$output" != "$keep" ]]; then
            xrandr --output "$output" --off || true
        fi
    done
}

assign_bspwm_desktops() {
    local monitor="$1" current_monitor geometry

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
    # shellcheck disable=SC2086
    bspc monitor "$monitor" -d $DESKTOPS || true
    bspc monitor "$monitor" -f || true
}

restart_polybar() {
    local launcher="$HOME/.config/polybar/launch.sh"
    [[ -x "$launcher" ]] || return 0
    "$launcher" >/tmp/monitor-switch-polybar.log 2>&1 || true
}

main() {
    command -v xrandr >/dev/null 2>&1 || {
        printf 'monitor-switch: xrandr not found\n' >&2
        exit 1
    }

    mkdir -p "$CACHE_DIR"
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        exit 0
    fi
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

    [[ -n "$LAPTOP_OUTPUT" ]] || LAPTOP_OUTPUT="$(detect_laptop_output || true)"
    [[ -n "$EXTERNAL_OUTPUT" ]] || EXTERNAL_OUTPUT="$(detect_external_output || true)"

    if is_connected "$EXTERNAL_OUTPUT"; then
        xrandr --output "$EXTERNAL_OUTPUT" --primary --mode "$EXTERNAL_MODE" || \
            xrandr --output "$EXTERNAL_OUTPUT" --primary --auto
        turn_off_other_outputs "$EXTERNAL_OUTPUT"
        printf 'external\n' >"$PROFILE_FILE"
        assign_bspwm_desktops "$EXTERNAL_OUTPUT"
        apply_scale_profile external
    elif is_connected "$LAPTOP_OUTPUT"; then
        xrandr --output "$LAPTOP_OUTPUT" --primary --auto
        turn_off_other_outputs "$LAPTOP_OUTPUT"
        printf 'laptop\n' >"$PROFILE_FILE"
        assign_bspwm_desktops "$LAPTOP_OUTPUT"
        apply_scale_profile laptop
    else
        printf 'monitor-switch: no usable connected outputs found\n' >&2
        exit 1
    fi

    command -v wallpaper >/dev/null 2>&1 && wallpaper || true
    restart_polybar
}

main "$@"
