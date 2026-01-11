@echo off
setlocal ENABLEDELAYEDEXPANSION

:: CONFIGURAÇÕES
set ISO_ORIGINAL=Win10_22H2_PT-BR_x32v1.iso
set ISO_MONTAGEM=ISO_EXTRATADA
set ISO_SAIDA=Win10_22H2_PT-BR_x32_auto.iso
set AUTO_XML=autounattend.xml

:: CAMINHO PARA oscdimg.exe
set OSCDIMG="C:\Users\Golimaru\Downloads\oscdimg.exe"

:: VERIFICAÇÕES
if not exist "%ISO_ORIGINAL%" (
    echo [ERRO] ISO original '%ISO_ORIGINAL%' não encontrada!
    exit /b 1
)

if not exist "%AUTO_XML%" (
    echo [ERRO] Arquivo '%AUTO_XML%' não encontrado!
    exit /b 1
)

if not exist %OSCDIMG% (
    echo [ERRO] oscdimg.exe não encontrado em: %OSCDIMG%
    exit /b 1
)

:: LIMPA PASTA TEMPORÁRIA
rd /s /q "%ISO_MONTAGEM%" >nul 2>&1
mkdir "%ISO_MONTAGEM%"

:: MONTA ISO
echo [INFO] Extraindo a ISO...
PowerShell Mount-DiskImage -ImagePath "%CD%\%ISO_ORIGINAL%"
FOR /F "tokens=2 delims==" %%I IN ('PowerShell -Command "(Get-DiskImage -ImagePath '%CD%\%ISO_ORIGINAL%') | Get-Volume | Select -ExpandProperty DriveLetter"') DO (
    set DRIVELETRA=%%I
)

xcopy "%DRIVELETRA%:\*" "%ISO_MONTAGEM%\" /E /H /Q /Y

PowerShell Dismount-DiskImage -ImagePath "%CD%\%ISO_ORIGINAL%"

:: ADICIONA O ARQUIVO autounattend.xml
copy "%AUTO_XML%" "%ISO_MONTAGEM%\"

:: CRIA NOVA ISO
echo [INFO] Criando nova ISO inicializável...
%OSCDIMG% -b"%ISO_MONTAGEM%\boot\etfsboot.com" -u2 -h -m -o -lWIN_UNATTENDED "%ISO_MONTAGEM%" "%ISO_SAIDA%"

echo [SUCESSO] Nova ISO criada: %ISO_SAIDA%
pause
