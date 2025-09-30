@echo off
:: --------------------------------------------
::      Detecta o SO 64 bits e copia pasta
::       e cria item no menu de contexto.
:: --------------------------------------------

:: === Define variáveis ===
set "PASTA_ORIGEM=%~dp0Easy Context Menu"
set "DESTINO=%ProgramFiles%"

:: === Verifica arquitetura do sistema ===
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo Sistema 64 bits detectado.
    :: === Copia a pasta para o destino ===
    echo Copiando arquivos para %DESTINO%...
    xcopy "%PASTA_ORIGEM%" "%DESTINO%" /E /I /Y
    :: === Importa no Registro ===
    regedit /s %~dp0otimizar-memoria-ram.reg
    exit /b
) else (
    echo O sistema nao é 64 bits. Saindo...
    exit /b
)
