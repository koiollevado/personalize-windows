@echo off
setlocal

set "ATALHO=%USERPROFILE%\Desktop\Desligar Reiniciar Windows 2.lnk"

powershell -NoProfile -Command ^
"$Shell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $Shell.CreateShortcut('%ATALHO%'); ^
$Shortcut.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'; ^
$Shortcut.Arguments = '-NoProfile -WindowStyle Hidden -Command ""$ObjShell = New-Object -ComObject Shell.Application; $ObjShell.ShutdownWindows()""'; ^
$Shortcut.WindowStyle = 7; ^
$Shortcut.IconLocation = 'C:\Users\Asus\Downloads\Botao-tela-desligamento\power-button.ico'; ^
$Shortcut.Save()"

echo.
echo Atalho criado com sucesso.
pause 
