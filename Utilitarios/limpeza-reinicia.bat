::=============================================================================
:: Script de limpeza de temporários + caches de browsers
:: Versão estável (sem blocos aninhados problemáticos)
:: Detecta: Chrome, Edge, Firefox, Opera, Vivaldi, Brave, Chromium
:: Limpa: Temp, Prefetch, caches seguros do Windows
::----------------------------------------------------------------------------- 
:: Script atualizado em 27/09/2026.
::=============================================================================


@echo off
setlocal
title Limpeza de Temporarios e Caches de Browsers
color 0A

cls
echo.
echo  ========================================
echo   Detectando browsers instalados...
echo  ========================================
echo.

set "CHROME=0"
set "EDGE=0"
set "FIREFOX=0"
set "OPERA=0"
set "VIVALDI=0"
set "BRAVE=0"
set "CHROMIUM=0"

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=1"
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=1"

if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "EDGE=1"
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "EDGE=1"

if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" set "FIREFOX=1"
if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" set "FIREFOX=1"

if exist "%ProgramFiles%\Opera\opera.exe" set "OPERA=1"
if exist "%ProgramFiles(x86)%\Opera\opera.exe" set "OPERA=1"
if exist "%LOCALAPPDATA%\Programs\Opera\opera.exe" set "OPERA=1"

if exist "%ProgramFiles%\Vivaldi\Application\vivaldi.exe" set "VIVALDI=1"
if exist "%ProgramFiles(x86)%\Vivaldi\Application\vivaldi.exe" set "VIVALDI=1"
if exist "%LOCALAPPDATA%\Vivaldi\Application\vivaldi.exe" set "VIVALDI=1"

if exist "%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=1"
if exist "%ProgramFiles(x86)%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=1"
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" set "BRAVE=1"

if exist "%ProgramFiles%\Chromium\Application\chrome.exe" set "CHROMIUM=1"
if exist "%ProgramFiles(x86)%\Chromium\Application\chrome.exe" set "CHROMIUM=1"
if exist "%LOCALAPPDATA%\Chromium\Application\chrome.exe" set "CHROMIUM=1"

if "%CHROME%"=="1"    (echo  [OK] Google Chrome) else (echo  [  ] Google Chrome)
if "%EDGE%"=="1"      (echo  [OK] Microsoft Edge) else (echo  [  ] Microsoft Edge)
if "%FIREFOX%"=="1"   (echo  [OK] Mozilla Firefox) else (echo  [  ] Mozilla Firefox)
if "%OPERA%"=="1"     (echo  [OK] Opera) else (echo  [  ] Opera)
if "%VIVALDI%"=="1"   (echo  [OK] Vivaldi) else (echo  [  ] Vivaldi)
if "%BRAVE%"=="1"     (echo  [OK] Brave) else (echo  [  ] Brave)
if "%CHROMIUM%"=="1"  (echo  [OK] Chromium) else (echo  [  ] Chromium)

echo.
echo  Iniciando limpeza em todos os perfis de usuario...
timeout /t 2 >nul

:: Vai para a pasta Users
cd /d "%SystemDrive%\Users"

