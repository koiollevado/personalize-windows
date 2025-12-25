# ============================================================
#  TEMA LEVE PERSONALIZADO – WINDOWS 10 / 11
# ============================================================

Clear-Host

# ============================================================
# CAMINHOS LOCAIS
# ============================================================

$LocalPath  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ThemesPath = Join-Path $LocalPath "Themes"

if (-not (Test-Path $ThemesPath)) {
    New-Item -ItemType Directory -Path $ThemesPath | Out-Null
}

# ============================================================
# FUNÇÃO: CRIAR E APLICAR TEMA LEVE
# ============================================================

function New-LiteTheme {
    param (
        [string]$ThemeName,
        [int]$AccentColor,
        [int]$AppsTheme,
        [int]$SystemTheme
    )

    $ThemeFile = Join-Path $ThemesPath "$ThemeName.theme"

@"
; ============================================================
; TEMA LEVE PERSONALIZADO - WINDOWS 10 / 11
; ============================================================

[Theme]
DisplayName=$ThemeName
SetLogonBackground=0

[Control Panel\Desktop]
Wallpaper=
WallpaperStyle=10
TileWallpaper=0

[VisualStyles]
Path=%ResourceDir%\Themes\Aero\Aerolite.msstyles
ColorStyle=NormalColor
Size=NormalSize
AutoColorization=0
ColorizationColor=$AccentColor

[Sounds]
SchemeName=@%SystemRoot%\System32\mmres.dll,-800

[MasterThemeSelector]
MTSM=RJSPBS
"@ | Out-File -Encoding ASCII $ThemeFile

    Write-Host "Tema '$ThemeName' criado com sucesso." -ForegroundColor Green

    # ============================
    # APLICAR TEMA
    # ============================

    Start-Process $ThemeFile
    Start-Sleep -Seconds 1

    # ============================
    # DEFINIR MODO CLARO / ESCURO
    # ============================

    $Personalize = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

    reg add $Personalize /v AppsUseLightTheme   /t REG_DWORD /d $AppsTheme   /f | Out-Null
    reg add $Personalize /v SystemUsesLightTheme /t REG_DWORD /d $SystemTheme /f | Out-Null

    # ============================
    # APLICAR ACCENT COLOR
    # ============================

    reg add "HKCU\Software\Microsoft\Windows\DWM" /v ColorPrevalence /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v AccentColor /t REG_DWORD /d $AccentColor /f | Out-Null

    Restart-Explorer
}

# ============================================================
# FUNÇÃO: RESTAURAR TEMA PADRÃO DO WINDOWS
# ============================================================

function Restore-DefaultTheme {
    Write-Host "Restaurando tema padrão do Windows..." -ForegroundColor Cyan

    Start-Process "$env:SystemRoot\Resources\Themes\aero.theme"

    $Personalize = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    reg add $Personalize /v AppsUseLightTheme   /t REG_DWORD /d 1 /f | Out-Null
    reg add $Personalize /v SystemUsesLightTheme /t REG_DWORD /d 1 /f | Out-Null

    Restart-Explorer

    Write-Host "Tema padrão restaurado com sucesso." -ForegroundColor Green
}

# ============================================================
# FUNÇÃO: AJUSTAR TAMANHO DOS ÍCONES DA BARRA DE TAREFAS
# ============================================================

function Set-TaskbarIconSize {
    param ([string]$Choice)

    $RegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    switch ($Choice) {
        "1" { $Value = 1; $Label = "Pequenos" }
        "2" { $Value = 0; $Label = "Médios (padrão)" }
        "3" { $Value = 2; $Label = "Grandes" }
        default {
            Write-Host "Opção inválida." -ForegroundColor Red
            return
        }
    }

    reg add $RegPath /v TaskbarSmallIcons /t REG_DWORD /d $Value /f | Out-Null
    Write-Host "Ícones da barra de tarefas definidos como: $Label" -ForegroundColor Green

    Restart-Explorer
}

# ============================================================
# FUNÇÃO AUXILIAR
# ============================================================

function Restart-Explorer {
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

Write-Host "==============================================="
Write-Host "  PERSONALIZAÇÃO DO WINDOWS – TEMA LEVE"
Write-Host "==============================================="
Write-Host
Write-Host "[1] Criar e aplicar tema leve personalizado"
Write-Host "[2] Restaurar tema padrão do Windows"
Write-Host

$MainChoice = Read-Host "Escolha uma opção"

if ($MainChoice -eq "2") {
    Restore-DefaultTheme
    pause
    exit
}

# ============================================================
# PALETA DE CORES (ORDENADA)
# ============================================================

$Colors = @(
    @{ Name="Azul 1"; Value=0x00003BD9 }
    @{ Name="Azul 2"; Value=0x00008BFF }
    @{ Name="Azul 3"; Value=0x0000E6FF }
    @{ Name="Azul 4"; Value=0x0001B9FF }
    @{ Name="Azul 5"; Value=0x001050CA }
    @{ Name="Azul 6"; Value=0x002A4EF8 }
    @{ Name="Azul 7"; Value=0x00000080 }
    @{ Name="Azul 8"; Value=0x002311E8 }
    @{ Name="Azul 9"; Value=0x004444FC }
    @{ Name="Verde 1"; Value=0x00008000 }
    @{ Name="Verde 2"; Value=0x0000CC66 }
    @{ Name="Verde 3"; Value=0x00137A11 }
    @{ Name="Verde 4"; Value=0x003E8614 }
    @{ Name="Verde 5"; Value=0x00202020 }
    @{ Name="Cinza 1"; Value=0x0061737E }
    @{ Name="Cinza 2"; Value=0x00484A4B }
    @{ Name="Cinza 3"; Value=0x00545E52 }
)

$Colors = $Colors | Sort-Object Name
$i = 1
foreach ($c in $Colors) {
    $c.Id = $i
    Write-Host "[$i] $($c.Name)"
    $i++
}

$ColorChoice = Read-Host "Escolha a cor"
$Selected = $Colors | Where-Object { $_.Id -eq [int]$ColorChoice }

if (-not $Selected) {
    Write-Host "Cor inválida." -ForegroundColor Red
    exit
}

# ============================================================
# ESCOLHA DO MODO CLARO / ESCURO
# ============================================================

Write-Host
Write-Host "[1] Tema Claro"
Write-Host "[2] Tema Escuro"
$ThemeChoice = Read-Host "Escolha o modo"

switch ($ThemeChoice) {
    "1" { $AppsTheme = 1; $SystemTheme = 1; $ThemeName = "Tema-Leve-Personalizado" }
    "2" { $AppsTheme = 0; $SystemTheme = 0; $ThemeName = "Tema-Escuro-Personalizado" }
    default { exit }
}

# ============================================================
# TAMANHO DOS ÍCONES
# ============================================================

Write-Host
Write-Host "1 - Ícones pequenos"
Write-Host "2 - Ícones médios"
Write-Host "3 - Ícones grandes"
$IconChoice = Read-Host "Escolha o tamanho"

Set-TaskbarIconSize -Choice $IconChoice

# ============================================================
# CRIAR E APLICAR TEMA
# ============================================================

New-LiteTheme `
    -ThemeName   $ThemeName `
    -AccentColor $Selected.Value `
    -AppsTheme   $AppsTheme `
    -SystemTheme $SystemTheme

Write-Host
Write-Host "Configuração concluída com sucesso." -ForegroundColor Green
pause
