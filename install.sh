#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

CORE_PACKAGES=(
  xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-setxkbmap
  bspwm sxhkd polybar picom rofi dunst alttab
  alacritty kitty fish thunar firefox code i3lock btop keyd
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  networkmanager network-manager-applet bluez bluez-utils blueman
  pavucontrol pamixer playerctl brightnessctl
  flameshot xclip feh lxappearance
  papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-dejavu
  git base-devel ripgrep
)

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
  --check             Show detected hardware names and missing package groups.
  --packages          Install the curated BSPWM desktop package list.
  --dev               Install curated developer packages.
  --docker            Install Docker packages and enable docker.service.
  --go                Install Go.
  --rust              Install rustup.
  --jdk               Install OpenJDK.
  --browser-firefox   Install Firefox.
  --browser-chromium  Install Chromium.
  --login-manager     Install and enable ly display manager.
  --dotfiles          Copy dotfiles into \$HOME with timestamped backups.
  --services          Enable NetworkManager, bluetooth and PipeWire user units.
  --all               Run --packages, --dotfiles and --services only.
  --help              Show this help.

No option is destructive by default.
No AUR packages are installed by this script.
EOF
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

install_packages() {
  install_group "${CORE_PACKAGES[@]}"
}

install_dev_packages() {
  install_group "${DEV_PACKAGES[@]}"
}

install_docker() {
  install_group "${DOCKER_PACKAGES[@]}"
  sudo systemctl enable docker.service
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

install_dotfiles() {
  copy_dir "$ROOT_DIR/config/bspwm" "$HOME/.config/bspwm"
  copy_dir "$ROOT_DIR/config/sxhkd" "$HOME/.config/sxhkd"
  copy_dir "$ROOT_DIR/config/polybar" "$HOME/.config/polybar"
  copy_dir "$ROOT_DIR/config/picom" "$HOME/.config/picom"
  copy_dir "$ROOT_DIR/config/rofi" "$HOME/.config/rofi"
  copy_dir "$ROOT_DIR/config/dunst" "$HOME/.config/dunst"
  copy_dir "$ROOT_DIR/config/alacritty" "$HOME/.config/alacritty"
  copy_dir "$ROOT_DIR/config/kitty" "$HOME/.config/kitty"
  copy_dir "$ROOT_DIR/config/fish" "$HOME/.config/fish"
  copy_dir "$ROOT_DIR/config/btop" "$HOME/.config/btop"
  copy_dir "$ROOT_DIR/config/flameshot" "$HOME/.config/flameshot"
  copy_dir "$ROOT_DIR/config/keyd" "$HOME/.config/keyd"
  copy_dir "$ROOT_DIR/config/Code - OSS" "$HOME/.config/Code - OSS"
  copy_dir "$ROOT_DIR/config/gtk-3.0" "$HOME/.config/gtk-3.0"
  copy_dir "$ROOT_DIR/config/gtk-4.0" "$HOME/.config/gtk-4.0"
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
  chmod +x "$HOME/.config/bspwm/bspwmrc" "$HOME/.config/polybar/launch.sh" "$HOME/.local/bin/"*
}

enable_services() {
  sudo systemctl enable NetworkManager.service
  sudo systemctl enable bluetooth.service
  systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service || true
}

case "${1:-}" in
  --help|-h|"")
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
    install_dotfiles
    enable_services
    ;;
  *)
    echo "Unknown option: $1" >&2
    show_help
    exit 2
    ;;
esac
