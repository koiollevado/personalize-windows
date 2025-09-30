@echo off
REM === Caminho onde estão as imagens ===
set "IMAGENS=C:\Wallpapers"

REM === Escolhe uma imagem aleatória do diretório ===
setlocal enabledelayedexpansion
set count=0
for %%I in ("%IMAGENS%\*.jpg") do (
    set /a count+=1
    set "file[!count!]=%%I"
)
if %count%==0 (
    echo Nenhuma imagem encontrada em %IMAGENS%
    exit /b
)

set /a rand=%RANDOM% %% %count% + 1
set "WALL=!file[%rand%]!"

REM === Define como papel de parede ===
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%WALL%" /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

echo Papel de parede alterado para: %WALL%
