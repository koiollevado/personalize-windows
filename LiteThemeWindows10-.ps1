# ============================================
# TEMA LOCAL - sem uso de pastas do sistema
# ============================================

# Caminho local (mesma pasta do script)
$LocalPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ThemesPath = "$LocalPath\Themes"
if (!(Test-Path $ThemesPath)) { New-Item -ItemType Directory -Path $ThemesPath | Out-Null }

# Função: cria e aplica tema leve
function New-LiteTheme {
    param (
        [string]$ThemeName,
        [string]$BorderColor,
        [string]$Mode = "Light"
    )

    $ThemeFile = "$ThemesPath\$ThemeName.theme"

@"
; Copyright © Microsoft Corp.

[Theme]
DisplayName=@%SystemRoot%\System32\themeui.dll,-2060
SetLogonBackground=0

[Control Panel\Desktop]
Wallpaper=
TileWallpaper=0
WallpaperStyle=10
Pattern=

[VisualStyles]
Path=%ResourceDir%\Themes\Aero\Aerolite.msstyles
ColorStyle=NormalColor
Size=NormalSize
AutoColorization=0
ColorizationColor=$BorderColor
SystemMode=$Mode
AppMode=$Mode

[boot]
SCRNSAVE.EXE=

[MasterThemeSelector]
MTSM=RJSPBS

[Sounds]
SchemeName=@%SystemRoot%\System32\mmres.dll,-800

"@ | Out-File -Encoding ASCII $ThemeFile

    Write-Host "Tema '$ThemeName' criado com sucesso em '$ThemesPath'." -ForegroundColor Green
    Start-Process -FilePath $ThemeFile
    Write-Host "Aplicando o tema $ThemeName..." -ForegroundColor Cyan

    # Define modo claro/escuro no registro
    if ($Mode -eq "Dark") {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f | Out-Null
    } else {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null
    }

    # Reinicia o Explorer automaticamente
    Write-Host "Reiniciando o Explorer para aplicar as alterações..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# Função: restaurar tema padrão
function Restore-DefaultTheme {
    Write-Host "Restaurando tema padrão do Windows..." -ForegroundColor Cyan
    Start-Process "$env:SystemRoot\Resources\Themes\aero.theme"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null
    Write-Host "Tema padrão restaurado." -ForegroundColor Green
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# Função: ajustar tamanho dos ícones da barra de tarefas
function Set-TaskbarIconSize {
    param ([string]$SizeChoice)

    $RegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    switch ($SizeChoice) {
        "1" {
            reg add $RegPath /v TaskbarSmallIcons /t REG_DWORD /d 2 /f | Out-Null
            Write-Host "Ícones pequenos aplicados à barra de tarefas." -ForegroundColor Green
        }
        "2" {
            reg add $RegPath /v TaskbarSmallIcons /t REG_DWORD /d 1 /f | Out-Null
            Write-Host "Ícones médios (padrão) aplicados à barra de tarefas." -ForegroundColor Green
        }
        "3" {
            reg add $RegPath /v TaskbarSmallIcons /t REG_DWORD /d 0 /f | Out-Null
            Write-Host "Ícones grandes aplicados à barra de tarefas." -ForegroundColor Green
        }
        default {
            Write-Host "Opção inválida para tamanho de ícones." -ForegroundColor Red
            return
        }
    }

    Write-Host "Reiniciando o Explorer para aplicar as alterações..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# ============================================
# MENU PRINCIPAL
# ============================================

Clear-Host
Write-Host "===============================" -ForegroundColor DarkCyan
Write-Host "     GERENCIADOR DE TEMAS LITE  " -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "1 - Tema Azul Claro   - 0x00CCCCFF"
Write-Host "2 - Tema Marrom Claro - 0x00B19760"
Write-Host "3 - Tema Escuro       - 0x00404040"
Write-Host "4 - Cinza Neutro  - 0xFFB0B0B0"
Write-Host "5 - Cinza Claro   - 0xFFD3D3D3"
Write-Host "6 - Cinza Médio   - 0xFFA9A9A9"
Write-Host "7 - Cinza Escuro  - 0xFF696969"
Write-Host "8 - Restaurar Tema Padrão do Windows"
Write-Host ""
$opcao = Read-Host "Escolha uma opção (1-8)"

switch ($opcao) {
    "1" { New-LiteTheme -ThemeName "LiteBlue"   -BorderColor "0X00CCCCFF" -Mode "Light" }
    "2" { New-LiteTheme -ThemeName "LiteBrown"  -BorderColor "0X00B19760" -Mode "Light" }
    "3" { New-LiteTheme -ThemeName "LiteDark"   -BorderColor "0X00404040" -Mode "Dark" }
    "4" { New-LiteTheme -ThemeName "LiteGrayNeutral"-BorderColor "0xFFB0B0B0" -Mode "Light" }
    "5" { New-LiteTheme -ThemeName "LiteGrayLight"  -BorderColor "0xFFD3D3D3" -Mode "Light" }
    "6" { New-LiteTheme -ThemeName "LiteGrayMedium" -BorderColor "0xFFA9A9A9" -Mode "Light" }
    "7" { New-LiteTheme -ThemeName "LiteGrayDark"   -BorderColor "0xFF696969" -Mode "Dark" }
    "8" { Restore-DefaultTheme; exit }
    default { Write-Host "Opção inválida. Encerrando..." -ForegroundColor Red; exit }
}

# ============================================
# MENU SECUNDÁRIO - TAMANHO DOS ÍCONES DA BARRA DE TAREFAS
# ============================================

Write-Host ""
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host " CONFIGURAÇÃO DOS ÍCONES DA BARRA DE TAREFAS" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "1 - Ícones pequenos"
Write-Host "2 - Ícones médios (padrão)"
Write-Host "3 - Ícones grandes"
Write-Host ""
$iconChoice = Read-Host "Escolha uma opção (1-3)"
Set-TaskbarIconSize -SizeChoice $iconChoice

Write-Host ""
Write-Host "Operação concluída!" -ForegroundColor Green
pause
