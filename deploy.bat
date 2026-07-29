@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================================
rem  deploy.bat - prepare install\ folder and build NSIS setup.exe
rem
rem  Prerequisites:
rem    - Project already built (build\release\qmodbus.exe)
rem    - Qt 5.15.2 MinGW and MinGW 8.1 installed under C:\Qt
rem    - NSIS installed (makensis in PATH or standard Program Files path)
rem
rem  Usage (from cmd):
rem    deploy.bat
rem    deploy.bat C:\Qt\5.15.2\mingw81_64 C:\Qt\Tools\mingw810_64
rem ============================================================================

cd /d "%~dp0"

set "QT_DIR=%~1"
set "MINGW_DIR=%~2"

if "%QT_DIR%"=="" set "QT_DIR=C:\Qt\5.15.2\mingw81_64"
if "%MINGW_DIR%"=="" set "MINGW_DIR=C:\Qt\Tools\mingw810_64"

set "QT_BIN=%QT_DIR%\bin"
set "MINGW_BIN=%MINGW_DIR%\bin"
set "RELEASE_DIR=%~dp0build\release"
set "INSTALL_DIR=%~dp0install"

echo === QModBus deploy ===
echo QT_DIR=%QT_DIR%
echo MINGW_DIR=%MINGW_DIR%
echo RELEASE_DIR=%RELEASE_DIR%
echo INSTALL_DIR=%INSTALL_DIR%
echo.

if not exist "%RELEASE_DIR%\qmodbus.exe" (
    echo ERROR: "%RELEASE_DIR%\qmodbus.exe" not found.
    echo Build the project first:
    echo   mkdir build ^& cd build
    echo   "%QT_BIN%\qmake.exe" ..
    echo   mingw32-make -j4
    exit /b 1
)

if not exist "%QT_BIN%\Qt5Core.dll" (
    echo ERROR: Qt DLLs not found in "%QT_BIN%"
    exit /b 1
)

echo [1/3] Preparing install folder...
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)
if exist "%INSTALL_DIR%" (
    echo ERROR: cannot remove "%INSTALL_DIR%" - close QModBus if it is running.
    exit /b 1
)
mkdir "%INSTALL_DIR%"
if errorlevel 1 (
    echo ERROR: cannot create "%INSTALL_DIR%"
    exit /b 1
)
mkdir "%INSTALL_DIR%\platforms"
mkdir "%INSTALL_DIR%\styles"
mkdir "%INSTALL_DIR%\imageformats"
mkdir "%INSTALL_DIR%\iconengines"

copy /y "%RELEASE_DIR%\qmodbus.exe" "%INSTALL_DIR%\qmodbus.exe" >nul
if errorlevel 1 (
    echo ERROR: failed to copy qmodbus.exe
    echo Make sure the application is not running.
    exit /b 1
)

copy /y "%QT_BIN%\Qt5Core.dll"    "%INSTALL_DIR%\" >nul
copy /y "%QT_BIN%\Qt5Gui.dll"     "%INSTALL_DIR%\" >nul
copy /y "%QT_BIN%\Qt5Widgets.dll" "%INSTALL_DIR%\" >nul
if exist "%QT_BIN%\Qt5Svg.dll" copy /y "%QT_BIN%\Qt5Svg.dll" "%INSTALL_DIR%\" >nul

if exist "%QT_BIN%\libEGL.dll"         copy /y "%QT_BIN%\libEGL.dll"         "%INSTALL_DIR%\" >nul
if exist "%QT_BIN%\libGLESv2.dll"      copy /y "%QT_BIN%\libGLESv2.dll"      "%INSTALL_DIR%\" >nul
if exist "%QT_BIN%\D3Dcompiler_47.dll" copy /y "%QT_BIN%\D3Dcompiler_47.dll" "%INSTALL_DIR%\" >nul
if exist "%QT_BIN%\opengl32sw.dll"     copy /y "%QT_BIN%\opengl32sw.dll"     "%INSTALL_DIR%\" >nul

copy /y "%MINGW_BIN%\libgcc_s_seh-1.dll"   "%INSTALL_DIR%\" >nul
copy /y "%MINGW_BIN%\libstdc++-6.dll"      "%INSTALL_DIR%\" >nul
copy /y "%MINGW_BIN%\libwinpthread-1.dll"  "%INSTALL_DIR%\" >nul

copy /y "%QT_DIR%\plugins\platforms\qwindows.dll" "%INSTALL_DIR%\platforms\" >nul
if exist "%QT_DIR%\plugins\styles\*.dll"       copy /y "%QT_DIR%\plugins\styles\*.dll"       "%INSTALL_DIR%\styles\" >nul
if exist "%QT_DIR%\plugins\imageformats\*.dll" copy /y "%QT_DIR%\plugins\imageformats\*.dll" "%INSTALL_DIR%\imageformats\" >nul
if exist "%QT_DIR%\plugins\iconengines\*.dll"  copy /y "%QT_DIR%\plugins\iconengines\*.dll"  "%INSTALL_DIR%\iconengines\" >nul

echo [2/3] Looking for makensis...
if not exist "%~dp0version.nsh" (
    echo ERROR: version.nsh not found.
    echo Run qmake first so VERSION from qmodbus.pro is exported:
    echo   cd build ^& qmake ..
    exit /b 1
)

set "MAKENSIS="
where makensis >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%i in ('where makensis') do (
        set "MAKENSIS=%%i"
        goto :nsis_found
    )
)

if exist "%ProgramFiles%\NSIS\makensis.exe" (
    set "MAKENSIS=%ProgramFiles%\NSIS\makensis.exe"
    goto :nsis_found
)

if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
    set "MAKENSIS=%ProgramFiles(x86)%\NSIS\makensis.exe"
    goto :nsis_found
)

if exist "%~dp0tools\nsis-3.10\makensis.exe" (
    set "MAKENSIS=%~dp0tools\nsis-3.10\makensis.exe"
    goto :nsis_found
)

for /d %%d in ("%~dp0tools\nsis-*") do (
    if exist "%%d\makensis.exe" (
        set "MAKENSIS=%%d\makensis.exe"
        goto :nsis_found
    )
)

echo ERROR: NSIS not found. Install it, then re-run this script:
echo   choco install nsis -y
echo   or download from https://nsis.sourceforge.io
echo   or unpack NSIS into tools\nsis-3.10\
exit /b 1

:nsis_found
echo Using: %MAKENSIS%

echo [3/3] Building installer...
"%MAKENSIS%" "%~dp0qmodbus.nsi"
if errorlevel 1 (
    echo ERROR: makensis failed
    exit /b 1
)

echo.
echo Done.
dir /b "%~dp0QModBus-*-setup.exe"
echo.
echo Installer is ready in the project root.
endlocal
