@echo off
setlocal

set "DESKTOP=%USERPROFILE%\Desktop"
set "VBS=%DESKTOP%\Gerenciador de Dispositivos.vbs"
set "LNK=%DESKTOP%\Gerenciador de Dispositivos.lnk"

echo Criando script VBS...

(
echo Set UAC = CreateObject("Shell.Application"^)
echo UAC.ShellExecute "mmc.exe", "devmgmt.msc", "", "runas", 1
) > "%VBS%"

echo Criando atalho...

powershell -NoProfile -ExecutionPolicy Bypass ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%LNK%'); ^
$Shortcut.TargetPath = '%VBS%'; ^
$Shortcut.IconLocation = 'C:\Windows\System32\devmgr.dll,0'; ^
$Shortcut.WorkingDirectory = '%DESKTOP%'; ^
$Shortcut.Save()"

echo.
echo ==========================================
echo Atalho criado com sucesso!
echo Local: %LNK%
echo ==========================================
pause 
