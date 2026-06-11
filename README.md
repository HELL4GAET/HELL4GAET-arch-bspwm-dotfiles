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

Developer tools, Neovim, GoLand и дисплейный менеджер `ly` устанавливаются только по
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

## Рекомендуемые настройки archinstall

Запускай `archinstall` из актуального официального Arch Linux ISO. Перед
запуском подключи интернет; Wi-Fi при необходимости настраивается через
`iwctl`.

Для чистой установки под этот репозиторий рекомендуется:

- `Disk configuration`: автоматическая разметка свободного диска или ручная
  разметка, если рядом уже установлена другая ОС; файловая система `btrfs` или
  `ext4`;
- `Bootloader`: `systemd-boot` для обычной UEFI-установки, `GRUB` или `Limine`
  для BIOS и специфических multiboot-сценариев;
- `Swap`: включить;
- `Hostname`: любое удобное имя;
- `Root password`: по желанию;
- `User account`: создать обычного пользователя и дать ему `sudo`;
- `Profile`: `Minimal`, без Desktop/Window Manager profile;
- `Audio`: можно не выбирать, потому что installer поставит PipeWire и
  WirePlumber;
- `Network configuration`: `NetworkManager`;
- `Kernels`: стандартный `linux`; `linux-lts` можно добавить вторым;
- `Additional packages`: оставить пустым;
- `Timezone`, locale и keyboard layout: выбрать свои; X11-раскладки позже
  настроит этот репозиторий.

После завершения `archinstall` загрузись в установленную систему, войди обычным
пользователем и выполни команды из раздела «Быстрая установка». Не выбирай в
`archinstall` готовый Desktop/BSPWM profile: пакеты и конфиги рабочего стола
должны устанавливаться `./install.sh`, чтобы не получить конфликтующие настройки.
Актуальные названия и ограничения параметров описаны в
[официальной документации archinstall](https://archinstall.archlinux.page/installing/guided.html).

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
./install.sh --docker
./install.sh --go
./install.sh --rust
./install.sh --jdk
./install.sh --browser-firefox
./install.sh --browser-chromium
./install.sh --login-manager
./install.sh --help
```

Если `yay` отсутствует, этап `--aur` соберёт его из официального AUR.

## Что устанавливается

Основной рабочий стол:

- BSPWM, SXHKD, Polybar, Picom, Rofi, Dunst и Alttab;
- Kitty с Fish, кастомным prompt и Fastfetch;
- PipeWire, WirePlumber, Pavucontrol и управление громкостью;
- NetworkManager, Blueman и Bluetooth;
- Thunar, Firefox, Code OSS, Telegram Desktop, MPV и Flameshot;
- JetBrainsMono Nerd Font, Noto Fonts и Papirus;
- Matugen-based цвета для Kitty и Rofi;
- белый курсор `Bibata-Modern-Ice`;
- lockscreen через `i3lock-color`;
- GTK-тема `Dracula-pink-accent`.

Опционально мастер может установить:

- developer tools: Neovim, Go, Rust, Node.js, Python, JDK, Docker, GitHub CLI;
- GoLand;
- дисплейный менеджер `ly`.

Профили браузеров, SSH-ключи, VPN, Telegram session, JetBrains license,
кэши и пароли в репозиторий не входят.

Git identity намеренно не устанавливается. После установки задай собственные
значения:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Скрипты рабочего стола также явно устанавливают `libnotify`,
`nm-connection-editor` и `xdg-utils`, необходимые для уведомлений, управления
сетевыми подключениями и открытия URL.

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
- Polybar `1886x34+16+10`;
- отступы BSPWM `top=50`, `bottom=6`.

Профиль внешнего монитора:

- `3840x2160@60`, с fallback на `xrandr --auto`;
- `Xft.dpi=168`;
- Qt scale `1.75`;
- курсор `32`;
- Polybar `3806x46+16+12`;
- отступы BSPWM `top=72`, `bottom=14`.

При переключении рабочие столы `1-5` переносятся на активный монитор,
выключаются все неактивные RandR-выходы, включая зависшие `disconnected`
выходы с сохранённой геометрией, перезапускается Polybar, повторно применяются
обои и перечитывается конфигурация Dunst. SXHKD не перезапускается.

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

Слева находятся увеличенный фирменный значок Arch Linux `#1793D1` и рабочие
столы, в центре температура, память и CPU. Активный workspace выделяется жирной
цифрой и синей нижней линией, занятые workspace ярче пустых, срочные workspace
получают красную нижнюю линию без фонового квадрата.

Справа расположен выровненный системный блок:

- раскладка;
- батарея;
- яркость;
- звук;
- Bluetooth;
- Wi-Fi;
- время и дата `HH:MM dd.mm`.

Общий system tray отключён, поэтому иконки запущенных приложений в Polybar не
попадают. Синий значок Arch Linux слева открывает powermenu. Значок Bluetooth
открывает `blueman-manager`, Wi-Fi открывает `nm-connection-editor`.

## Picom

Picom настроен на ML4W-inspired визуальный слой:

- backend `glx`;
- VSync включён;
- мягкие тени включены;
- gaussian blur включён для прозрачных окон;
- fading включён;
- активные окна имеют opacity `0.90`, неактивные `0.78`;
- скругления `14 px`.

## Kitty, Fish и GoLand

`Super+Enter` открывает Kitty. Alacritty не используется и не устанавливается.
Kitty запускает Fish, использует Tokyo Night/Matugen цвета, прозрачность `0.62`,
скрытые декорации, powerline tabs и небольшой cursor trail.
В Kitty `Ctrl+V` явно вставляет содержимое системного clipboard.

Fish prompt показывает текущий путь, git branch, затем с новой строки значок
Arch Linux и текущего пользователя. При старте интерактивного Kitty один раз
показывается Fastfetch.

GoLand 2026.1 настроен на Fish во встроенном терминале через:

```text
~/.config/JetBrains/GoLand2026.1/options/terminal-local.xml
```

Также устанавливаются тёмная тема интерфейса GoLand, тёмная цветовая схема
редактора, compact UI и увеличенные editor/terminal fonts.

## Клавиатура и раскладки

Используются раскладки `us,ructrl`, переключение выполняется через
`Alt+Shift`. В русской раскладке сочетания с физическим `Ctrl` используют
латинские буквы, поэтому `Ctrl+C`, `Ctrl+V`, `Ctrl+X` и другие shortcut работают
без ручного переключения на английский.

Caps Lock остаётся обычным Caps Lock и не переназначается в Ctrl. `keyd`
используется только для преобразования аппаратной клавиши `Fn` в `F13`.

## Rofi и powermenu

Rofi использует прозрачную Tokyo Night/Matugen тему. `Super+D` открывает меню
приложений, `Super+Shift+D` — run prompt, `Super+Shift+Enter` — переключатель
окон. Powermenu открывается через `Super+Shift+X` или левый значок Arch Linux в
Polybar.

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

Команда также проверяет синтаксис shell/Fish-скриптов и конфигурацию `keyd`.

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
