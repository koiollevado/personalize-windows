@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ============================================================
:: LIMPAR ARQUIVO ANTIGO
:: ============================================================
if exist "X:\script-diskpart.txt" del /f /q "X:\script-diskpart.txt"

:: ============================================================
:: OBTER LISTA DE DISCOS
:: ============================================================
echo list disk | diskpart > X:\lista-disco.txt

cls
echo ================================
echo     LISTA DE DISCOS DO SISTEMA
echo ================================
echo.
echo O arquivo lista-disco.txt foi aberto.
echo Utilize-o para identificar o numero do disco.
echo.
timeout /t 2 >nul
notepad X:\lista-disco.txt

:: ============================================================
:: MENU PRINCIPAL
:: ============================================================
:MENU_INICIAL
cls
echo ================================
echo     Selecione o tipo de disco
echo ================================
echo 1. MBR (Legacy)
echo 2. GPT (UEFI)
echo 0. Sair
echo ================================
set /p tipo="Escolha: "

if "%tipo%"=="1" goto MENU_MBR
if "%tipo%"=="2" goto MENU_GPT
if "%tipo%"=="0" exit /b

echo Opcao invalida.
timeout /t 2 >nul
goto MENU_INICIAL

:: ============================================================
:: MENU MBR
:: ============================================================
:MENU_MBR
cls
set esquema=
echo ==========================================
echo     Escolha o tipo de particionamento MBR
echo ==========================================
echo 1. System + Windows
echo 2. System + Windows + Dados
echo 3. System + Windows + Linux
echo M. Voltar
echo ==========================================
set /p esquema="Escolha: "

if "%esquema%"=="1" goto MBR_SW
if "%esquema%"=="2" goto MBR_SWD
if "%esquema%"=="3" goto MBR_SWL
if /i "%esquema%"=="M" goto MENU_INICIAL

echo Opcao invalida.
timeout /t 2 >nul
goto MENU_MBR


:: ============================================================
:: MENU GPT
:: ============================================================
:MENU_GPT
cls
set esquema=
echo ==========================================
echo      Escolha o particionamento GPT
echo ==========================================
echo 1. EFI + Windows
echo 2. EFI + Windows + Dados
echo 3. EFI + Windows + Recovery
echo 4. EFI + Windows + Recovery + Dados
echo M. Voltar
echo ==========================================
set /p esquema="Escolha: "

if "%esquema%"=="1" goto GPT_EW
if "%esquema%"=="2" goto GPT_EWD
if "%esquema%"=="3" goto GPT_EWR
if "%esquema%"=="4" goto GPT_EWRD
if /i "%esquema%"=="M" goto MENU_INICIAL

echo Opcao invalida.
timeout /t 2 >nul
goto MENU_GPT


:: ============================================================
:: CAPTURAR DISCO E CONVERTER GB → MB
:: ============================================================
:DEFINIR_DISCO
set disco=
cls
echo =======================================
echo   Defina o número do disco utilizado:
echo =======================================
set /p disco="Disco: "
if not defined disco goto DEFINIR_DISCO
goto %1


:: ============================================================
:: CAPTURA DE TAMANHOS
:: ============================================================
:ASK_WINDOWS
cls
echo Informe o tamanho da partição Windows em GB:
set /p win_gb="GB: "
set /a win_mb=win_gb*1024
goto %1

:ASK_DADOS
cls
echo Informe o tamanho da partição Dados em GB:
set /p dados_gb="GB: "
set /a dados_mb=dados_gb*1024
goto %1

:ASK_RECOVERY
cls
echo Informe o tamanho da partição Recovery em GB:
set /p rec_gb="GB: "
set /a rec_mb=rec_gb*1024
goto %1


:: ============================================================
:: MBR - SYSTEM + WINDOWS
:: ============================================================
:MBR_SW
set system_mb=100
call :DEFINIR_DISCO MBR_SW_CONT
goto :eof

