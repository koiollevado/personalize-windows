# ============================================
# Script: LiteThemes.ps1
# Autor: ChatGPT (adaptado para Francisco Filho)
# Função: Criar e aplicar temas leves personalizados no Windows
# Versão: v5 - Três opções de tamanho de ícones da barra de tarefas
# ============================================

$ThemesPath = "$env:LOCALAPPDATA\Microsoft\Windows\Themes"
if (!(Test-Path $ThemesPath)) { New-Item -ItemType Directory -Path $ThemesPath | Out-Null }

# Função: cria e aplica tema leve
function New-LiteTheme {
    param ([string]$ThemeName, [string]$BorderColor, [string]$Mode = "Light")
    $ThemeFile = "$ThemesPath\$ThemeName.theme"

    if (!(Test-Path $ThemeFile)) {
@"
[Theme]
DisplayName=$ThemeName

[Control Panel\Colors]
Window=255 255 255
Menu=240 240 240
ButtonFace=240 240 240
ButtonText=0 0 0
ActiveTitle=200 200 200
InactiveTitle=220 220 220

[Control Panel\Desktop]
Wallpaper=
TileWallpaper=0
WallpaperStyle=0
Pattern=

[VisualStyles]
Path=%SystemRoot%\resources\themes\Aero\aero.msstyles
ColorStyle=NormalColor
Size=NormalSize
ColorizationColor=$BorderColor
Transparency=0

[Metrics]
IconSpacing=75
IconVerticalSpacing=75
"@ | Out-File -Encoding ASCII $ThemeFile
        Write-Host "Tema '$ThemeName' criado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "Tema '$ThemeName' já existe." -ForegroundColor Yellow
    }

    Start-Process $ThemeFile
    Write-Host "Aplicando o tema $ThemeName..." -ForegroundColor Cyan

    # Define modo claro ou escuro
    if ($Mode -eq "Dark") {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f | Out-Null
    } else {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null
    }
}

# Função: restaurar tema padrão
function Restore-DefaultTheme {
    Write-Host "Restaurando tema padrão do Windows..." -ForegroundColor Cyan
    Start-Process "$env:SystemRoot\Resources\Themes\aero.theme"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null
    Write-Host "Tema padrão restaurado." -ForegroundColor Green
}

# Função: ajustar tamanho dos ícones da BARRA DE TAREFAS
function Set-TaskbarIconSize {
    param ([string]$SizeChoice)

    $RegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    switch ($SizeChoice) {
        "1" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 0 /f | Out-Null
            Write-Host "Ícones pequenos aplicados à barra de tarefas." -ForegroundColor Green
        }
        "2" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 1 /f | Out-Null
            Write-Host "Ícones médios (padrão) aplicados à barra de tarefas." -ForegroundColor Green
        }
        "3" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 2 /f | Out-Null
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
Write-Host "1 - Tema Azul Claro (leve e limpo)"
Write-Host "2 - Tema Marrom Claro (leve e clássico)"
Write-Host "3 - Tema Escuro (leve e contrastante)"
Write-Host "4 - Restaurar Tema Padrão do Windows"
Write-Host ""
$opcao = Read-Host "Escolha uma opção (1-4)"

switch ($opcao) {
    "1" { New-LiteTheme -ThemeName "LiteBlue" -BorderColor "0X00CCCCFF" -Mode "Light" }
    "2" { New-LiteTheme -ThemeName "LiteBrown" -BorderColor "0X00B19760" -Mode "Light" }
    "3" { New-LiteTheme -ThemeName "LiteDark" -BorderColor "0X00404040" -Mode "Dark" }
    "4" { Restore-DefaultTheme; exit }
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
