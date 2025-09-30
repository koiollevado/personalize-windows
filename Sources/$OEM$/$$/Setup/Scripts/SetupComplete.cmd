@echo off

:: Adiciona as chaves ao registro do windows
regedit /s %~dp0copiar_mover_padroes.reg
regedit /s %~dp0restaura-visualizador-de-fotos.reg
regedit /s %~dp0TaskbarTweaks.reg
regedit /s %~dp0adiciona-cmd-powershell-menucontexto.reg
regedit /s %~dp0reiniciar-menu-contexto.reg
regedit /s %~dp0Ajustar-para-melhor-desempenho-otimizado.reg

:: Executar script menu-contexto-limpa-memoria.bat
cmd /c %~dp0menu-contexto-limpa-memoria.bat

:: Executa o script configura-layout.ps1
::powershell.exe -ExecutionPolicy Bypass -File %~dp0Configurar-Layout.ps1

:: Executa o script explorerplusplus.bat
cmd /c %~dp0explorerplusplus.bat


:: Executar script configura-layout.bat
cmd /c %~dp0configurar-layout.bat

:: Remove executável do microsoft edge
cmd /c %~dp0remover_edge.bat
