@echo off

rem ============================================================
rem Remove pastas de idioma xx-xx, mantendo apenas en-us e pt-br
rem ============================================================

for /D %%i in (C:\WinPE_amd64\media\*-*) do (
    if /I not "%%~nxi"=="en-us" if /I not "%%~nxi"=="pt-br" (
        rmdir /S /Q "%%i"
    )
)

for /D %%i in (C:\WinPE_amd64\media\Boot\*-*) do (
    if /I not "%%~nxi"=="en-us" if /I not "%%~nxi"=="pt-br" (
        rmdir /S /Q "%%i"
    )
)

for /D %%i in (C:\WinPE_amd64\media\EFI\Microsoft\Boot\*-*) do (
    if /I not "%%~nxi"=="en-us" if /I not "%%~nxi"=="pt-br" (
        rmdir /S /Q "%%i"
    )
)

exit /b
