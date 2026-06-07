# HELL4GAET Arch BSPWM dotfiles

Минимальный X11-десктоп на Arch Linux с BSPWM. Конфиги частично опираются на
идеи из `Zproger/bspwm-dotfiles`, но без запуска их билдера и без установки
широкого набора приложений.

## Состав

- `bspwm`, `sxhkd`, `polybar`, `picom`, `rofi`, `dunst`, `alttab`
- `alacritty`, `kitty`, `fish`, `bash`
- `btop`, `flameshot`, `keyd`, пользовательские настройки `Code - OSS`
- `mpv`, `telegram-desktop`, GoLand defaults
- lockscreen через `i3lock-color`
- звук через PipeWire
- NetworkManager и bluetooth
- базовые настройки для VS Code/dev-среды
- переключение раскладок `us/ru`
- скриншоты, clipboard, яркость, громкость
- ручное переключение между ноутбучным экраном и внешним 4K-монитором
- MIME defaults: изображения через `feh`, видео через `mpv`, browser links через Firefox

Намеренно не включены: профили браузеров, VPN-профили, SSH-ключи, кэши,
runtime-состояние, `tor`, `torbrowser-launcher`, `mpd`, `ncmpcpp`, LibreOffice,
`gparted`, `kdenlive`, `audacity`, `anki`, `wireshark`, `veracrypt`, `deluge` и
случайные AUR-пакеты.

## Почему не запускается Zproger builder

Оригинальный репозиторий полезен как визуальный и конфигурационный референс, но
его builder здесь намеренно не используется. Он делает слишком широкие изменения
для этой машины, включая действия, которых этот репозиторий избегает:

- `chsh -s /usr/bin/fish`
- `sudo chmod -R 700 ~/.config/*`
- `sudo ln -sf /usr/bin/alacritty /usr/bin/xterm`
- включение `tor.service`
- включение пользовательского `mpd`

Из Zproger-подхода здесь оставлены только идеи, связанные с BSPWM, а локальные
скрипты переписаны под текущую систему.

## Текущие аппаратные предположения

- Wi-Fi интерфейс: `wlp3s0`
- Ethernet интерфейсы: `enp2s0f0`, `enp5s0`
- Backlight: `amdgpu_bl1`
- Батарея: `BAT0`
- AC-адаптер: `AC`
- Встроенный дисплей: `eDP-1`
- Внешний 27" 4K дисплей: `DP-1`, режим `3840x2160`

Если имена устройств изменятся, в первую очередь проверь
`config/polybar/modules.ini`, `config/bspwm/bspwmrc` и переменные в начале
`config/bspwm/scripts/monitor-switch.sh`.

## Использование

Справочник по хоткеям системы и LazyVim/Go лежит в
`docs/keybindings.md`.

Посмотреть справку и проверить текущее железо/пакеты:

```sh
./install.sh --help
./install.sh --check
```

`--check` ничего не устанавливает и не копирует. Он только читает имена
устройств из `/sys/class/*` и проверяет наличие пакетов через `pacman -Q`.

Установить основной набор пакетов для десктопа:

```sh
./install.sh --packages
```

Опциональные группы для разработки и браузеров:

```sh
./install.sh --dev
./install.sh --docker
./install.sh --go
./install.sh --rust
./install.sh --jdk
./install.sh --browser-firefox
./install.sh --browser-chromium
```

Обязательные AUR-пакеты:

```sh
./install.sh --aur
```

Эта команда требует установленный `yay` и ставит `goland`, `goland-jre` и
`i3lock-color`. `install.sh --check` проверяет их наличие как `required AUR`.

Скопировать dotfiles в `$HOME` с бэкапом старых файлов по timestamp:

```sh
./install.sh --dotfiles
```

Бэкапы создаются в:

```sh
~/.dotfiles-backup/YYYYMMDD-HHMMSS/
```

Включить сервисы NetworkManager, bluetooth и пользовательские PipeWire units:

```sh
./install.sh --services
```

Выполнить основной сценарий:

```sh
./install.sh --all
```

`--all` запускает только `--packages`, `--dotfiles` и `--services`. Он не ставит
опциональные dev/browser/login-manager/AUR группы.

Запуск X из TTY:

```sh
startx
```

## Логин

Текущая схема рассчитана на `startx`: это самый простой и лёгкий путь запуска
этого BSPWM-десктопа.

Если нужен лёгкий графический экран входа:

```sh
./install.sh --login-manager
```

Эта команда устанавливает `ly` и включает `ly@tty1.service`. Autologin не
настраивается.

## Визуальный слой

Визуальный слой близок к Zproger-стилю, но с очищенной политикой пакетов и
сервисов:

- `alacritty` и `kitty` используют JetBrainsMono Nerd Font и цвета в духе
  Zproger-конфига
