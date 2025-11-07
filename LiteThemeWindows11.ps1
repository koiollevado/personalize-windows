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
; Windows - IDS_THEME_DISPLAYNAME_AERO_LIGHT
DisplayName=@%SystemRoot%\System32\themeui.dll,-2060
SetLogonBackground=0

; Computer - SHIDI_SERVER
[CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\DefaultIcon]
DefaultValue=%SystemRoot%\System32\imageres.dll,-109

; UsersFiles - SHIDI_USERFILES
[CLSID\{59031A47-3F72-44A7-89C5-5595FE6B30EE}\DefaultIcon]
DefaultValue=%SystemRoot%\System32\imageres.dll,-123

; Network - SHIDI_MYNETWORK
[CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\DefaultIcon]
DefaultValue=%SystemRoot%\System32\imageres.dll,-25

; Recycle Bin - SHIDI_RECYCLERFULL SHIDI_RECYCLER
[CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon]
Full=%SystemRoot%\System32\imageres.dll,-54
Empty=%SystemRoot%\System32\imageres.dll,-55

[Control Panel\Cursors]
AppStarting=%SystemRoot%\cursors\aero_working.ani
Arrow=%SystemRoot%\cursors\aero_arrow.cur
Crosshair=
Hand=%SystemRoot%\cursors\aero_link.cur
Help=%SystemRoot%\cursors\aero_helpsel.cur
IBeam=
No=%SystemRoot%\cursors\aero_unavail.cur
NWPen=%SystemRoot%\cursors\aero_pen.cur
SizeAll=%SystemRoot%\cursors\aero_move.cur
SizeNESW=%SystemRoot%\cursors\aero_nesw.cur
SizeNS=%SystemRoot%\cursors\aero_ns.cur
SizeNWSE=%SystemRoot%\cursors\aero_nwse.cur
SizeWE=%SystemRoot%\cursors\aero_ew.cur
UpArrow=%SystemRoot%\cursors\aero_up.cur
Wait=%SystemRoot%\cursors\aero_busy.ani
DefaultValue=Windows Default
DefaultValue.MUI=@main.cpl,-1020

[Control Panel\Desktop]
Wallpaper=%SystemRoot%\web\wallpaper\Windows\img0.jpg
TileWallpaper=0
WallpaperStyle=10
Pattern=

[VisualStyles]
Path=%ResourceDir%\Themes\Aero\Aerolite.msstyles
ColorStyle=NormalColor
Size=NormalSize
AutoColorization=0
ColorizationColor=0XC40078D4
SystemMode=Light
AppMode=Light

[boot]
SCRNSAVE.EXE=

[MasterThemeSelector]
MTSM=RJSPBS

[Sounds]
; IDS_SCHEME_DEFAULT
SchemeName=@%SystemRoot%\System32\mmres.dll,-800

"@ | Out-File -Encoding ASCII $ThemeFile

    Write-Host "Tema '$ThemeName' criado com sucesso em '$ThemesPath'." -ForegroundColor Green

    # Aplica o tema diretamente (não precisa estar em pasta do sistema)
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
}

# Função: restaurar tema padrão
function Restore-DefaultTheme {
    Write-Host "Restaurando tema padrão do Windows..." -ForegroundColor Cyan
    Start-Process "$env:SystemRoot\Resources\Themes\aero.theme"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null
    Write-Host "Tema padrão restaurado." -ForegroundColor Green
}

# Função: ajustar tamanho dos ícones da barra de tarefas
function Set-TaskbarIconSize {
    param ([string]$SizeChoice)

    $RegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    switch ($SizeChoice) {
        "1" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 2 /f | Out-Null
            Write-Host "Ícones pequenos aplicados à barra de tarefas." -ForegroundColor Green
        }
        "2" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 1 /f | Out-Null
            Write-Host "Ícones médios (padrão) aplicados à barra de tarefas." -ForegroundColor Green
        }
        "3" {
            reg add $RegPath /v TaskbarSi /t REG_DWORD /d 0 /f | Out-Null
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

