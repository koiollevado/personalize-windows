@echo off
:: ===============================
:: Script: configurar-layout.bat
:: Objetivo: Ajustar Start, Taskbar e Bandeja
:: ===============================

:: Caminho da pasta padrão do usuário Default
set "ShellPath=C:\Users\Default\AppData\Local\Microsoft\Windows\Shell"

if not exist "%ShellPath%" (
    mkdir "%ShellPath%"
)

:: -------------------------------
:: LayoutModification.json (Start vazio)
:: -------------------------------
(
echo {
echo   "layoutModification": {
echo     "version": 1,
echo     "defaultLayoutOverride": {
echo       "startMenuLayout": {
echo         "groups": []
echo       }
echo     }
echo   }
echo }
) > "%ShellPath%\LayoutModification.json"

:: -------------------------------
:: LayoutModification.xml (Start vazio + Taskbar personalizada)
:: -------------------------------
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<LayoutModificationTemplate
echo     xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
echo     xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
echo     xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
echo     xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
echo     Version="1"^>
echo
echo   ^<!-- Layout do Menu Iniciar --^>
echo   ^<LayoutOptions StartTileGroupCellWidth="6" /^>
echo
echo   ^<DefaultLayoutOverride^>
echo     ^<StartLayoutCollection^>
echo       ^<defaultlayout:StartLayout GroupCellWidth="6"^>
echo         ^<!-- Nenhum bloco fixado --^>
echo       ^</defaultlayout:StartLayout^>
echo     ^</StartLayoutCollection^>
echo   ^</DefaultLayoutOverride^>
echo
echo   ^<!-- Layout da Barra de Tarefas --^>
echo   ^<CustomTaskbarLayoutCollection PinListPlacement="Replace"^>
echo     ^<defaultlayout:TaskbarLayout^>
echo       ^<taskbar:TaskbarPinList^>
echo
echo         ^<!-- Explorador de Arquivos --^>
echo         ^<taskbar:DesktopApp DesktopApplicationLinkPath="%%APPDATA%%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" /^>
echo
echo         ^<!-- Bloco de Notas --^>
echo         ^<taskbar:DesktopApp DesktopApplicationLinkPath="%%APPDATA%%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk" /^>
echo
echo       ^</taskbar:TaskbarPinList^>
echo     ^</defaultlayout:TaskbarLayout^>
echo   ^</CustomTaskbarLayoutCollection^>
echo ^</LayoutModificationTemplate^>
) > "%ShellPath%\LayoutModification.xml"

:: -------------------------------
:: Ajuste da Bandeja (System Tray)
:: -------------------------------
:: 0 = mostrar, 1 = ocultar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 0 /f

:: Limpar cache de ícones da bandeja
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TrayNotify" /v IconStreams /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TrayNotify" /v PastIconsStream /f >nul 2>&1

:: -------------------------------
:: Registro: bloquear sugestões da Microsoft no Start
:: -------------------------------
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f

::echo.
::echo ===== Configuração aplicada com sucesso =====
::pause
