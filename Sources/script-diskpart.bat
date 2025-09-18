@echo off
setlocal enabledelayedexpansion
echo list disk | diskpart > X:\lista-disco.txt
chcp 65001 >null
cls
echo          ================================
echo           Aguarde a execução do diskpart
echo.
echo              para identificar o disco
echo          ================================
timeout 3 >nul
start "" notepad X:\lista-disco.txt
cls
:main_menu
cls
echo ================================
echo      Escolha o modo de inicialização:
echo ================================
echo  1. Legacy
echo  2. UEFI
echo  0. Sair
echo ================================
set /p choice="Digite o número da opção: "

if "%choice%"=="1" (
	set /a "system=100"
    call :legacy_menu
) else if "%choice%"=="2" (
	set /a "efi=100"
    call :uefi_menu
) else if "%choice%"=="0" (
    echo Saindo...
    exit /b
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto main_menu
)

:legacy_menu
cls
echo ==============================================
echo           Modo de inicialização em Legacy.
echo ==============================================
echo  11. Criar as partições System e Windows
echo  12. Criar as partições System, Windows e Dados
echo  13. Criar as partições System, Windows e Linux
echo   M. Voltar ao menu principal
echo ==============================================
set /p legacy_choice="Digite o número da opção: "

if "%legacy_choice%"=="11" (
    call :create_partitions_legacy
) else if "%legacy_choice%"=="12" (
    call :create_partitions_legacy_data
) else if "%legacy_choice%"=="13" (
    call :create_partitions_legacy_linux
) else if /i "%legacy_choice%"=="M" (
    goto main_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto legacy_menu
)

:create_partitions_legacy
cls
echo.
echo ========================================
echo  Criando as partições no modo Legacy...
echo ========================================
echo.

set /p disco=" Defina qual disco será utilizado: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição System: !system! MB
echo Tamanho da partição Windows: Restante do disco.
echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto legacy_sw
) else if "!continue!"=="s" (
    goto legacy_sw
) else if /i "!continue!"=="n" (
    goto legacy_menu
) else if /i "!continue!"=="N" (
    goto legacy_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto legacy_menu
)

:legacy_sw
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert mbr>> X:\script-diskpart.txt
echo create partition primary size=!system!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="System">> X:\script-diskpart.txt 
echo assign letter="S">> X:\script-diskpart.txt
echo active>> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto legacy_menu

:create_partitions_legacy_data
cls
echo.
echo ========================================
echo  Criando as partições no modo Legacy...
echo ========================================
echo.

set /p disco="Defina qual disco será utilizado: "
set /p windows="Defina o tamanho, em MB, da partição Windows: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição System: !system! MB
echo Tamanho da partição Windows: !windows! MB
echo Tamanho da partição Dados pessoais: Restante do disco.
echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto legacy_swd
) else if "!continue!"=="s" (
    goto legacy_swd
) else if /i "!continue!"=="n" (
    goto legacy_menu
) else if /i "!continue!"=="N" (
    goto legacy_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto legacy_menu
)

:legacy_swd
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert mbr>> X:\script-diskpart.txt
echo create partition primary size=!system!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="System">> X:\script-diskpart.txt
echo assign letter="S">> X:\script-diskpart.txt
echo active>> X:\script-diskpart.txt
echo create partition primary size=!windows!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Dados Pessoais">> X:\script-diskpart.txt
echo assign letter="P">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto legacy_menu

:create_partitions_legacy_linux
cls
echo.
echo ========================================
echo  Criando as partições no modo Legacy...
echo ========================================
echo.

set /p disco="Defina qual disco será utilizado: "
set /p windows="Defina o tamanho, em MB, da partição Windows: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição System: !system! MB
echo Tamanho da partição Windows: !windows! MB
echo Tamanho da partição Linux: Restante do disco.
echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto legacy_swl
) else if "!continue!"=="s" (
    goto legacy_swl
) else if /i "!continue!"=="n" (
    goto legacy_menu
) else if /i "!continue!"=="N" (
    goto legacy_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto legacy_menu
)

:legacy_swl
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert mbr>> X:\script-diskpart.txt
echo create partition primary size=!system!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="System">> X:\script-diskpart.txt
echo assign letter="S">> X:\script-diskpart.txt
echo active>> X:\script-diskpart.txt
echo create partition primary size=!windows!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Linux">> X:\script-diskpart.txt
echo assign letter="L">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto legacy_menu


:uefi_menu
cls
echo =====================================================
echo            Modo de inicialização UEFI.
echo =====================================================
echo  21. Criar as partições EFI e Windows
echo  22. Criar as partições EFI, Windows e Dados
echo  23. Criar as partições EFI, Windows e Recovery
echo  24. Criar as partições EFI, Windows, Recovery e Dados
echo   M. Voltar ao menu principal
echo =====================================================
set /p uefi_choice="Digite o número da opção: "

if "%uefi_choice%"=="21" (
    call :create_partitions_uefi
) else if "%uefi_choice%"=="22" (
    call :create_partitions_uefi_data
) else if "%uefi_choice%"=="23" (
    call :create_partitions_uefi_recovery
) else if "%uefi_choice%"=="24" (
    call :create_partitions_uefi_recovery_data
) else if /i "%uefi_choice%"=="M" (
    goto main_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto uefi_menu
)

:create_partitions_uefi
cls
echo.
echo ========================================
echo   Criando as partições no modo UEFI...
echo ========================================
echo.
set /p disco="Defina qual disco será utilizado: "

