#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="$HOME/.local/state/hell4gaet-dotfiles/manifest"
DRY_RUN=0

CORE_PACKAGES=(
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot
  xorg-setxkbmap xorg-xkbcomp xorg-xmodmap xorg-xrdb
  bspwm sxhkd polybar picom rofi dunst
  kitty fish fastfetch neovim thunar mousepad firefox chromium code btop keyd matugen
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  networkmanager network-manager-applet bluez bluez-utils blueman power-profiles-daemon
  nm-connection-editor pavucontrol pamixer playerctl brightnessctl libnotify
  flameshot xclip feh mpv telegram-desktop lxappearance
  xdg-utils
  papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-dejavu
  git base-devel ripgrep go unzip
)

DESKTOP_INTEGRATION_PACKAGES=(
  polkit-gnome udisks2 udiskie
  gvfs gvfs-mtp gvfs-smb tumbler ffmpegthumbnailer
  thunar-archive-plugin file-roller
  xdg-desktop-portal xdg-desktop-portal-gtk
  xss-lock redshift
)

CLI_PACKAGES=(
  fzf fd bat eza zoxide jq
  lazygit git-delta direnv tealdeer
  dust duf ncdu trash-cli shellcheck shfmt
)

DEBUG_PACKAGES=(
  alttab-debug
  i3lock-color-debug
  yay-debug
)

AUR_DESKTOP_PACKAGES=(
  i3lock-color
  bibata-cursor-theme
)

AUR_GOLAND_PACKAGES=(goland goland-jre)

DEV_PACKAGES=(
  nodejs npm pnpm
  python python-pip python-pipx
  rustup jdk-openjdk
  docker docker-compose
  openssh github-cli lazygit shellcheck shfmt
)

DOCKER_PACKAGES=(docker docker-compose)
GO_PACKAGES=(go)
RUST_PACKAGES=(rustup)
JDK_PACKAGES=(jdk-openjdk)
FIREFOX_PACKAGES=(firefox)
CHROMIUM_PACKAGES=(chromium)
FORBIDDEN_PACKAGES=(
  tor torbrowser-launcher mpd ncmpcpp libreoffice-fresh libreoffice-still
  gparted kdenlive audacity obs-studio anki wireshark-qt veracrypt deluge
  deluge-gtk
)

