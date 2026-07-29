# QModBus

QModBus — свободное Qt-приложение Modbus-мастера. Графический интерфейс позволяет обмениваться данными со slave-устройствами по последовательному порту (RTU/ASCII) и по TCP, а также просматривать трафик шины.

## Требования

* Qt 5 (рекомендуется 5.15.x)
* MinGW / GCC
* Для инсталлятора Windows: [NSIS](https://nsis.sourceforge.io)

## Версионирование

Версия приложения задаётся **в одном месте** — в файле `qmodbus.pro`:

```pro
VERSION = 0.3.0
```

При запуске `qmake` из этой строки автоматически генерируются:

| Файл | Назначение |
|------|------------|
| `app_version.h` | ресурсы Windows (`qmodbus.rc`), диалог About |
| `version.nsh` | NSIS-инсталлятор (`qmodbus.nsi`) |

После смены версии нужно заново выполнить `qmake` и пересобрать проект, чтобы обновились заголовок, сведения о файле exe и имя setup-файла.

## Сборка (Windows, cmd)

```bat
set PATH=C:\Qt\5.15.2\mingw81_64\bin;C:\Qt\Tools\mingw810_64\bin;%PATH%
mkdir build
cd build
qmake ..
mingw32-make -j4
```

Готовый исполняемый файл: `build\release\qmodbus.exe`.

Для запуска напрямую из `release` рядом с exe должны лежать DLL Qt/MinGW и плагин `platforms\qwindows.dll` (их копирует `deploy.bat`).

## Создание инсталлятора

Инсталлятор собирается скриптом `deploy.bat` (обычный **cmd**, не PowerShell). Скрипт:

1. копирует `qmodbus.exe` и нужные DLL в каталог `install\`;
2. берёт версию из `version.nsh` (создаётся при `qmake`);
3. запускает NSIS по скрипту `qmodbus.nsi`;
4. формирует файл `QModBus-<версия>-setup.exe` в корне проекта.

### Перед сборкой setup

1. Соберите release-сборку (см. выше).
2. Закройте запущенный QModBus, если он открыт.
3. Убедитесь, что установлен NSIS (`makensis` в PATH), либо распакован в `tools\nsis-3.10\`.

### Команда

Из корня репозитория в **cmd**:

```bat
deploy.bat
```

Если Qt/MinGW установлены не в стандартные пути:

```bat
deploy.bat C:\путь\к\Qt\mingw81_64 C:\путь\к\Tools\mingw810_64
```

Пример результата: `QModBus-0.3.0-setup.exe`.

### Как обновить версию и пересобрать инсталлятор

```bat
rem 1. Изменить VERSION в qmodbus.pro
rem 2. Пересобрать
cd build
qmake ..
mingw32-make -j4
cd ..

rem 3. Собрать инсталлятор
deploy.bat
```

## Полезные файлы

* `qmodbus.pro` — версия и настройки сборки
* `qmodbus.rc` — сведения о версии Windows exe (через `app_version.h`)
* `qmodbus.nsi` — скрипт NSIS
* `deploy.bat` — подготовка `install\` и сборка setup.exe
* `INSTALL` — общие инструкции по сборке
* [README](README) — оригинальное описание проекта, авторы и текст лицензии
* [AUTHORS](AUTHORS) — список авторов
* [COPYING](COPYING) — полный текст GNU GPL v2

## Авторы

* Copyright (c) 2009–2018 Tobias Junghans, EDC Electronic Design Chemnitz GmbH  
  — [http://www.ed-chemnitz.de](http://www.ed-chemnitz.de)
* Copyright (c) 2013 Karl-Heinz Reichel, ing-büro reichel-langer  
  — [http://www.techdrivers.de](http://www.techdrivers.de)

Сайт проекта: [http://qmodbus.sourceforge.net](http://qmodbus.sourceforge.net)

Подробнее об авторах и контактах — в файлах [AUTHORS](AUTHORS) и [README](README).

## Лицензия

Программа распространяется на условиях [GNU General Public License версии 2](COPYING) (или любой более поздней версии) — см. также формулировку в [README](README).
