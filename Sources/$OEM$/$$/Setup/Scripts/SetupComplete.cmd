@echo off
:: Copia o layout para o diretório do sistema
::copy %SystemDrive%\Layout\Layout.xml %SystemRoot%\LayoutModification.xml /Y

:: Define a política para aplicar esse layout ao iniciar
::reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "%SystemRoot%\LayoutModification.xml" /f

:: Adiciona as chaves ao registro do windows
regedit /s %~dp0copiar_mover_padroes.reg
regedit /s %~dp0restaura-visualizador-de-fotos.reg
regedit /s %~dp0TaskbarTweaks.reg
regedit /s %~dp0adiciona-cmd-powershell-menucontexto.reg
regedit /s %~dp0reiniciar-menu-contexto.reg

:: Remove executável do microsoft edge
::cmd /c %~dp0remover_edge.bat
powershell -ExecutionPolicy Bypass -File %~dp0FirstStartup.ps1

:: Executar script user customization.ps1
::powershell -ExecutionPolicy Bypass -File %~dp0User_customization.ps1

:: Copia o script de ajuste para C:
::copy %~dp0User_customization.ps1 %SystemRoot%
