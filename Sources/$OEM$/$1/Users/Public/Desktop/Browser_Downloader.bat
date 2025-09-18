@echo off
title Browser Downloader and Installer

:: Check for administrative privileges
powershell -Command "if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) { exit 1 }"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( 
    goto gotAdmin 
)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

set "downloadDir=%USERPROFILE%\Downloads"

:: Check if the system is 64-bit or 32-bit
set "arch=32"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "arch=64"

:menu
cls
echo.
echo Select a browser to download and install:
echo [1]  Microsoft Edge
echo [2]  Brave
echo [3]  Firefox
echo [4]  Google Chrome
echo [5]  Opera
echo [6]  DuckDuckGo 
echo [7]  Librewolf
echo [8]  Exit
echo.
set /p choice=Enter your choice (1-8): 

if "%choice%"=="1" goto edge
if "%choice%"=="2" goto brave
if "%choice%"=="3" goto firefox
if "%choice%"=="4" goto chrome
if "%choice%"=="5" goto opera
if "%choice%"=="6" goto duckduckgo
if "%choice%"=="7" goto librewolf
if "%choice%"=="8" exit

cls
echo Invalid choice. Please select a number between 1 and 8.
goto menu

:edge
set "browserName=Microsoft Edge"
set "fileName=MicrosoftEdgeSetup.exe"
set "url=https://go.microsoft.com/fwlink/?linkid=2109047&Channel=Stable&language=en&consent=1"
set "silentArgs=/silent /install"
goto download

:brave
set "browserName=Brave"
if "%arch%"=="64" (
    set "url=https://github.com/brave/brave-browser/releases/download/v1.75.181/BraveBrowserStandaloneSetup.exe"
    set "fileName=BraveBrowserSetup64.exe"
) else (
    set "url=https://github.com/brave/brave-browser/releases/download/v1.75.181/BraveBrowserStandaloneSetup32.exe"
    set "fileName=BraveBrowserSetup32.exe"
)
set "silentArgs=/silent /install"
goto download

:firefox
set "browserName=Firefox"
set "fileName=FirefoxSetup.exe"
set "url=https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US&arch=%arch%"
set "silentArgs=/silent /install"
goto download

:chrome
set "browserName=Google Chrome"
if "%arch%"=="64" (
    set "url=https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"
    set "fileName=GoogleChromeStandaloneEnterprise64.msi"
) else (
    set "url=https://dl.google.com/chrome/install/googlechromestandaloneenterprise.msi"
    set "fileName=GoogleChromeStandaloneEnterprise.msi"
)
set "silentArgs=/quiet"
goto download

:opera
set "browserName=Opera"
if "%arch%"=="64" (
    set "url=https://download3.operacdn.com/pub/opera/desktop/76.0.4017.177/win/Opera_76.0.4017.177_Setup_x64.exe"
    set "fileName=OperaSetup_x64.exe"
) else (
    set "url=https://download3.operacdn.com/pub/opera/desktop/76.0.4017.177/win/Opera_76.0.4017.177_Setup.exe"
    set "fileName=OperaSetup.exe"
)
set "silentArgs=/silent /install"
goto download

:duckduckgo
set "browserName=DuckDuckGo"
set "fileName=DuckDuckGo.msixbundle"
set "url=https://staticcdn.duckduckgo.com/windows-desktop-browser/help-pages/DuckDuckGo.msixbundle"

if "%arch%"=="64" (
    set "frameworkUrl=https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    set "frameworkFileName=Microsoft.VCLibs.x64.14.00.Desktop.appx"
) else (
    set "frameworkUrl=https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx"
    set "frameworkFileName=Microsoft.VCLibs.x86.14.00.Desktop.appx"
)

cls
echo Downloading %browserName%...
curl -L -o "%downloadDir%\%fileName%" "%url%"
if %errorlevel% neq 0 (
    echo Error downloading %browserName%. Exiting.
    exit /B 1
)
cls
echo Downloading required framework...
curl -L -o "%downloadDir%\%frameworkFileName%" "%frameworkUrl%"
if %errorlevel% neq 0 (
    echo Error downloading framework. Exiting.
    exit /B 1
)
cls
echo Installing required framework...
powershell -Command "Add-AppxPackage -Path '%downloadDir%\%frameworkFileName%'"
if %errorlevel% neq 0 (
    echo Error installing framework. Exiting.
    exit /B 1
)
cls
echo Installing %browserName%...
powershell -Command "Add-AppxPackage -Path '%downloadDir%\%fileName%'"
if %errorlevel% neq 0 (
    echo Error installing %browserName%. Exiting.
    exit /B 1
)
cls
echo %browserName% has been installed.
goto menu

:librewolf
set "browserName=Librewolf"
set "fileName=LibrewolfSetup.exe"
set "url=https://gitlab.com/api/v4/projects/44042130/packages/generic/librewolf/135.0.1-1/librewolf-135.0.1-1-windows-x86_64-setup.exe"
set "silentArgs=/S"
goto download

:download
cls
echo Downloading %browserName%...
curl -L -o "%downloadDir%\%fileName%" "%url%"
if %errorlevel% neq 0 (
    echo Error downloading %browserName%. Exiting.
    exit /B 1
)
cls
echo Installing %browserName%...
start /wait "" "%downloadDir%\%fileName%" %silentArgs%
if %errorlevel% neq 0 (
    echo Error installing %browserName%. Exiting.
    exit /B 1
)

:: Check if the browser is installed
set "checkCommand="
if "%browserName%"=="Microsoft Edge" set "checkCommand=msedge"
if "%browserName%"=="Brave" set "checkCommand=brave"
if "%browserName%"=="Firefox" set "checkCommand=firefox"
if "%browserName%"=="Google Chrome" set "checkCommand=chrome"
if "%browserName%"=="Opera" set "checkCommand=opera"
if "%browserName%"=="DuckDuckGo" set "checkCommand=duckduckgo"
if "%browserName%"=="Librewolf" set "checkCommand=librewolf"

if not "%checkCommand%"=="" (
    powershell -Command "Get-Command '%checkCommand%' -ErrorAction SilentlyContinue" >nul 2>&1
    if %errorlevel% neq 0 (
        echo %browserName% installation failed. Exiting.
        exit /B 1
    )
    echo %browserName% has been installed.
) else (
    echo Could not verify the installation of %browserName%.
)
goto menu

:end
echo Done.
pause;