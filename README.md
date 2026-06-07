# HELL4GAET Arch BSPWM dotfiles

Лёгкий X11-десктоп для Arch Linux: BSPWM, SXHKD, Polybar, Rofi, Picom,
PipeWire, NetworkManager и Bluetooth. Конфигурация адаптирована для ноутбука и
внешнего 4K-монитора.

## Быстрая установка

На новой установленной Arch Linux должен работать интернет, а пользователь
должен иметь доступ к `sudo`.

```bash
sudo pacman -Syu --needed git base-devel
git clone https://github.com/HELL4GAET/HELL4GAET-arch-bspwm-dotfiles.git
cd HELL4GAET-arch-bspwm-dotfiles
./install.sh
```

`./install.sh` запускает интерактивный мастер. Для обычной установки отвечай
`Y` на первые четыре вопроса:

1. установить основные пакеты рабочего стола;
2. установить обязательные AUR-пакеты;
3. установить dotfiles;
4. включить системные сервисы.

Developer tools, GoLand и дисплейный менеджер `ly` устанавливаются только по
отдельному подтверждению.

После завершения:

```bash
reboot
```

Войди в TTY и запусти:

```bash
startx
```

Терминал открывается через `Super+Enter`, меню приложений через `Super+D`.

## Установка одной командой

Основной сценарий одной командой:

```bash
./install.sh --all
```

Он устанавливает основные пакеты, обязательные AUR-пакеты, dotfiles и сервисы.
Пароль `sudo` всё равно потребуется.

Доступные отдельные этапы:

```bash
./install.sh --check
./install.sh --packages
./install.sh --aur
./install.sh --dotfiles
./install.sh --services
./install.sh --dev
./install.sh --goland
./install.sh --login-manager
./install.sh --help
```

Если `yay` отсутствует, этап `--aur` соберёт его из официального AUR.

## Что устанавливается

Основной рабочий стол:

- BSPWM, SXHKD, Polybar, Picom, Rofi, Dunst и Alttab;
- Alacritty, Kitty, Fish и Bash;
- PipeWire, WirePlumber, Pavucontrol и управление громкостью;
- NetworkManager, Blueman и Bluetooth;
- Thunar, Firefox, Code OSS, Telegram Desktop, MPV и Flameshot;
- JetBrainsMono Nerd Font, Noto Fonts и Papirus;
- белый курсор `Bibata-Modern-Ice`;
- lockscreen через `i3lock-color`;
- GTK-тема `Dracula-pink-accent`.

Опционально мастер может установить:

- developer tools: Go, Rust, Node.js, Python, JDK, Docker, GitHub CLI;
- GoLand;
- дисплейный менеджер `ly`.

Профили браузеров, SSH-ключи, VPN, Telegram session, JetBrains license,
кэши и пароли в репозиторий не входят.

## Безопасность установки

Перед заменой существующих файлов установщик переносит их в:

```text
~/.dotfiles-backup/YYYYMMDD-HHMMSS/
```

Установщик нужно запускать обычным пользователем. Запуск от `root` запрещён.

После копирования автоматически определяются:

- Wi-Fi интерфейс;
- backlight device;
- батарея;
- AC/USB power adapter.

Найденные значения записываются в установленный
`~/.config/polybar/modules.ini`.

## Запуск с графическим логином

По умолчанию используется `startx`. Для установки лёгкого login manager:

```bash
./install.sh --login-manager
```

Команда устанавливает `ly` и включает `ly@tty1.service`. Autologin не
настраивается.

## Мониторы и HiDPI

`Super+Shift+M` переключает активный экран:

- внутренний экран → внешний;
- внешний экран → внутренний.

Одновременно используется только один экран. Скрипт находится здесь:

```text
~/.config/bspwm/scripts/monitor-switch.sh
```

Профиль ноутбука:

- родное разрешение;
- `Xft.dpi=120`;
- Qt scale `1`;
- курсор `24`;
- Polybar `31 px`;
- верхний отступ BSPWM `56 px`.

Профиль внешнего монитора:

- `3840x2160@60`, с fallback на `xrandr --auto`;
- `Xft.dpi=168`;
- Qt scale `1.75`;
- курсор `32`;
- Polybar `54 px`;
- верхний отступ BSPWM `86 px`.

При переключении рабочие столы `1-5` переносятся на активный монитор,
перезапускается Polybar и повторно применяются обои. SXHKD не перезапускается.

Проверка:

```bash
xrandr --query
bspc query -M --names
cat ~/.cache/monitor-profile
pgrep -a polybar
pgrep -a sxhkd
```

Логи:

```text
~/.cache/monitor-switch.log
/tmp/monitor-switch-polybar.log
/tmp/polybar-<monitor>.log
```

## Polybar

Слева находятся рабочие столы, в центре температура, память и CPU. Справа:

- батарея;
- яркость;
- звук;
- раскладка;
- часы;
- Bluetooth;
- Wi-Fi;
- питание.

Общий system tray отключён, поэтому иконки запущенных приложений в Polybar не
попадают. Значок Bluetooth открывает `blueman-manager`, Wi-Fi открывает
`nm-connection-editor`.

## Picom

Picom настроен на минимальный визуальный слой:

- backend `glx`;
- VSync включён;
- тени выключены;
- blur выключен;
- скругления выключены;
- fading и прозрачность выключены.

## Обои

Применить текущую:

```bash
wallpaper
```

Выбрать случайную из `~/.config/bspwm/wallpapers`:

```bash
wallpaper --random
```

## Основные клавиши

```text
Super+Enter          терминал
Super+D              приложения
Super+Shift+D        запуск команды
Super+Shift+Enter    список окон
Super+Q              закрыть окно
Super+1..5           рабочие столы
Super+Shift+1..5     перенести окно
Super+H/J/K/L        фокус
Super+Shift+H/J/K/L  обмен окон
Super+Shift+M        переключить монитор
Print                Flameshot
```

Полный список: [docs/keybindings.md](docs/keybindings.md).

## Проверка после установки

```bash
./install.sh --check
```

Также полезно проверить:

```bash
systemctl status NetworkManager bluetooth keyd
systemctl --user status pipewire pipewire-pulse wireplumber
command -v bspwm sxhkd polybar picom rofi
```

Если Polybar не показывает устройство, проверь:

```bash
ip -brief link
ls /sys/class/backlight
ls /sys/class/power_supply
```

и соответствующие секции в `~/.config/polybar/modules.ini`.

## Происхождение

Внешний вид частично основан на идеях
[`Zproger/bspwm-dotfiles`](https://github.com/Zproger/bspwm-dotfiles), но
builder и широкая политика установки оригинала не используются. Скрипты
мониторов, установки, звука, яркости, lockscreen и Polybar адаптированы под
этот репозиторий.