show_help() {
  cat <<EOF
Usage: ./install.sh [option]

Options:
  (no option)         Start the interactive installation wizard.
  --check             Show detected hardware names and missing package groups.
  --packages          Install the curated BSPWM desktop package list.
  --integration       Install lock, Polkit, automount and Thunar integration.
  --cli               Install the curated command-line tools.
  --aur               Install desktop AUR packages; bootstraps yay if needed.
  --dev               Install optional developer packages.
  --goland            Install optional GoLand packages from AUR.
  --docker            Install Docker packages and enable docker.service.
  --go                Install Go.
  --rust              Install rustup.
  --jdk               Install OpenJDK.
  --browser-firefox   Install Firefox.
  --browser-chromium  Install Chromium.
  --dotfiles          Copy dotfiles into \$HOME with timestamped backups.
  --update            Validate and update installed dotfiles with backups.
  --restore [path]    Restore a backup (latest backup by default).
  --uninstall         Remove files tracked by the installer manifest.
  --doctor            Check packages, commands, fonts, configs and hardware.
  --cleanup           Remove known debug packages and orphan dependencies.
  --dry-run OPTION    Print actions for another installer option.
  --services          Enable NetworkManager, Bluetooth, keyd, power profiles and PipeWire.
  --all               Install the complete desktop, dotfiles and services.
  --help              Show this help.

Existing dotfiles are moved to a timestamped backup before replacement.
EOF
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer supports Arch Linux and pacman-based systems." >&2
    exit 1
  fi
  if ((!DRY_RUN)) && [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "Run this installer as a regular user, not as root." >&2
    exit 1
  fi
}

confirm() {
  local prompt="$1"
  local default="${2:-yes}"
  local answer

  if [[ "$default" == yes ]]; then
    read -r -p "$prompt [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]
  else
    read -r -p "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
  fi
}

detect() {
  echo "User: $USER"
  echo "Home: $HOME"
  echo "Network interfaces:"
  find /sys/class/net -maxdepth 1 -mindepth 1 -printf '  %f\n' | sort
  echo "Backlight devices:"
  find /sys/class/backlight -maxdepth 1 -mindepth 1 -printf '  %f\n' | sort || true
  echo "Power supplies:"
  find /sys/class/power_supply -maxdepth 1 -mindepth 1 -printf '  %f\n' | sort || true
  echo "DRM connectors:"
  find /sys/class/drm -maxdepth 1 -mindepth 1 -printf '  %f\n' | sort || true
}

check_group() {
  local name="$1"
  shift
  local missing=()
  local pkg
  for pkg in "$@"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if ((${#missing[@]} == 0)); then
    echo "$name: installed"
  else
    echo "$name: missing"
    printf '  %s\n' "${missing[@]}"
  fi
}

check_packages() {
  check_group "core desktop" "${CORE_PACKAGES[@]}"
  check_group "desktop integration" "${DESKTOP_INTEGRATION_PACKAGES[@]}"
  check_group "CLI tools" "${CLI_PACKAGES[@]}"
  check_group "desktop AUR" "${AUR_DESKTOP_PACKAGES[@]}"
  check_group "GoLand AUR" "${AUR_GOLAND_PACKAGES[@]}"
  check_group "developer" "${DEV_PACKAGES[@]}"
  check_group "firefox" "${FIREFOX_PACKAGES[@]}"
  check_group "chromium" "${CHROMIUM_PACKAGES[@]}"
  echo "forbidden packages installed:"
  local found=()
  local pkg
  for pkg in "${FORBIDDEN_PACKAGES[@]}"; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
      found+=("$pkg")
    fi
  done
  if ((${#found[@]} == 0)); then
    echo "  none"
  else
    printf '  %s\n' "${found[@]}"
  fi
}

install_group() {
  if ((DRY_RUN)); then
    printf '[dry-run] sudo pacman -S --needed'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  sudo pacman -S --needed "$@"
}

ensure_yay() {
  local build_dir

  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  echo "yay is not installed; bootstrapping it from AUR."
  install_group base-devel git
  build_dir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  (
    cd "$build_dir/yay"
    makepkg -si --needed
  )
  rm -rf "$build_dir"
}

install_packages() {
  install_group "${CORE_PACKAGES[@]}"
}

install_integration_packages() {
  install_group "${DESKTOP_INTEGRATION_PACKAGES[@]}"
}

install_cli_packages() {
  install_group "${CLI_PACKAGES[@]}"
}

install_dev_packages() {
  install_group "${DEV_PACKAGES[@]}"
}

install_aur_packages() {
  if ((DRY_RUN)); then
    printf '[dry-run] yay -S --needed'
    printf ' %q' "${AUR_DESKTOP_PACKAGES[@]}"
    printf '\n'
    return 0
  fi
  ensure_yay
  yay -S --needed "${AUR_DESKTOP_PACKAGES[@]}"
}

install_goland() {
  if ((DRY_RUN)); then
    printf '[dry-run] yay -S --needed'
    printf ' %q' "${AUR_GOLAND_PACKAGES[@]}"
    printf '\n'
    return 0
  fi
  ensure_yay
  yay -S --needed "${AUR_GOLAND_PACKAGES[@]}"
}

install_docker() {
  install_group "${DOCKER_PACKAGES[@]}"
  sudo systemctl enable --now docker.service
  sudo usermod -aG docker "$USER"
  echo "Docker group membership takes effect after the next login."
}

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if ((DRY_RUN)); then
      echo "[dry-run] backup $target -> $BACKUP_DIR/${target#"$HOME"/}"
      return 0
    fi
    mkdir -p "$BACKUP_DIR/$(dirname "${target#"$HOME"/}")"
    mv "$target" "$BACKUP_DIR/${target#"$HOME"/}"
    echo "Backed up $target -> $BACKUP_DIR/${target#"$HOME"/}"
  fi
}

copy_dir() {
  local src="$1"
  local dst="$2"
  backup_path "$dst"
  if ((DRY_RUN)); then
    echo "[dry-run] copy directory $src -> $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

copy_file() {
  local src="$1"
  local dst="$2"
  backup_path "$dst"
  if ((DRY_RUN)); then
    echo "[dry-run] copy file $src -> $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

configure_hardware() {
  local modules="$HOME/.config/polybar/modules.ini"
  local wifi=""
  local backlight=""
  local battery=""
  local adapter=""
  local device type

  [[ -f "$modules" ]] || return 0

  for device in /sys/class/net/*; do
    [[ -d "$device/wireless" ]] || continue
    wifi="${device##*/}"
    break
  done

  if [[ -d /sys/class/backlight ]]; then
    backlight="$(find /sys/class/backlight -mindepth 1 -maxdepth 1 -printf '%f\n' | head -n 1)"
  fi

  for device in /sys/class/power_supply/*; do
    [[ -r "$device/type" ]] || continue
    type="$(<"$device/type")"
    case "$type" in
      Battery)
        [[ -n "$battery" ]] || battery="${device##*/}"
        ;;
      Mains | USB | USB_C)
        [[ -n "$adapter" ]] || adapter="${device##*/}"
        ;;
    esac
  done

  [[ -z "$wifi" ]] || sed -i "/^\\[module\\/wlan\\]/,/^\\[/ s/^interface = .*/interface = $wifi/" "$modules"
  [[ -z "$backlight" ]] || sed -i "/^\\[module\\/backlight\\]/,/^\\[/ s/^card = .*/card = $backlight/" "$modules"
  [[ -z "$battery" ]] || sed -i "/^\\[module\\/battery\\]/,/^\\[/ s/^battery = .*/battery = $battery/" "$modules"
  [[ -z "$adapter" ]] || sed -i "/^\\[module\\/battery\\]/,/^\\[/ s/^adapter = .*/adapter = $adapter/" "$modules"

  echo "Detected Polybar devices:"
  echo "  Wi-Fi: ${wifi:-not found}"
  echo "  Backlight: ${backlight:-not found}"
  echo "  Battery: ${battery:-not found}"
  echo "  Adapter: ${adapter:-not found}"
}

validate_dotfiles() {
  local required=(
    "$HOME/.config/bspwm/scripts/monitor-switch.sh"
    "$HOME/.config/systemd/user/bspwm-session.target"
    "$HOME/.config/polybar/config.ini"
    "$HOME/.config/polybar/modules.ini"
    "$HOME/.config/dunst/dunstrc"
    "$HOME/.local/bin/wallpaper"
  )
  local path

  for path in "${required[@]}"; do
    if [[ ! -e "$path" ]]; then
      echo "Missing installed file: $path" >&2
      return 1
    fi
  done
}

validate_sources() {
  local scripts=(
    "$ROOT_DIR/install.sh"
    "$ROOT_DIR/xinitrc"
    "$ROOT_DIR/config/bspwm/bspwmrc"
    "$ROOT_DIR/config/bspwm/scripts/monitor-switch.sh"
    "$ROOT_DIR/config/polybar/launch.sh"
    "$ROOT_DIR"/local/bin/*
  )
  local script

  for script in "${scripts[@]}"; do
    bash -n "$script"
  done

  if command -v fish >/dev/null 2>&1; then
    fish -n "$ROOT_DIR/config/fish/config.fish"
  fi
  if command -v keyd >/dev/null 2>&1; then
    keyd check "$ROOT_DIR"/config/keyd/*.conf
  fi
  echo "Repository configuration syntax: OK"
}

manifest_paths() {
  cat <<EOF
$HOME/.config/bspwm
$HOME/.config/sxhkd
$HOME/.config/polybar
$HOME/.config/picom
$HOME/.config/rofi
$HOME/.config/dunst
$HOME/.config/kitty
$HOME/.config/fish
$HOME/.config/matugen
$HOME/.config/btop
$HOME/.config/flameshot
$HOME/.config/keyd
$HOME/.config/nvim
$HOME/.config/systemd/user
$HOME/.config/Code - OSS
$HOME/.config/JetBrains
$HOME/.config/gtk-3.0
$HOME/.config/gtk-4.0
$HOME/.config/xfce4
$HOME/.xkb
$HOME/.themes/Dracula-pink-accent
$HOME/.xinitrc
$HOME/.Xresources
$HOME/.gtkrc-2.0
$HOME/.bashrc
$HOME/.bash_profile
$HOME/.config/mimeapps.list
EOF
  for file in "$ROOT_DIR"/local/bin/*; do
    printf '%s/.local/bin/%s\n' "$HOME" "$(basename "$file")"
  done
}

write_manifest() {
  ((DRY_RUN)) && return 0
  mkdir -p "$(dirname "$MANIFEST_FILE")"
  manifest_paths >"$MANIFEST_FILE"
}

install_dotfiles() {
  validate_sources
  copy_dir "$ROOT_DIR/config/bspwm" "$HOME/.config/bspwm"
  copy_dir "$ROOT_DIR/config/sxhkd" "$HOME/.config/sxhkd"
  copy_dir "$ROOT_DIR/config/polybar" "$HOME/.config/polybar"
  copy_dir "$ROOT_DIR/config/picom" "$HOME/.config/picom"
  copy_dir "$ROOT_DIR/config/rofi" "$HOME/.config/rofi"
  copy_dir "$ROOT_DIR/config/dunst" "$HOME/.config/dunst"
  copy_dir "$ROOT_DIR/config/kitty" "$HOME/.config/kitty"
  copy_dir "$ROOT_DIR/config/fish" "$HOME/.config/fish"
  copy_dir "$ROOT_DIR/config/matugen" "$HOME/.config/matugen"
  copy_dir "$ROOT_DIR/config/btop" "$HOME/.config/btop"
  copy_dir "$ROOT_DIR/config/flameshot" "$HOME/.config/flameshot"
  copy_dir "$ROOT_DIR/config/keyd" "$HOME/.config/keyd"
  copy_dir "$ROOT_DIR/config/nvim" "$HOME/.config/nvim"
  copy_dir "$ROOT_DIR/config/systemd/user" "$HOME/.config/systemd/user"
  copy_dir "$ROOT_DIR/config/Code - OSS" "$HOME/.config/Code - OSS"
  copy_dir "$ROOT_DIR/config/JetBrains" "$HOME/.config/JetBrains"
  copy_dir "$ROOT_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0"
  copy_dir "$ROOT_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0"
  copy_dir "$ROOT_DIR/config/xfce4" "$HOME/.config/xfce4"
  copy_dir "$ROOT_DIR/xkb" "$HOME/.xkb"
  copy_dir "$ROOT_DIR/themes/Dracula-pink-accent" "$HOME/.themes/Dracula-pink-accent"
  mkdir -p "$HOME/.local/bin"
  for file in "$ROOT_DIR"/local/bin/*; do
    copy_file "$file" "$HOME/.local/bin/$(basename "$file")"
  done
  copy_file "$ROOT_DIR/xinitrc" "$HOME/.xinitrc"
  copy_file "$ROOT_DIR/Xresources" "$HOME/.Xresources"
  copy_file "$ROOT_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0"
  copy_file "$ROOT_DIR/bashrc" "$HOME/.bashrc"
  copy_file "$ROOT_DIR/bash_profile" "$HOME/.bash_profile"
  copy_file "$ROOT_DIR/config/mimeapps.list" "$HOME/.config/mimeapps.list"
  if ((DRY_RUN)); then
    echo "[dry-run] configure detected hardware, user units and executable permissions"
    return 0
  fi
  configure_hardware
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  chmod +x "$HOME/.config/bspwm/bspwmrc" "$HOME/.config/polybar/launch.sh" "$HOME/.local/bin/"*
  find "$HOME/.config/bspwm/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  validate_dotfiles
  write_manifest
}

enable_services() {
  if ((DRY_RUN)); then
    echo "[dry-run] install keyd configs and enable NetworkManager, bluetooth, keyd, power profiles and PipeWire"
    return 0
  fi
  sudo install -d -m 0755 /etc/keyd
  local keyd_conf
  for keyd_conf in "$ROOT_DIR"/config/keyd/*.conf; do
    sudo install -m 0644 "$keyd_conf" "/etc/keyd/$(basename "$keyd_conf")"
  done
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable --now bluetooth.service
  sudo systemctl enable --now keyd.service
  sudo systemctl enable --now power-profiles-daemon.service
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service || true
}

latest_backup() {
  find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d -printf '%p\n' 2>/dev/null |
    sort | tail -n 1
}

restore_backup() {
  local source="${1:-}" safety
  [[ -n "$source" ]] || source="$(latest_backup)"
  [[ -d "$source" ]] || {
    echo "Backup not found: ${source:-none}" >&2
    return 1
  }
  case "$(readlink -f "$source")" in
    "$(readlink -f "$HOME/.dotfiles-backup")"/*) ;;
    *)
      echo "Refusing to restore a path outside ~/.dotfiles-backup" >&2
      return 1
      ;;
  esac

  safety="$HOME/.dotfiles-backup/restore-safety-$(date +%Y%m%d-%H%M%S)"
  echo "Restoring: $source"
  echo "Current managed files will be saved to: $safety"
  if ((DRY_RUN)); then
    echo "[dry-run] backup current managed paths and merge restored files into $HOME"
    return 0
  fi

  BACKUP_DIR="$safety"
  if [[ -f "$MANIFEST_FILE" ]]; then
    while IFS= read -r target; do
      [[ -n "$target" ]] && backup_path "$target"
    done <"$MANIFEST_FILE"
  fi
  cp -a "$source/." "$HOME/"
  echo "Restore completed."
}

uninstall_dotfiles() {
  local safety
  [[ -f "$MANIFEST_FILE" ]] || {
    echo "Installer manifest not found: $MANIFEST_FILE" >&2
    return 1
  }
  safety="$HOME/.dotfiles-backup/uninstall-$(date +%Y%m%d-%H%M%S)"
  echo "Managed files will be moved to: $safety"
  if ((DRY_RUN)); then
    sed 's/^/[dry-run] remove /' "$MANIFEST_FILE"
    return 0
  fi

  BACKUP_DIR="$safety"
  while IFS= read -r target; do
    [[ -n "$target" ]] && backup_path "$target"
  done <"$MANIFEST_FILE"
  rm -f "$MANIFEST_FILE"
}

cleanup_packages() {
  local installed_debug=() orphans=() pkg

  if pacman -Q go >/dev/null 2>&1; then
    if ((DRY_RUN)); then
      echo "[dry-run] sudo pacman -D --asexplicit go"
    else
      sudo pacman -D --asexplicit go
    fi
  fi

  for pkg in "${DEBUG_PACKAGES[@]}"; do
    pacman -Q "$pkg" >/dev/null 2>&1 && installed_debug+=("$pkg")
  done
  if ((${#installed_debug[@]})); then
    if ((DRY_RUN)); then
      printf '[dry-run] sudo pacman -Rns'
      printf ' %q' "${installed_debug[@]}"
      printf '\n'
    else
      sudo pacman -Rns "${installed_debug[@]}"
    fi
  fi

  mapfile -t orphans < <(pacman -Qdtq 2>/dev/null || true)
  if ((DRY_RUN)); then
    local filtered=() orphan debug
    for orphan in "${orphans[@]}"; do
      [[ "$orphan" == go ]] && continue
      for debug in "${DEBUG_PACKAGES[@]}"; do
        [[ "$orphan" == "$debug" ]] && continue 2
      done
      filtered+=("$orphan")
    done
    orphans=("${filtered[@]}")
  fi
  if ((${#orphans[@]})); then
    if ((DRY_RUN)); then
      printf '[dry-run] sudo pacman -Rns'
      printf ' %q' "${orphans[@]}"
      printf '\n'
    else
      sudo pacman -Rns "${orphans[@]}"
    fi
  else
    echo "No orphan packages found."
  fi
}

doctor() {
  local failed=0 command font xrandr_output orphan_output
  detect
  check_packages
  validate_sources

  echo "Runtime commands:"
  for command in bspwm sxhkd polybar picom rofi dunst kitty fish xrandr \
    xss-lock udiskie redshift fzf fd bat eza zoxide jq; do
    if command -v "$command" >/dev/null 2>&1; then
      printf '  OK      %s\n' "$command"
    else
      printf '  MISSING %s\n' "$command"
      failed=1
    fi
  done

  echo "Fonts:"
  for font in "JetBrainsMono Nerd Font" "Noto Color Emoji"; do
    if fc-match "$font" 2>/dev/null | grep -qi "${font%% *}"; then
      printf '  OK      %s\n' "$font"
    else
      printf '  CHECK   %s\n' "$font"
      failed=1
    fi
  done

  echo "Display:"
  if [[ -n "${DISPLAY:-}" ]]; then
    if xrandr_output="$(xrandr --query 2>/dev/null)"; then
      awk '$2 == "connected" {print "  " $1, $2, $3}' <<<"$xrandr_output"
    else
      echo "  DISPLAY=$DISPLAY is not accessible in this execution context."
    fi
  else
    echo "  DISPLAY is not available; runtime RandR check skipped."
  fi

  echo "Display manager:"
  for command in lightdm.service sddm.service gdm.service ly@tty1.service; do
    if systemctl is-enabled "$command" >/dev/null 2>&1; then
      printf '  enabled %s\n' "$command"
    fi
  done

  echo "Orphan packages:"
  orphan_output="$(pacman -Qdtq 2>/dev/null || true)"
  if [[ -n "$orphan_output" ]]; then
    printf '%s\n' "$orphan_output"
  else
    echo "  none"
  fi

  return "$failed"
}

print_finish() {
  cat <<EOF

Installation finished.

Next steps:
  1. Reboot, or log out and back in.
  2. Log in on tty1; bash_profile starts BSPWM automatically through startx.
  3. In BSPWM press Super+Enter for a terminal.
  4. Use Super+Shift+M to toggle laptop/external monitor profiles.

Backups, when created, are stored under:
  $BACKUP_DIR
EOF
}

run_wizard() {
  cat <<EOF
HELL4GAET BSPWM installer

This wizard can install the desktop, CLI and AUR packages, copy dotfiles with
backups and enable services. The desktop starts from tty1 through startx.
EOF

  confirm "Continue with the BSPWM desktop installation?" yes || exit 0

  if confirm "Install the core desktop packages?" yes; then
    install_packages
  fi
  if confirm "Install lock, Polkit, automount and Thunar integration?" yes; then
    install_integration_packages
  fi
  if confirm "Install command-line tools?" yes; then
    install_cli_packages
  fi
  if confirm "Install required AUR packages (i3lock-color, Bibata)?" yes; then
    install_aur_packages
  fi
  if confirm "Install dotfiles into $HOME?" yes; then
    install_dotfiles
  fi
  if confirm "Enable NetworkManager, Bluetooth, keyd, power profiles and PipeWire?" yes; then
    enable_services
  fi
  if confirm "Install optional developer tools?" no; then
    install_dev_packages
  fi
  if confirm "Install optional GoLand?" no; then
    install_goland
  fi
  print_finish
}

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
  [[ $# -gt 0 ]] || {
    echo "--dry-run requires another option" >&2
    exit 2
  }
fi

if [[ "${1:-}" != "--help" && "${1:-}" != "-h" ]]; then
  require_arch
fi

case "${1:-}" in
  "")
    run_wizard
    ;;
  --help | -h)
    show_help
    ;;
  --check)
    detect
    check_packages
    validate_sources
    ;;
  --packages)
    install_packages
    ;;
  --integration)
    install_integration_packages
    ;;
  --cli)
    install_cli_packages
    ;;
  --dev)
    install_dev_packages
    ;;
  --aur)
    install_aur_packages
    ;;
  --goland)
    install_goland
    ;;
  --docker)
    install_docker
    ;;
  --go)
    install_group "${GO_PACKAGES[@]}"
    ;;
  --rust)
    install_group "${RUST_PACKAGES[@]}"
    ;;
  --jdk)
    install_group "${JDK_PACKAGES[@]}"
    ;;
  --browser-firefox)
    install_group "${FIREFOX_PACKAGES[@]}"
    ;;
  --browser-chromium)
    install_group "${CHROMIUM_PACKAGES[@]}"
    ;;
  --dotfiles)
    install_dotfiles
    ;;
  --update)
    install_dotfiles
    ;;
  --restore)
    restore_backup "${2:-}"
    ;;
  --uninstall)
    uninstall_dotfiles
    ;;
  --doctor)
    doctor
    ;;
  --cleanup)
    cleanup_packages
    ;;
  --services)
    enable_services
    ;;
  --all)
    install_packages
    install_integration_packages
    install_cli_packages
    install_aur_packages
    install_dotfiles
    enable_services
    print_finish
    ;;
  *)
    echo "Unknown option: $1" >&2
    show_help
    exit 2
    ;;
esac
