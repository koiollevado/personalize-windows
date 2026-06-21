@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:MENU_INICIAL

:: ============================================================
:: LIMPAR ARQUIVO ANTIGO
:: ============================================================

if exist "X:\script-diskpart.txt" del /f /q "X:\script-diskpart.txt"

cls
echo =============================================
echo           DETECCAO DE BIOS / UEFI
echo =============================================
echo.

REM =========================================================
REM 1. DETECTAR PELO REGISTRO
REM =========================================================

set "REG_MODE=DESCONHECIDO"

for /f "tokens=3" %%A in ('
    reg query HKLM\SYSTEM\CurrentControlSet\Control /v PEFirmwareType 2^>nul ^| find "PEFirmwareType"
') do (
    set "FWTYPE=%%A"
)

if /I "!FWTYPE!"=="0x1" set "REG_MODE=LEGACY"
if /I "!FWTYPE!"=="0x2" set "REG_MODE=UEFI"

:: echo [REG QUERY]
:: echo Firmware detectado: !REG_MODE!
:: echo.

REM =========================================================
REM 2. DETECTAR PELO BCDEDIT
REM =========================================================

set "BCD_MODE=DESCONHECIDO"

for /f "tokens=*" %%A in ('
    bcdedit ^| find /I "path"
') do (
    echo %%A | find /I "winload.efi" >nul && set "BCD_MODE=UEFI"
    echo %%A | find /I "winload.exe" >nul && set "BCD_MODE=LEGACY"
)

:: echo [BCDEDIT]
:: echo Firmware detectado: !BCD_MODE!
:: echo.

REM =========================================================
REM 3. COMPARAR RESULTADOS
REM =========================================================

:: echo [COMPARACAO]

if /I "!REG_MODE!"=="!BCD_MODE!" (

::     echo RESULTADO: OS DOIS METODOS CONCORDAM
::     echo Sistema iniciado em: !REG_MODE!
    echo.

    REM =====================================================
    REM 4. SUGESTAO DE PARTICIONAMENTO
    REM =====================================================

    if /I "!REG_MODE!"=="UEFI" (
        echo =============================================
        echo              S U G E S T A O
        echo ---------------------------------------------
        echo          Firmware UEFI detectado
        echo        Utilize particionamento GPT
        echo =============================================
    )

    if /I "!REG_MODE!"=="LEGACY" (
        echo =============================================
        echo              S U G E S T A O
        echo ---------------------------------------------
        echo        Firmware Legacy BIOS detectado
        echo         Utilize particionamento MBR
        echo =============================================
    )

) else (
    echo.
    echo =============================================
    echo      Atencao: DIFERENCA ENTRE OS METODOS
    echo.
    echo        REG QUERY = !REG_MODE!
    echo        BCDEDIT   = !BCD_MODE!
    echo.
    echo   Nao foi possivel determinar com seguranca
    echo        o modo correto de inicializacao.
    echo =============================================
)

echo.
pause



echo.
echo =============================================
echo      Selecione o particionamento de disco
echo =============================================
echo               MBR (Legacy)
echo ---------------------------------------------
echo    1. System + Windows
echo    2. System + Windows + Dados
echo    3. System + Windows + Recovery
echo    4. System + Windows + Recovery + Dados
echo ---------------------------------------------
echo               GPT (UEFI)
echo ---------------------------------------------
echo      5. EFI + Windows
echo      6. EFI + Windows + Dados
echo      7. EFI + Windows + Recovery
echo      8. EFI + Windows + Recovery + Dados
echo ---------------------------------------------
echo               0. Sair
echo =============================================
echo.
set /p esquema="          Escolha: "

if "%esquema%"=="1" goto MBR_SW
if "%esquema%"=="2" goto MBR_SWD
if "%esquema%"=="3" goto MBR_SWR
if "%esquema%"=="4" goto MBR_SWRD
if "%esquema%"=="5" goto GPT_EW
if "%esquema%"=="6" goto GPT_EWD
if "%esquema%"=="7" goto GPT_EWR
if "%esquema%"=="8" goto GPT_EWRD
if "%esquema%"=="0" goto SAIR

echo Opcao invalida.

goto MENU_INICIAL

