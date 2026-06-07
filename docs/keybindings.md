# Бинды системы и LazyVim для Go

Этот файл фиксирует текущие системные хоткеи BSPWM/sxhkd и даёт рабочую карту
перехода с GoLand на Neovim/LazyVim для Go-разработки.

В обозначениях ниже:

- `super` = клавиша Windows/Meta.
- `<leader>` в LazyVim = `Space`.
- `<localleader>` в LazyVim = `\`.
- В LazyVim почти всё можно подсмотреть через which-key: нажми `Space` и жди
  всплывающее меню доступных команд.

## Системные бинды

Источник: `config/sxhkd/sxhkdrc`.

### Запуск приложений

| Бинд | Действие |
| --- | --- |
| `super + Return` | Открыть Alacritty |
| `super + d` | Rofi app launcher |
| `super + shift + d` | Rofi run prompt |
| `super + shift + Return` | Rofi window switcher |
| `super + shift + f` | Firefox |
| `super + shift + c` | Code - OSS |
| `super + shift + n` | Thunar |
| `super + shift + p` | Pavucontrol |
| `super + shift + b` | Blueman Manager |
| `super + shift + x` | Powermenu |
| `super + shift + m` | Переключить профиль монитора через `monitor-switch.sh` |

### Скриншоты

| Бинд | Действие |
| --- | --- |
| `Print` | Flameshot GUI |
| `super + Print` | Полный скриншот через `screenshot-full` |
| `super + shift + Print` | Выделение области через `screenshot-area` |
| `super + shift + a` | Выделение области через `screenshot-area` |

### Звук и яркость

| Бинд | Действие |
| --- | --- |
| `XF86AudioRaiseVolume` | Громкость вверх |
| `XF86AudioLowerVolume` | Громкость вниз |
| `XF86AudioMute` | Mute |
| `XF86MonBrightnessUp` | Яркость вверх |
| `XF86MonBrightnessDown` | Яркость вниз |

### Сессия и окна BSPWM

| Бинд | Действие |
| --- | --- |
| `super + Escape` | Перезагрузить sxhkd config |
| `ctrl + shift + q` | Выйти из BSPWM |
| `ctrl + shift + r` | Перезапустить BSPWM |
| `super + q` | Закрыть окно |
| `super + shift + q` | Убить окно |
| `super + space` | Toggle floating/tiled |
| `super + t` | Tiled |
| `super + shift + t` | Pseudo tiled |
| `super + f` | Fullscreen |
| `super + h/j/k/l` | Фокус west/south/north/east |
| `super + shift + h/j/k/l` | Swap окна west/south/north/east |
| `Alt + Tab` | Переключение окон через `alttab` со всех рабочих столов |
| `super + grave` | Последнее окно |
| `super + Tab` | Последний desktop |
| `super + 1-5` | Перейти на desktop 1-5 |
| `super + shift + 1-5` | Переместить окно на desktop 1-5 и перейти туда |
| `super + ctrl + h/j/k/l` | Resize окна |

## LazyVim: что включить для Go

Сейчас локальный `~/.config/nvim/lazyvim.json` показывает пустой список extras.
Для Go-разработки включи extras внутри Neovim:

```vim
:LazyExtras
```

Минимальный набор:

- `lang.go` — Go language support: Treesitter, `gopls`, `goimports`, `gofumpt`,
  `gomodifytags`, `impl`, `golangci-lint`, `delve`.
- `dap.core` — отладка через DAP.
- `test.core` — запуск тестов через neotest.
- Опционально `editor.aerial` — удобный outline/symbols view.
- Опционально `util.gitui` — git UI внутри Neovim, если не хватает LazyGit.

Потом:

```vim
:Lazy sync
:Mason
```

В `:Mason` проверь, что стоят `gopls`, `goimports`, `gofumpt`,
`gomodifytags`, `impl`, `golangci-lint`, `delve`.

Официальные страницы:

- LazyVim keymaps: https://www.lazyvim.org/keymaps
- LazyVim Go extra: https://www.lazyvim.org/extras/lang/go
- LazyVim DAP core: https://www.lazyvim.org/extras/dap/core

## LazyVim: базовая навигация

| Бинд | Действие |
| --- | --- |
| `<C-h/j/k/l>` | Перейти в окно слева/снизу/сверху/справа |
| `<C-Up/Down/Left/Right>` | Resize split |
| `<S-h>` / `<S-l>` | Предыдущий/следующий buffer |
| `[b` / `]b` | Предыдущий/следующий buffer |
| `<leader>bb` | Переключиться на другой buffer |
| `<leader>bd` | Закрыть buffer |
| `<leader>bo` | Закрыть остальные buffers |
| `<C-s>` | Сохранить файл |
| `<leader>fn` | Новый файл |
| `<esc>` | Сбросить поиск/highlight |
| `s` | Быстрый jump через Flash |
| `S` | Treesitter jump через Flash |

## LazyVim: файлы и поиск

Это главная замена GoLand Search Everywhere/Project View.

| Бинд | Действие |
| --- | --- |
| `<leader><space>` | Найти файл в проекте |
| `<leader>ff` | Find files |
| `<leader>fF` | Find files от текущей директории |
| `<leader>fg` | Git files |
| `<leader>fr` | Recent files |
| `<leader>/` | Grep по проекту |
| `<leader>sg` | Live grep |
| `<leader>sw` | Search word под курсором |
| `<leader>sb` | Search в текущем buffer |
| `<leader>e` | File explorer |
| `<leader>E` | File explorer от текущей директории |

Если бинды не совпадают из-за версии LazyVim, нажми `Space` и ищи через
which-key: группы `f` = files, `s` = search.

## LazyVim: LSP и Go-код

Это замена GoLand navigation/refactor/intentions.

| Бинд | GoLand-аналог | Действие |
| --- | --- | --- |
| `gd` | Go to Declaration/Definition | Перейти к definition |
| `gD` | Go to Declaration | Перейти к declaration |
| `gI` | Go to Implementation | Перейти к implementation |
| `gy` | Go to Type | Перейти к type definition |
| `gr` | Find Usages | References |
| `K` | Quick Documentation | Hover docs |
| `gK` | Parameter Info | Signature help |
| `<leader>cr` | Rename | Rename symbol |
| `<leader>ca` | Show Intention Actions | Code action |
| `<leader>cA` | Source actions | Source action, включая organize imports если доступно |
| `<leader>cf` | Reformat Code | Format file/range |
| `<leader>cd` | Show Error Description | Line diagnostics |
| `[d` / `]d` | Prev/Next problem | Prev/next diagnostic |
| `[e` / `]e` | Prev/Next error | Prev/next error |
| `[w` / `]w` | Prev/Next warning | Prev/next warning |
| `<leader>xx` | Problems tool window | Diagnostics list |
| `<leader>xX` | Current file problems | Buffer diagnostics |
| `<leader>cs` | Structure/Symbols | Symbols/outline via Trouble или Aerial |

Практический Go workflow:

1. Открыл проект: `nvim .`
2. Найти файл: `<leader><space>`.
3. Перейти к типу/методу: `gd`, `gI`, `gy`.
4. Найти usages: `gr`.
5. Переименовать: `<leader>cr`.
6. Любое “GoLand предложил бы починить”: `<leader>ca`.
7. Формат/импорты: `<leader>cf` или save, если включён format-on-save.

## LazyVim: тесты Go

Если включён `test.core` и Go extra:

| Бинд | Действие |
| --- | --- |
| `<leader>tr` | Run nearest test |
| `<leader>tR` | Run test file |
| `<leader>ta` | Run all tests |
| `<leader>ts` | Toggle test summary |
| `<leader>to` | Show test output |
| `<leader>tO` | Toggle test output panel |
| `<leader>td` | Debug nearest test |

Если бинда нет, проверь `:LazyExtras` и `:Mason`, затем открой which-key через
`<leader>t`.

## LazyVim: debug Go

Если включён `dap.core` и установлен `delve`:

| Бинд | Действие |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue/run |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into |
| `<leader>dO` | Step over |
| `<leader>do` | Step out |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Eval expression/selection |
| `<leader>dr` | Toggle REPL |
| `<leader>dl` | Run last |

GoLand mental model:

- Breakpoint gutter -> `<leader>db`
- Debug current test -> `<leader>td`
- Step over/into/out -> `<leader>dO`, `<leader>di`, `<leader>do`
- Watches/eval -> `<leader>de`
- Debug tool window -> `<leader>du`

## LazyVim: Git

| Бинд | Действие |
| --- | --- |
| `<leader>gg` | LazyGit/Git UI root dir, если extra установлен |
| `<leader>gG` | LazyGit/Git UI cwd, если extra установлен |
| `]h` / `[h` | Next/prev git hunk |
| `<leader>ghp` | Preview hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>gb` | Git blame line |

Если GoLand VCS panel привычнее, поставь `lazygit` и включи LazyVim git UI
extra. Тогда большая часть git workflow уходит в `<leader>gg`.

## LazyVim: терминал и задачи

| Бинд | Действие |
| --- | --- |
| `<C-/>` | Toggle terminal |
| `<C-_>` | Toggle terminal, если терминал/клавиатура так отдаёт shortcut |
| `<leader>ft` | Terminal root dir |
| `<leader>fT` | Terminal cwd |

Команды Go из терминала внутри Neovim:

```sh
go test ./...
go test ./... -race
go test ./... -run TestName
go test ./... -count=1
go test ./... -cover
go mod tidy
golangci-lint run ./...
```

## Минимальный переход с GoLand без боли

Первые 2-3 дня не пытайся выучить всё:

1. Используй `nvim .` только для чтения/малых правок.
2. Главные бинды: `<leader><space>`, `<leader>/`, `gd`, `gr`, `K`,
   `<leader>ca`, `<leader>cr`, `<leader>cf`, `<leader>tr`.
3. Для сложного debug первое время оставь GoLand.
4. Когда LSP/test/debug в LazyVim станут привычными, перенеси debug workflow на
   `<leader>d*`.
5. Если забыл бинды, жми `Space`: which-key покажет меню.

### Карта GoLand -> LazyVim

| GoLand | LazyVim |
| --- | --- |
| Search Everywhere | `<leader><space>`, `<leader>sg`, `<leader>fr` |
| Project tree | `<leader>e` |
| Recent files | `<leader>fr` |
| Find in Files | `<leader>/`, `<leader>sg` |
| Go to Definition | `gd` |
| Find Usages | `gr` |
| Implementation | `gI` |
| Type Declaration | `gy` |
| Rename | `<leader>cr` |
| Intentions/quick fix | `<leader>ca` |
| Reformat | `<leader>cf` |
| Problems | `<leader>xx`, `<leader>xX` |
| Run nearest test | `<leader>tr` |
| Debug nearest test | `<leader>td` |
| Breakpoint | `<leader>db` |
| Git UI | `<leader>gg` или внешний `lazygit` |
