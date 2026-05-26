# HELL4GAET Arch BSPWM dotfiles

Minimal X11 desktop based on ideas from Zproger/bspwm-dotfiles, but without
running its builder and without broad package sets.

## Scope

- bspwm, sxhkd, polybar, picom, rofi, dunst
- PipeWire audio
- NetworkManager, bluetooth
- VS Code/dev friendly defaults
- us/ru layout toggle
- screenshots, clipboard, brightness, volume

Excluded on purpose: tor, tor browser, mpd, ncmpcpp, libreoffice, gparted,
kdenlive, audacity, anki, wireshark, veracrypt, deluge and random AUR packages.

## Zproger audit

The upstream repository is useful as a visual/config reference, but its builder
is intentionally not used here. It installs a broad desktop/app set and contains
the exact actions this repo avoids:

- `chsh -s /usr/bin/fish`
- `sudo chmod -R 700 ~/.config/*`
- `sudo ln -sf /usr/bin/alacritty /usr/bin/xterm`
- enabling `tor.service`
- enabling user `mpd`

Only the BSPWM-related ideas are carried forward, with local scripts rewritten
for this machine.

## Current hardware assumptions

- Wi-Fi interface: `wlp3s0`
- Wired interface: `enp5s0`
- Backlight: `amdgpu_bl1`
- Battery: `BAT0`
- AC adapter: `AC`
- Internal display: `eDP-1`

Adjust `config/polybar/modules.ini` and `local/bin/monitors` if hardware names
change.

## Usage

Preview:

```sh
./install.sh --help
./install.sh --check
```

Install packages:

```sh
./install.sh --packages
```

Optional developer/browser groups:

```sh
./install.sh --dev
./install.sh --docker
./install.sh --go
./install.sh --rust
./install.sh --jdk
./install.sh --browser-firefox
./install.sh --browser-chromium
```

Copy dotfiles with backup:

```sh
./install.sh --dotfiles
```

Enable NetworkManager/bluetooth/PipeWire units:

```sh
./install.sh --services
```

Start X from TTY:

```sh
startx
```

## Login options

Current setup uses `startx`, which is the lightest normal launch path for this
BSPWM desktop. A graphical login manager can be added later as an explicit
choice, for example `ly` or `lightdm`, but it is not enabled by default.

To use a lightweight graphical login screen:

```sh
./install.sh --login-manager
```

This installs and enables `ly.service`. It does not enable autologin.
On current Arch packages this is enabled as `ly@tty1.service`.

## Visual Layer

The visual layer mirrors the Zproger setup while keeping the cleaned package and
service policy:

- `alacritty` with JetBrainsMono Nerd Font and Zproger-style colors
- `fish` inside alacritty only; login shell is not changed
- Zproger-style polybar, rofi, dunst, picom and Xresources
- Dracula-pink-accent GTK theme with Papirus-Dark icons
- curated Zproger wallpapers under `config/bspwm/wallpapers`