echo.
echo Disco escolhido: !disco!
echo Tamanho da partição UEFI: !efi! MB
echo Tamanho da partição Windows: Restante do disco.
echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto uefi_sw
) else if "!continue!"=="s" (
    goto uefi_sw
) else if /i "!continue!"=="n" (
    goto uefi_menu
) else if /i "!continue!"=="N" (
    goto uefi_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto uefi_menu
)
:uefi_sw
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt 
echo convert gpt>> X:\script-diskpart.txt
echo create partition efi size=!efi!>> X:\script-diskpart.txt 
echo format quick fs=fat32 label="EFI">> X:\script-diskpart.txt 
echo assign letter="S">> X:\script-diskpart.txt
echo create partition msr size=16>> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt 
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt 
echo assign letter="W">> X:\script-diskpart.txt 
echo exit>> X:\script-diskpart.txt 
goto uefi_menu

:create_partitions_uefi_data
cls
echo.
echo ========================================
echo   Criando as partições no modo UEFI...
echo ========================================
echo.
set /p disco="Defina qual disco será utilizado: "
set /p windows="Defina o tamanho, em MB, da partição Windows: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição UEFI: !efi! MB
echo Tamanho da partição Windows: !windows! MB
echo Tamanho da partição Dados Pessoais: Restante do disco.
echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto uefi_ewd
) else if "!continue!"=="s" (
    goto uefi_ewd
) else if /i "!continue!"=="n" (
    goto uefi_menu
) else if /i "!continue!"=="N" (
    goto uefi_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto uefi_menu
)
:uefi_ewd
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert gpt>> X:\script-diskpart.txt
echo create partition efi size=!efi!>> X:\script-diskpart.txt
echo format quick fs=fat32 label="EFI">> X:\script-diskpart.txt
echo assign letter="S">> X:\script-diskpart.txt
echo create partition msr size=16>> X:\script-diskpart.txt
echo create partition primary size=!windows!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Dados Pessoais">> X:\script-diskpart.txt
echo assign letter="P">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto uefi_menu

:create_partitions_uefi_recovery
cls
echo.
echo ========================================
echo   Criando as partições no modo UEFI...
echo ========================================
echo.
set /p disco="Defina qual disco será utilizado: "
set /p recovery="Defina o tamanho, em MB, da partição Recovery: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição UEFI: !efi! MB
echo Tamanho da partição Recovery: !recovery! MB
echo Tamanho da partição Windows: Restante do disco.

echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto uefi_ewr
) else if "!continue!"=="s" (
    goto uefi_ewr
) else if /i "!continue!"=="n" (
    goto uefi_menu
) else if /i "!continue!"=="N" (
    goto uefi_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto uefi_menu
)
:uefi_ewr
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert gpt>> X:\script-diskpart.txt
echo create partition efi size=!efi!>> X:\script-diskpart.txt
echo format quick fs=fat32 label="EFI">> X:\script-diskpart.txt
echo assign letter="S">> X:\script-diskpart.txt
echo create partition msr size=16>> X:\script-diskpart.txt
echo create partition primary size=!recovery!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Recovery">> X:\script-diskpart.txt
echo assign letter="R">> X:\script-diskpart.txt
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac">> X:\script-diskpart.txt
echo gpt attributes=0x8000000000000001>> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto uefi_menu

:create_partitions_uefi_recovery_data
cls
echo.
echo ========================================
echo   Criando as partições no modo UEFI...
echo ========================================
echo.
set /p disco="Defina qual disco será utilizado: "

set /p recovery="Defina o tamanho, em MB, da partição Recovery: "
set /p windows="Defina o tamanho, em MB, da partição Windows: "
echo.
echo Disco escolhido: !disco!
echo Tamanho da partição UEFI: !efi! MB
echo Tamanho da partição Recovery: !recovery! MB
echo Tamanho da partição Windows: !windows! MB
echo Tamanho da partição Dados Pessoais: Restante do disco.

echo.
set /p continue=". Deseja continuar o procedimento? (S/N): "

if "!continue!"=="S" (
	goto uefi_ewrd
) else if "!continue!"=="s" (
    goto uefi_ewrd
) else if /i "!continue!"=="n" (
    goto uefi_menu
) else if /i "!continue!"=="N" (
    goto uefi_menu
) else (
    echo Opção inválida. Tente novamente.
    timeout /t 3 >nul
    goto uefi_menu
)
:uefi_ewrd
echo select disk !disco!> X:\script-diskpart.txt
echo clean>> X:\script-diskpart.txt
echo convert gpt>> X:\script-diskpart.txt
echo create partition efi size=!efi!>> X:\script-diskpart.txt
echo format quick fs=fat32 label="EFI">> X:\script-diskpart.txt
echo assign letter="S">> X:\script-diskpart.txt
echo create partition msr size=16>> X:\script-diskpart.txt
echo create partition primary size=!recovery!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Recovery">> X:\script-diskpart.txt
echo assign letter="R">> X:\script-diskpart.txt
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac">> X:\script-diskpart.txt
echo gpt attributes=0x8000000000000001>> X:\script-diskpart.txt
echo create partition primary size=!windows!>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Windows">> X:\script-diskpart.txt
echo assign letter="W">> X:\script-diskpart.txt
echo create partition primary>> X:\script-diskpart.txt
echo format quick fs=ntfs label="Dados Pessoais">> X:\script-diskpart.txt
echo assign letter="P">> X:\script-diskpart.txt
echo exit>> X:\script-diskpart.txt
goto uefi_menu