:MBR_SW_CONT
(
echo select disk %disco%
echo clean
echo convert mbr
echo create partition primary size=%system_mb%
echo format quick fs=ntfs label="System"
echo assign letter=S
echo active
echo create partition primary
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: MBR - SYSTEM + WINDOWS + DADOS
:: ============================================================
:MBR_SWD
set system_mb=100
call :DEFINIR_DISCO MBR_SWD_ASK_WINDOWS
goto :eof

:MBR_SWD_ASK_WINDOWS
call :ASK_WINDOWS MBR_SWD_CONT
goto :eof

:MBR_SWD_CONT
(
echo select disk %disco%
echo clean
echo convert mbr
echo create partition primary size=%system_mb%
echo format quick fs=ntfs label="System"
echo assign letter=S
echo active
echo create partition primary size=%win_mb%
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo create partition primary
echo format quick fs=ntfs label="Dados"
echo assign letter=D
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: MBR - SYSTEM + WINDOWS + LINUX
:: ============================================================
:MBR_SWL
set system_mb=100
call :DEFINIR_DISCO MBR_SWL_ASK_WINDOWS
goto :eof

:MBR_SWL_ASK_WINDOWS
call :ASK_WINDOWS MBR_SWL_CONT
goto :eof

:MBR_SWL_CONT
(
echo select disk %disco%
echo clean
echo convert mbr
echo create partition primary size=%system_mb%
echo format quick fs=ntfs label="System"
echo assign letter=S
echo active
echo create partition primary size=%win_mb%
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo create partition primary
echo format quick fs=ntfs label="Linux"
echo assign letter=L
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: GPT - EFI + WINDOWS
:: ============================================================
:GPT_EW
set efi_mb=100
call :DEFINIR_DISCO GPT_EW_CONT
goto :eof

:GPT_EW_CONT
(
echo select disk %disco%
echo clean
echo convert gpt
echo create partition efi size=%efi_mb%
echo format quick fs=fat32 label="EFI"
echo assign letter=S
echo create partition msr size=16
echo create partition primary
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: GPT - EFI + WINDOWS + DADOS
:: ============================================================
:GPT_EWD
set efi_mb=100
call :DEFINIR_DISCO GPT_EWD_ASK_WINDOWS
goto :eof

:GPT_EWD_ASK_WINDOWS
call :ASK_WINDOWS GPT_EWD_CONT
goto :eof

:GPT_EWD_CONT
(
echo select disk %disco%
echo clean
echo convert gpt
echo create partition efi size=%efi_mb%
echo format quick fs=fat32 label="EFI"
echo assign letter=S
echo create partition msr size=16
echo create partition primary size=%win_mb%
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo create partition primary
echo format quick fs=ntfs label="Dados"
echo assign letter=D
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: GPT - EFI + WINDOWS + RECOVERY
:: ============================================================
:GPT_EWR
set efi_mb=100
call :DEFINIR_DISCO GPT_EWR_ASK_RECOVERY
goto :eof

:GPT_EWR_ASK_RECOVERY
call :ASK_RECOVERY GPT_EWR_CONT
goto :eof

:GPT_EWR_CONT
(
echo select disk %disco%
echo clean
echo convert gpt
echo create partition efi size=%efi_mb%
echo format quick fs=fat32 label="EFI"
echo assign letter=S
echo create partition msr size=16
echo create partition primary size=%rec_mb%
echo format quick fs=ntfs label="Recovery"
echo assign letter=R
echo set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac
echo gpt attributes=0x8000000000000001
echo create partition primary
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: GPT - EFI + WINDOWS + RECOVERY + DADOS
:: ============================================================
:GPT_EWRD
set efi_mb=100
call :DEFINIR_DISCO GPT_EWRD_ASK_RECOVERY
goto :eof

:GPT_EWRD_ASK_RECOVERY
call :ASK_RECOVERY GPT_EWRD_ASK_WINDOWS
goto :eof

:GPT_EWRD_ASK_WINDOWS
call :ASK_WINDOWS GPT_EWRD_CONT
goto :eof

:GPT_EWRD_CONT
(
echo select disk %disco%
echo clean
echo convert gpt
echo create partition efi size=%efi_mb%
echo format quick fs=fat32 label="EFI"
echo assign letter=S
echo create partition msr size=16
echo create partition primary size=%rec_mb%
echo format quick fs=ntfs label="Recovery"
echo assign letter=R
echo set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac
echo gpt attributes=0x8000000000000001
echo create partition primary size=%win_mb%
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo create partition primary
echo format quick fs=ntfs label="Dados"
echo assign letter=D
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: EXECUTAR DISKPART AUTOMATICO
:: ============================================================
:EXECUTAR
cls
echo =======================================
echo   Executando Diskpart com o script...
echo =======================================
timeout /t 2 >nul

diskpart /s X:\script-diskpart.txt

echo.
echo Processo concluído.
pause
exit /b