- `fish` используется внутри `alacritty`; login shell не меняется
- Polybar, rofi, dunst, picom и Xresources выдержаны в Zproger-like стиле
- окна в `picom` непрозрачные: `active-opacity`, `inactive-opacity` и
  `frame-opacity` выставлены в `1.0`
- `alttab` запускается через `bspwmrc` в EWMH-режиме и показывает окна со всех
  рабочих столов
- GTK-тема: Dracula-pink-accent, иконки: Papirus-Dark
- обои лежат в `config/bspwm/wallpapers`
- текущая обоина применяется через `~/.local/bin/wallpaper` и
  `~/.config/bspwm/wallpaper.png`
- сейчас `config/bspwm/wallpaper.png` является симлинком на
  `config/bspwm/wallpapers/wallpaper.jpg`

## Мониторы и HiDPI

Текущая схема мониторов намеренно ручная: автоматический polling watcher не
включён, потому что при резком hotplug он мог рассинхронизировать `xrandr` и
BSPWM. Безопасный путь сейчас — запускать переключатель вручную:

```sh
~/.config/bspwm/scripts/monitor-switch.sh
```

Горячая клавиша:

```text
super + shift + m
```

Скрипт `config/bspwm/scripts/monitor-switch.sh`:

- если `DP-1` подключён, включает его как primary в `3840x2160`, отключает
  активную картинку на `eDP-1`, переносит BSPWM desktops `1 2 3 4 5` на `DP-1`
  и пишет профиль `external` в `~/.cache/monitor-profile`
- если `DP-1` не подключён, возвращает primary на `eDP-1`, переносит desktops
  на ноутбучный экран и пишет профиль `laptop`
- обновляет `Xft.dpi`, GTK font/DPI/cursor size, Rofi font и известные строки
  `height`/`font-*` в `~/.config/polybar/config.ini`
- перезапускает Polybar через `config/polybar/launch.sh`

Профили читаемости:

- `laptop`: `Xft.dpi=120`, GTK dpi `122880`, Rofi font `14`, Polybar `31`,
  Polybar fonts `13/18`
- `external`: `Xft.dpi=168`, GTK dpi `172032`, Rofi font `17`, Polybar `40`,
  Polybar fonts `16/22`

Проверка состояния:

```sh
xrandr --query
bspc query -M --names
pgrep -a -x polybar
cat ~/.cache/monitor-profile
```

Ожидаемо на внешнем мониторе:

```text
DP-1 primary 3840x2160
bspc -> DP-1
monitor-profile -> external
```

Ожидаемо на ноутбуке:

```text
eDP-1 primary 1920x1080
bspc -> eDP-1
monitor-profile -> laptop
```

`config/polybar/config.ini` хранится в репозитории в laptop baseline. External
размеры применяются самим `monitor-switch.sh` на установленной системе.

## Bluetooth и Apple Magic Keyboard

Bluetooth включается через `bluetooth.service`, а Blueman запускается из
`bspwmrc`. Для Apple Magic Keyboard на этой машине рабочий путь — pairing через
`bluetoothctl` с подтверждением passkey на компьютере, а не вводом кода на
клавиатуре.

Если Blueman показывает код без кнопок подтверждения, используй:

```sh
bluetoothctl
agent DisplayOnly
default-agent
scan on
```

Когда появится `Magic Keyboard`:

```sh
scan off
pair 1C:1D:D3:78:B9:2A
```

Если появится запрос вида:

```text
[agent] Confirm passkey 123456 (yes/no):
```

нужно ввести `yes` в `bluetoothctl`. После успешного pairing:

```sh
trust 1C:1D:D3:78:B9:2A
connect 1C:1D:D3:78:B9:2A
```

Проверка:

```sh
bluetoothctl info 1C:1D:D3:78:B9:2A
xinput list
```

Рабочее состояние:

```text
Paired: yes
Bonded: yes
Trusted: yes
Connected: yes
Magic Keyboard ... [slave keyboard]
```

## Текущий снимок системы

Репозиторий зеркалит текущее состояние BSPWM-десктопа на этой машине. Старые
helper-скрипты для мониторов и UI scaling удалены, потому что live-конфиг их
больше не использует:

- `local/bin/monitors`
- `local/bin/ui-size`

Мониторы теперь переключаются через `config/bspwm/scripts/monitor-switch.sh`, а
Polybar запускается на активных мониторах из `config/polybar/launch.sh`.

## Политика install.sh

- Скрипт ставит AUR-пакеты только при явном запуске `./install.sh --aur`.
- `i3lock-color` нужен для lockscreen.
- `goland` и `goland-jre` нужны для GoLand.
- Данные аккаунта Telegram, JetBrains license/key, кэши и recent project state
  намеренно не сохраняются в репозитории.
- Опции с установкой пакетов используют `sudo pacman -S --needed`.
- `--dotfiles` перед копированием переносит существующие файлы в
  `~/.dotfiles-backup/...`, а не удаляет их.
- Без аргументов или с `--help` скрипт только печатает справку.
