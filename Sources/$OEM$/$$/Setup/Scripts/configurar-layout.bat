@echo off

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

