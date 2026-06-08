#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

CORE_PACKAGES=(
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xsetroot
  xorg-setxkbmap xorg-xkbcomp xorg-xmodmap xorg-xrdb
  bspwm sxhkd polybar picom rofi dunst
  kitty fish fastfetch thunar mousepad firefox code btop keyd matugen
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  networkmanager network-manager-applet bluez bluez-utils blueman
  pavucontrol pamixer playerctl brightnessctl
  flameshot xclip feh mpv telegram-desktop lxappearance
  papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-dejavu
  git base-devel ripgrep
)

AUR_DESKTOP_PACKAGES=(
  alttab
  i3lock-color
  bibata-cursor-theme
)

AUR_GOLAND_PACKAGES=(goland goland-jre)

DEV_PACKAGES=(
  nodejs npm pnpm
  python python-pip python-pipx
  go rustup jdk-openjdk
  docker docker-compose
  openssh github-cli lazygit shellcheck shfmt
)

DOCKER_PACKAGES=(docker docker-compose)
GO_PACKAGES=(go)
RUST_PACKAGES=(rustup)
JDK_PACKAGES=(jdk-openjdk)
FIREFOX_PACKAGES=(firefox)
CHROMIUM_PACKAGES=(chromium)
LOGIN_PACKAGES=(ly)
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
  --aur               Install desktop AUR packages; bootstraps yay if needed.
  --dev               Install optional developer packages.
  --goland            Install optional GoLand packages from AUR.
  --docker            Install Docker packages and enable docker.service.
  --go                Install Go.
  --rust              Install rustup.
  --jdk               Install OpenJDK.
  --browser-firefox   Install Firefox.
  --browser-chromium  Install Chromium.
  --login-manager     Install and enable ly display manager.
  --dotfiles          Copy dotfiles into \$HOME with timestamped backups.
  --services          Enable NetworkManager, bluetooth and PipeWire user units.
  --all               Install desktop packages, AUR, dotfiles and services.
  --help              Show this help.

Existing dotfiles are moved to a timestamped backup before replacement.
EOF
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer supports Arch Linux and pacman-based systems." >&2
    exit 1
  fi
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
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
  check_group "desktop AUR" "${AUR_DESKTOP_PACKAGES[@]}"
  check_group "GoLand AUR" "${AUR_GOLAND_PACKAGES[@]}"
  check_group "developer" "${DEV_PACKAGES[@]}"
  check_group "firefox" "${FIREFOX_PACKAGES[@]}"
  check_group "chromium" "${CHROMIUM_PACKAGES[@]}"
  check_group "login manager" "${LOGIN_PACKAGES[@]}"
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

install_dev_packages() {
  install_group "${DEV_PACKAGES[@]}"
}

install_aur_packages() {
  ensure_yay
  yay -S --needed "${AUR_DESKTOP_PACKAGES[@]}"
}

install_goland() {
  ensure_yay
  yay -S --needed "${AUR_GOLAND_PACKAGES[@]}"
}

install_docker() {
  install_group "${DOCKER_PACKAGES[@]}"
  sudo systemctl enable --now docker.service
  sudo usermod -aG docker "$USER"
  echo "Docker group membership takes effect after the next login."
}

install_login_manager() {
  install_group "${LOGIN_PACKAGES[@]}"
  sudo systemctl enable ly@tty1.service
}

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${target#$HOME/}")"
    mv "$target" "$BACKUP_DIR/${target#$HOME/}"
    echo "Backed up $target -> $BACKUP_DIR/${target#$HOME/}"
  fi
}

copy_dir() {
  local src="$1"
  local dst="$2"
  backup_path "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

copy_file() {
  local src="$1"
  local dst="$2"
  backup_path "$dst"
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
      Mains|USB|USB_C)
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

install_dotfiles() {
  copy_dir "$ROOT_DIR/config/bspwm" "$HOME/.config/bspwm"
  copy_dir "$ROOT_DIR/config/sxhkd" "$HOME/.config/sxhkd"
  copy_dir "$ROOT_DIR/config/polybar" "$HOME/.config/polybar"
  copy_dir "$ROOT_DIR/config/picom" "$HOME/.config/picom"
  copy_dir "$ROOT_DIR/config/rofi" "$HOME/.config/rofi"
  copy_dir "$ROOT_DIR/config/dunst" "$HOME/.config/dunst"
  copy_dir "$ROOT_DIR/config/kitty" "$HOME/.config/kitty"
  copy_dir "$ROOT_DIR/config/fish" "$HOME/.config/fish"
  copy_dir "$ROOT_DIR/config/fastfetch" "$HOME/.config/fastfetch"
  copy_dir "$ROOT_DIR/config/matugen" "$HOME/.config/matugen"
  copy_dir "$ROOT_DIR/config/btop" "$HOME/.config/btop"
  copy_dir "$ROOT_DIR/config/flameshot" "$HOME/.config/flameshot"
  copy_dir "$ROOT_DIR/config/keyd" "$HOME/.config/keyd"
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
  copy_file "$ROOT_DIR/gitconfig" "$HOME/.gitconfig"
  copy_file "$ROOT_DIR/config/mimeapps.list" "$HOME/.config/mimeapps.list"
  configure_hardware
  chmod +x "$HOME/.config/bspwm/bspwmrc" "$HOME/.config/polybar/launch.sh" "$HOME/.local/bin/"*
  find "$HOME/.config/bspwm/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  validate_dotfiles
}

enable_services() {
  sudo install -Dm644 "$ROOT_DIR/config/keyd/default.conf" /etc/keyd/default.conf
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable --now bluetooth.service
  sudo systemctl enable --now keyd.service
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service || true
}

print_finish() {
  cat <<EOF

Installation finished.

Next steps:
  1. Reboot, or log out and back in.
  2. From a TTY run: startx
  3. In BSPWM press Super+Enter for a terminal.
  4. Use Super+Shift+M to toggle laptop/external monitor profiles.

Backups, when created, are stored under:
  $BACKUP_DIR
EOF
}

run_wizard() {
  cat <<EOF
HELL4GAET BSPWM installer

This wizard can install the desktop packages, required AUR packages,
copy dotfiles with backups, and enable desktop services.
EOF

  confirm "Continue with the BSPWM desktop installation?" yes || exit 0

  if confirm "Install the core desktop packages?" yes; then
    install_packages
  fi
  if confirm "Install required AUR packages (alttab, i3lock-color, Bibata)?" yes; then
    install_aur_packages
  fi
  if confirm "Install dotfiles into $HOME?" yes; then
    install_dotfiles
  fi
  if confirm "Enable NetworkManager, Bluetooth, keyd and PipeWire?" yes; then
    enable_services
  fi
  if confirm "Install optional developer tools?" no; then
    install_dev_packages
  fi
  if confirm "Install optional GoLand?" no; then
    install_goland
  fi
  if confirm "Install the optional ly login manager?" no; then
    install_login_manager
  fi

  print_finish
}

require_arch

case "${1:-}" in
  "")
    run_wizard
    ;;
  --help|-h)
    show_help
    ;;
  --check)
    detect
    check_packages
    ;;
  --packages)
    install_packages
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
  --login-manager)
    install_login_manager
    ;;
  --dotfiles)
    install_dotfiles
    ;;
  --services)
    enable_services
    ;;
  --all)
    install_packages
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
