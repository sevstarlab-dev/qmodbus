TARGET = qmodbus
TEMPLATE = app

# Single source of truth for the application version.
# Also updates app_version.h and version.nsh (used by qmodbus.rc, About, NSIS).
VERSION = 0.3.0

VER_MAJ = $$section(VERSION, ., 0, 0)
VER_MIN = $$section(VERSION, ., 1, 1)
VER_PAT = $$section(VERSION, ., 2, 2)

# Generate headers/scripts consumed by .rc, C++ and the NSIS installer
APP_VERSION_H_CONTENT = \
    "$${LITERAL_HASH}ifndef APP_VERSION_H" \
    "$${LITERAL_HASH}define APP_VERSION_H" \
    "" \
    "$${LITERAL_HASH}define APP_VERSION_MAJOR $$VER_MAJ" \
    "$${LITERAL_HASH}define APP_VERSION_MINOR $$VER_MIN" \
    "$${LITERAL_HASH}define APP_VERSION_PATCH $$VER_PAT" \
    "$${LITERAL_HASH}define APP_VERSION_BUILD 0" \
    "$${LITERAL_HASH}define APP_VERSION_STR \"$$VERSION\"" \
    "" \
    "$${LITERAL_HASH}endif /* APP_VERSION_H */"
write_file($$PWD/app_version.h, APP_VERSION_H_CONTENT)

VERSION_NSH_CONTENT = "!define VERSION \"$$VERSION\""
write_file($$PWD/version.nsh, VERSION_NSH_CONTENT)

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

QT += gui widgets

SOURCES += src/main.cpp \
    src/mainwindow.cpp \
    src/BatchProcessor.cpp \
    3rdparty/qextserialport/qextserialport.cpp	\
    3rdparty/libmodbus/src/modbus.c \
    3rdparty/libmodbus/src/modbus-data.c \
    3rdparty/libmodbus/src/modbus-rtu.c \
    3rdparty/libmodbus/src/modbus-tcp.c \
    3rdparty/libmodbus/src/modbus-ascii.c \
    src/asciisettingswidget.cpp \
    src/rtusettingswidget.cpp \
    src/serialsettingswidget.cpp \
    src/tcpipsettingswidget.cpp \
    src/ipaddressctrl.cpp \
    src/iplineedit.cpp

HEADERS += src/mainwindow.h \
    src/BatchProcessor.h \
    3rdparty/qextserialport/qextserialport.h \
    3rdparty/qextserialport/qextserialenumerator.h \
    3rdparty/libmodbus/src/modbus.h \
    src/serialsettingswidget.h \
    src/imodbus.h \
    src/tcpipsettingswidget.h \
    src/ipaddressctrl.h \
    src/iplineedit.h \
    app_version.h

INCLUDEPATH += 3rdparty/libmodbus \
               3rdparty/libmodbus/src \
               3rdparty/qextserialport \
               src \
               $$PWD
unix {
    SOURCES += 3rdparty/qextserialport/posix_qextserialport.cpp	\
           3rdparty/qextserialport/qextserialenumerator_unix.cpp
    DEFINES += _TTY_POSIX_
}

win32 {
    SOURCES += 3rdparty/qextserialport/win_qextserialport.cpp \
           3rdparty/qextserialport/qextserialenumerator_win.cpp
    DEFINES += _TTY_WIN_  WINVER=0x0501
    LIBS += -lsetupapi -lws2_32
    # so windres finds app_version.h next to qmodbus.rc
    RC_INCLUDEPATH += $$PWD
}

FORMS += forms/mainwindow.ui \
    forms/about.ui	\
    forms/BatchProcessor.ui \
    forms/serialsettingswidget.ui \
    forms/tcpipsettingswidget.ui \
    forms/ipaddressctrl.ui

RESOURCES += data/qmodbus.qrc

RC_FILE += qmodbus.rc

include(deployment.pri)