:: ============================================================
:: CAPTURAR DISCO E CONVERTER GB --> MB
:: ============================================================
:DEFINIR_DISCO
set disco=
cls
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
echo.
pause
echo.
echo =============================================
echo        Defina o disco a ser utilizado
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
echo              S U G E S T A O
echo ---------------------------------------------
echo 380 MB -- Windows 10 Enterprise 2016 LTSB x64
echo ---------------------------------------------
echo 460 MB -- Windows 10 Pro 22h2 x64
echo ---------------------------------------------
echo 350 MB -- Windows 10 Pro/Home 21h1 x86
echo ---------------------------------------------
echo.
set /p rec_mb="          Informe o tamanho em MB: "
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
:: MBR - SYSTEM + WINDOWS + RECOVERY
:: ============================================================
:MBR_SWR
set system_mb=100
set tipo_disco=MBR
set layout="System + Windows + Recovery"

call :DEFINIR_DISCO MBR_SWR_ASK_WINDOWS
goto :eof

:MBR_SWR_ASK_WINDOWS
call :ASK_RECOVERY MBR_SWR_CONT
goto :eof

:MBR_SWR_CONT
(
echo select disk %disco%
echo clean
echo convert mbr
echo create partition primary size=%system_mb%
echo format quick fs=ntfs label="System"
echo active
echo assign letter=S
echo create partition primary
echo shrink minimum=%rec_mb%
echo format quick fs=ntfs label="Windows"
echo assign letter="W"
echo create partition primary
echo format quick fs=ntfs label="Recovery"
echo assign letter="R"
echo set id=27
echo exit
) > X:\script-diskpart.txt
goto EXECUTAR


:: ============================================================
:: MBR - SYSTEM + WINDOWS + RECOVERY + DADOS
:: ============================================================
:MBR_SWRD
set system_mb=100
set tipo_disco=MBR
set layout="System + Windows + Recovery + Dados"

call :DEFINIR_DISCO MBR_SWRD_ASK_RECOVERY
goto :eof

:MBR_SWRD_ASK_RECOVERY
call :ASK_RECOVERY MBR_SWRD_ASK_WINDOWS
goto :eof

:MBR_SWRD_ASK_WINDOWS
call :ASK_WINDOWS MBR_SWRD_CONT
goto :eof

:MBR_SWRD_CONT
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
echo create partition primary size=%rec_mb%
echo format quick fs=ntfs label="Recovery"
echo assign letter="R"
echo set id=27
echo create partition primary
echo format quick fs=ntfs label="Dados"
echo assign letter=D
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
echo =======================================
echo       RESUMO DA CONFIGURACAO
echo =======================================
echo.
echo      Tipo de disco: !tipo_disco!
echo   Layout escolhido: !layout!
echo  Disco selecionado: !disco!
echo.
echo ---------------------------------------

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
    echo Particao Recovery: !rec_mb! MB
)

if !layout!=="System + Windows + Dados" (
    echo Particao Dados: *restante do disco*
)

if !layout!=="System + Windows + Recovery + Dados" (
    echo Particao Dados: *restante do disco*
)

if !layout!=="EFI + Windows + Dados" (
    echo Particao Dados: *restante do disco*
)

if !layout!=="EFI + Windows + Recovery + Dados" (
    echo Particao Dados: *restante do disco*
)

echo.
echo ---------------------------------------
echo     Deseja manter esta configuracao
echo ---------------------------------------
echo       S = Sim (Executa o script)
echo       N = Nao (voltar ao menu)
echo =======================================
echo.
set /p conf="         Opcao: "

if /i "!conf!"=="N" goto MENU_INICIAL
if /i "!conf!"=="S" goto DISKPART

echo Opcao invalida.
goto EXECUTAR

:DISKPART
cls
echo.
echo =============================================
echo.
echo           Executando o Diskpart ...
echo.
echo =============================================
echo.
if exist X:\script-diskpart.txt (
diskpart /s X:\script-diskpart.txt | find "O disco especificado n"
)
echo.
echo =============================================
echo.
echo              Processo concluido.
echo.
echo =============================================
echo.
pause
goto SAIR

:SAIR
exit /b

