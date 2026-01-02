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
if exist "X:\lista-disco.txt" del /f /q "X:\lista-disco.txt"

(
echo.
echo --------------------------------------------------------
echo             D I S C O S    L I S T A D O S
echo --------------------------------------------------------
echo   Disco N    Status         Tam.       Livre       GPT
echo   -------    ------         -------    -----       ---
echo.
echo list disk | diskpart | find "B"
echo.
echo --------------------------------------------------------
) > X:\lista-disco.txt

cls
echo.
echo =============================================
echo           LISTA DE DISCOS DO SISTEMA
echo =============================================
echo.
echo      O arquivo lista-disco.txt foi aberto.
echo    Use-o para identificar o numero do disco.
echo.
echo =============================================
echo.

notepad X:\lista-disco.txt

:: ============================================================
:: MENU PRINCIPAL
:: ============================================================
:MENU_INICIAL
cls
echo.
echo =============================================
echo  Selecione o tipo de particionamento de disco
echo =============================================
echo               1. MBR (Legacy)
echo               2. GPT (UEFI)
echo               0. Sair
echo =============================================
set /p tipo="Escolha: "

if "%tipo%"=="1" goto MENU_MBR
if "%tipo%"=="2" goto MENU_GPT
if "%tipo%"=="0" goto SAIR

echo Opcao invalida.

goto MENU_INICIAL

:: ============================================================
:: MENU MBR
:: ============================================================
:MENU_MBR
cls
set esquema=
echo.
echo =============================================
echo   Escolha o particionamento do disco em MBR
echo =============================================
echo          1. System + Windows
echo          2. System + Windows + Dados
echo          3. System + Windows + Linux
echo          M. Voltar
echo =============================================
set /p esquema="Escolha: "

if "%esquema%"=="1" goto MBR_SW
if "%esquema%"=="2" goto MBR_SWD
if "%esquema%"=="3" goto MBR_SWL
if /i "%esquema%"=="M" goto MENU_INICIAL

echo Opcao invalida.

goto MENU_MBR


:: ============================================================
:: MENU GPT
:: ============================================================
:MENU_GPT
cls
set esquema=
echo.
echo =============================================
echo   Escolha o particionamento do disco em GPT
echo =============================================
echo      1. EFI + Windows
echo      2. EFI + Windows + Dados
echo      3. EFI + Windows + Recovery
echo      4. EFI + Windows + Recovery + Dados
echo      M. Voltar
echo =============================================
set /p esquema="Escolha: "

if "%esquema%"=="1" goto GPT_EW
if "%esquema%"=="2" goto GPT_EWD
if "%esquema%"=="3" goto GPT_EWR
if "%esquema%"=="4" goto GPT_EWRD
if /i "%esquema%"=="M" goto MENU_INICIAL

echo Opcao invalida.

goto MENU_GPT


:: ============================================================
:: CAPTURAR DISCO E CONVERTER GB --> MB
:: ============================================================
:DEFINIR_DISCO
set disco=
cls
echo.
echo =============================================
echo          Defina o disco utilizado
echo =============================================
echo.
set /p disco="         Informe o numero do disco: "
if not defined disco goto DEFINIR_DISCO
goto %1


:: ============================================================
:: CAPTURA DE TAMANHOS
:: ============================================================
:ASK_WINDOWS
cls
echo.
echo =============================================
echo         Defina a particao Windows
echo =============================================
echo.
set /p win_gb="          Informe o tamanho em GB: "
set /a win_mb=win_gb*1024
goto %1

:ASK_DADOS
cls
echo.
echo =============================================
echo          Defina a particao Dados
echo =============================================
echo.
set /p dados_gb="          Informe o tamanho em GB: "
set /a dados_mb=dados_gb*1024
goto %1

:ASK_RECOVERY
cls
echo.
echo =============================================
echo         Defina a particao Recovery
echo =============================================
echo.
set /p rec_gb="          Informe o tamanho em GB: "
set /a rec_mb=rec_gb*1024
goto %1


:: ============================================================
:: MBR - SYSTEM + WINDOWS
:: ============================================================
:MBR_SW
set system_mb=100
set tipo_disco=MBR
set layout="System + Windows"

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
set tipo_disco=MBR
set layout="System + Windows + Dados"

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
set tipo_disco=MBR
set layout="System + Windows + Linux"

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
set tipo_disco=GPT
set layout="EFI + Windows"

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
set tipo_disco=GPT
set layout="EFI + Windows + Dados"

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
set tipo_disco=GPT
set layout="EFI + Windows + Recovery"

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
set tipo_disco=GPT
set layout="EFI + Windows + Recovery + Dados"

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

:EXECUTAR
cls
echo =============================================
echo            RESUMO DA CONFIGURACAO
echo =============================================
echo.
echo Particionamento: !tipo_disco!
echo Particoes escolhidas: !layout!
echo Disco selecionado: !disco!
echo.
echo ---------------------------------------------

if defined system_mb (
    echo Particao System: !system_mb! MB
)

if defined efi_mb (
    echo Particao EFI: !efi_mb! MB
)

if defined win_mb (
    echo Particao Windows: !win_gb! GB
)

if defined dados_mb (
    echo Particao Dados: !dados_gb! GB
)

if defined rec_mb (
    echo Particao Recovery: !rec_gb! GB
)

if !layout!=="System + Windows + Linux" (
    echo Particao Linux: *restante do disco*
)

if !layout!=="System + Windows + Dados" (
    echo Particao Dados: *restante do disco*
)

if !layout!=="EFI + Windows + Dados" (
    echo Particao Dados: *restante do disco*
)

if !layout!=="EFI + Windows + Recovery + Dados" (
    echo Particao Dados: *restante do disco*
)


echo =============================================
echo         Deseja manter esta configuracao
echo ---------------------------------------------
echo           S = Sim
echo           N = Nao (voltar ao menu)
echo =============================================
set /p conf="Opcao: "

if /i "!conf!"=="N" goto MENU_INICIAL
if /i "!conf!"=="S" goto SAIR

echo Opcao invalida.

goto EXECUTAR

:SAIR
exit /b



