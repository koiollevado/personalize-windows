@echo off
REM -------------------------------------------------------
REM Exemplo: criar atalho para um executável em Program Files
REM -------------------------------------------------------

REM Ajuste o nome da aplicação e o caminho do executável conforme necessário
set "APP_NAME=Explorer++"
set "TARGET=%ProgramFiles%\ExplorerPlusPlus\explorer++.exe"
set "FILEX64=%ProgramFiles%\ExplorerPlusPlus\explorer++-x64.exe"
set "FILEX86=%ProgramFiles%\ExplorerPlusPlus\explorer++-x86.exe"

REM --------------------------------------------------------

:: === Verifica arquitetura do sistema ===
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    ren "%FILEX64%" "explorer++.exe"
    del "%FILEX86%" 
    exit /b
) else (
    ren "%FILEX86%" "explorer++.exe"
    del "%FILEX64%" 
    exit /b
)

REM --------------------------------------------------------

REM caminhos de atalho do usuário atual
set "DESKTOP=%UserProfile%\Desktop\%APP_NAME%.lnk"
set "STARTMENU=%AppData%\Microsoft\Windows\Start Menu\Programs\%APP_NAME%.lnk"

REM verifica se o executável existe
if not exist "%TARGET%" (
    echo Erro: executavel nao encontrado em "%TARGET%"
    echo Verifique o caminho e tente novamente.
    ::pause
    exit /b 1
)

REM cria os atalhos usando PowerShell + WScript.Shell
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $s = $ws.CreateShortcut('%DESKTOP%'); ^
   $s.TargetPath = '%TARGET%'; ^
   $s.WorkingDirectory = '%~dp0'; ^
   $s.IconLocation = '%TARGET%'; ^
   $s.Save(); ^
   $s = $ws.CreateShortcut('%STARTMENU%'); ^
   $s.TargetPath = '%TARGET%'; ^
   $s.WorkingDirectory = '%~dp0'; ^
   $s.IconLocation = '%TARGET%'; ^
   $s.Save()"

echo Atalhos criados:
echo  - %DESKTOP%
echo  - %STARTMENU%
::pause
exit /b 0
