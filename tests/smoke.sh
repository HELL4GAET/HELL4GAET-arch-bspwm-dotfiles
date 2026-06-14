#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n \
  "$root/install.sh" \
  "$root/xinitrc" \
  "$root/config/bspwm/bspwmrc" \
  "$root/config/bspwm/scripts/monitor-switch.sh" \
  "$root/config/polybar/launch.sh" \
  "$root"/local/bin/*

if systemctl --user show-environment >/dev/null 2>&1; then
  systemd-analyze --user verify "$root/config/systemd/user/bspwm-session.target"
fi

if command -v fish >/dev/null 2>&1; then
  fish -n "$root/config/fish/config.fish"
fi

if command -v keyd >/dev/null 2>&1; then
  keyd check "$root/config/keyd/default.conf"
fi

help_output="$("$root/install.sh" --help)"
packages_output="$("$root/install.sh" --dry-run --packages)"
integration_output="$("$root/install.sh" --dry-run --integration)"
cli_output="$("$root/install.sh" --dry-run --cli)"
dotfiles_output="$("$root/install.sh" --dry-run --dotfiles)"
cleanup_output="$("$root/install.sh" --dry-run --cleanup)"
login_output="$("$root/install.sh" --dry-run --login-manager)"

grep -q -- '--doctor' <<<"$help_output"
grep -q ' go' <<<"$packages_output"
grep -q ' unzip' <<<"$packages_output"
grep -q 'pacman -S' <<<"$integration_output"
grep -q 'pacman -S' <<<"$cli_output"
grep -q 'copy directory' <<<"$dotfiles_output"
grep -Eq 'pacman -D --asexplicit go|No orphan packages found' <<<"$cleanup_output"
grep -q 'lightdm' <<<"$login_output"

echo "repository smoke tests: OK"