for /f "delims=" %%u in ('dir /b /ad') do (

    echo.
    echo  ----------------------------------------
    echo   Limpando perfil: %%u
    echo  ----------------------------------------

    :: ===== TEMP DO USUÁRIO (%TEMP% / AppData\Local\Temp) =====
    if exist "%%u\Local Settings\Temp" (
        del /f /s /q "%%u\Local Settings\Temp\*.*" 2>nul
        for /d %%d in ("%%u\Local Settings\Temp\*") do rd /s /q "%%d" 2>nul
    )
    if exist "%%u\AppData\Local\Temp" (
        del /f /s /q "%%u\AppData\Local\Temp\*.*" 2>nul
        for /d %%d in ("%%u\AppData\Local\Temp\*") do rd /s /q "%%d" 2>nul
    )

    :: Arquivos legados e outros temporários
    if exist "%%u\Local Settings\Temporary Internet Files" rd /s /q "%%u\Local Settings\Temporary Internet Files" 2>nul
    if exist "%%u\AppData\Local\Microsoft\Windows\Temporary Internet Files" rd /s /q "%%u\AppData\Local\Microsoft\Windows\Temporary Internet Files" 2>nul
    if exist "%%u\AppData\Local\Microsoft\Windows\WER\ReportArchive" rd /s /q "%%u\AppData\Local\Microsoft\Windows\WER\ReportArchive" 2>nul
    if exist "%%u\cookies" rd /s /q "%%u\cookies" 2>nul

    :: Cache de miniaturas (Thumbnails)
    if exist "%%u\AppData\Local\Microsoft\Windows\Explorer" (
        del /f /q "%%u\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
    )

    :: Arquivos recentes
    if exist "%%u\AppData\Roaming\Microsoft\Windows\Recent" (
        del /f /q "%%u\AppData\Roaming\Microsoft\Windows\Recent\*.*" 2>nul
    )

    :: ===== GOOGLE CHROME =====
    if "%CHROME%"=="1" (
        if exist "%%u\AppData\Local\Google\Chrome\User Data" (
            echo    - Chrome
            for /d %%p in ("%%u\AppData\Local\Google\Chrome\User Data\*") do (
                if exist "%%p\Cache" rd /s /q "%%p\Cache" 2>nul
                if exist "%%p\Code Cache" rd /s /q "%%p\Code Cache" 2>nul
                if exist "%%p\GPUCache" rd /s /q "%%p\GPUCache" 2>nul
                if exist "%%p\Service Worker\CacheStorage" rd /s /q "%%p\Service Worker\CacheStorage" 2>nul
            )
        )
    )

    :: ===== MICROSOFT EDGE =====
    if "%EDGE%"=="1" (
        if exist "%%u\AppData\Local\Microsoft\Edge\User Data" (
            echo    - Edge
            for /d %%p in ("%%u\AppData\Local\Microsoft\Edge\User Data\*") do (
                if exist "%%p\Cache" rd /s /q "%%p\Cache" 2>nul
                if exist "%%p\Code Cache" rd /s /q "%%p\Code Cache" 2>nul
                if exist "%%p\GPUCache" rd /s /q "%%p\GPUCache" 2>nul
                if exist "%%p\Service Worker\CacheStorage" rd /s /q "%%p\Service Worker\CacheStorage" 2>nul
            )
        )
        if exist "%%u\AppData\Local\Microsoft\Windows\INetCache" rd /s /q "%%u\AppData\Local\Microsoft\Windows\INetCache" 2>nul
        if exist "%%u\AppData\Local\Microsoft\Windows\INetCookies" rd /s /q "%%u\AppData\Local\Microsoft\Windows\INetCookies" 2>nul
    )

    :: ===== FIREFOX =====
    if "%FIREFOX%"=="1" (
        if exist "%%u\AppData\Local\Mozilla\Firefox\Profiles" (
            echo    - Firefox
            for /d %%p in ("%%u\AppData\Local\Mozilla\Firefox\Profiles\*") do (
                if exist "%%p\cache2" rd /s /q "%%p\cache2" 2>nul
                if exist "%%p\startupCache" rd /s /q "%%p\startupCache" 2>nul
                if exist "%%p\OfflineCache" rd /s /q "%%p\OfflineCache" 2>nul
            )
        )
    )

    :: ===== OPERA =====
    if "%OPERA%"=="1" (
        if exist "%%u\AppData\Local\Opera Software" (
            echo    - Opera
            for /d %%o in ("%%u\AppData\Local\Opera Software\*") do (
                if exist "%%o\Cache" rd /s /q "%%o\Cache" 2>nul
                if exist "%%o\Code Cache" rd /s /q "%%o\Code Cache" 2>nul
                if exist "%%o\GPUCache" rd /s /q "%%o\GPUCache" 2>nul
            )
        )
    )

    :: ===== VIVALDI =====
    if "%VIVALDI%"=="1" (
        if exist "%%u\AppData\Local\Vivaldi\User Data" (
            echo    - Vivaldi
            for /d %%p in ("%%u\AppData\Local\Vivaldi\User Data\*") do (
                if exist "%%p\Cache" rd /s /q "%%p\Cache" 2>nul
                if exist "%%p\Code Cache" rd /s /q "%%p\Code Cache" 2>nul
                if exist "%%p\GPUCache" rd /s /q "%%p\GPUCache" 2>nul
            )
        )
    )

    :: ===== BRAVE =====
    if "%BRAVE%"=="1" (
        if exist "%%u\AppData\Local\BraveSoftware\Brave-Browser\User Data" (
            echo    - Brave
            for /d %%p in ("%%u\AppData\Local\BraveSoftware\Brave-Browser\User Data\*") do (
                if exist "%%p\Cache" rd /s /q "%%p\Cache" 2>nul
                if exist "%%p\Code Cache" rd /s /q "%%p\Code Cache" 2>nul
                if exist "%%p\GPUCache" rd /s /q "%%p\GPUCache" 2>nul
            )
        )
    )

    :: ===== CHROMIUM =====
    if "%CHROMIUM%"=="1" (
        if exist "%%u\AppData\Local\Chromium\User Data" (
            echo    - Chromium
            for /d %%p in ("%%u\AppData\Local\Chromium\User Data\*") do (
                if exist "%%p\Cache" rd /s /q "%%p\Cache" 2>nul
                if exist "%%p\Code Cache" rd /s /q "%%p\Code Cache" 2>nul
                if exist "%%p\GPUCache" rd /s /q "%%p\GPUCache" 2>nul
                if exist "%%p\Service Worker\CacheStorage" rd /s /q "%%p\Service Worker\CacheStorage" 2>nul
            )
        )
    )
)

