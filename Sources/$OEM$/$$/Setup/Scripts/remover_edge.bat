@echo off
echo Removendo atalhos do Microsoft Edge...

:: Remove atalhos da área de trabalho (usuário atual e público)
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q
del "C:\Users\Public\Desktop\Microsoft Edge.lnk" /f /q

:: Remove atalhos do Menu Iniciar (usuário atual e todos usuários)
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q
del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q

:: Remove atalhos fixados na barra de tarefas
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q

:: Remove atalhos fixados no menu iniciar
::del "%LocalAppData%\Microsoft\Windows\Shell\DefaultLayouts.xml" /f /q

echo.
echo Todos os atalhos conhecidos foram removidos.
::pause