:: ============================================================
:: LIMPEZA DO SISTEMA
:: ============================================================

echo.
echo  ----------------------------------------
echo   Limpando pastas do sistema...
echo  ----------------------------------------

:: Temp do sistema
echo  - Temp do sistema
if exist "%SystemRoot%\Temp" (
    del /f /s /q "%SystemRoot%\Temp\*.*" 2>nul
    for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" 2>nul
)
if exist "%SystemDrive%\Temp" (
    del /f /s /q "%SystemDrive%\Temp\*.*" 2>nul
    for /d %%d in ("%SystemDrive%\Temp\*") do rd /s /q "%%d" 2>nul
)

:: Prefetch
echo  - Prefetch
if exist "%SystemRoot%\Prefetch" (
    del /f /s /q "%SystemRoot%\Prefetch\*.*" 2>nul
    for /d %%d in ("%SystemRoot%\Prefetch\*") do rd /s /q "%%d" 2>nul
)

:: Cache de atualização do Windows (seguro)
echo  - Cache de atualizacao do Windows
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    rd /s /q "%SystemRoot%\SoftwareDistribution\Download" 2>nul
    mkdir "%SystemRoot%\SoftwareDistribution\Download" 2>nul
)

:: Delivery Optimization (cache de entrega)
echo  - Delivery Optimization
if exist "%SystemRoot%\SoftwareDistribution\DeliveryOptimization" (
    rd /s /q "%SystemRoot%\SoftwareDistribution\DeliveryOptimization" 2>nul
)

:: Mini-dumps de erro
echo  - Mini-dumps
if exist "%SystemRoot%\Minidump" (
    del /f /q "%SystemRoot%\Minidump\*.*" 2>nul
)
if exist "%SystemRoot%\MEMORY.DMP" del /f /q "%SystemRoot%\MEMORY.DMP" 2>nul

:: Lixeira
echo  - Lixeira
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo.
echo  ========================================
echo   Limpeza concluida!
echo  ========================================
echo.
pause
exit
