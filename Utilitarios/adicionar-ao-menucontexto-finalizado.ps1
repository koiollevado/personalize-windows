# ==========================================================
# SCRIPT DE ADIÇÃO / REMOÇÃO DE ITENS DO MENU DE CONTEXTO
# Compatível com PowerShell 5.1 e PowerShell 7+
# ==========================================================

# ---------------------------
# Função auxiliar universal
# ---------------------------
function Add-RegistryItemChecked {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    
    if ($Path -like "HKCR*") {
        $Path = $Path.Replace("HKCR:", "Registry::HKEY_CLASSES_ROOT")
        $Path = $Path.Replace("HKCR", "Registry::HKEY_CLASSES_ROOT")
    }
    
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
}

# ---------------------------
# Verificação de Administrador
# ---------------------------
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    pause
    exit 1
}

# ==========================================================
# FUNÇÕES DE ADIÇÃO
# ==========================================================

# ---------------------------
# PowerShell Cascade
# ---------------------------
function Add-PowerShellCascade {
    $base = "Registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell"
    
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell" -Name "MUIVerb" -Value "Abrir o PowerShell aqui"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell" -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\MenuPowerShell"
    
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell" -Name "MUIVerb" -Value "Abrir o PowerShell aqui"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell" -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\MenuPowerShell"

    # Submenu Normal
    $subOpen = "$base\shell\open"
    $cmdOpen = "$subOpen\command"
    New-Item -Path $subOpen -Force | Out-Null
    New-Item -Path $cmdOpen -Force | Out-Null
    Add-RegistryItemChecked -Path $subOpen -Name "MUIVerb" -Value "Normal"
    Add-RegistryItemChecked -Path $subOpen -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path $cmdOpen -Name "(default)" -Value "powershell.exe -noexit -command Set-Location '%V'"

    # Submenu Elevado
    $subRunas = "$base\shell\runas"
    $cmdRunas = "$subRunas\command"
    New-Item -Path $subRunas -Force | Out-Null
    New-Item -Path $cmdRunas -Force | Out-Null
    Add-RegistryItemChecked -Path $subRunas -Name "MUIVerb" -Value "Elevado"
    Add-RegistryItemChecked -Path $subRunas -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path $subRunas -Name "HasLUAShield" -Value ""
    Add-RegistryItemChecked -Path $cmdRunas -Name "(default)" -Value "powershell.exe -noexit -command Set-Location '%V'"

    # Esconde itens padrão antigos
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\Powershell" -Name "Extended" -Value ""
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\Powershell" -Name "Extended" -Value ""
}

# ---------------------------
# CMD Cascade
# ---------------------------
function Add-CMDCascade {
    $base = "Registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd"
    
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd" -Name "MUIVerb" -Value "Abrir o CMD aqui"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd" -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\MenuCmd"
    
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd" -Name "MUIVerb" -Value "Abrir o CMD aqui"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd" -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\MenuCmd"

    # Submenu Normal
    $subOpen = "$base\shell\open"
    $cmdOpen = "$subOpen\command"
    New-Item -Path $subOpen -Force | Out-Null
    New-Item -Path $cmdOpen -Force | Out-Null
    Add-RegistryItemChecked -Path $subOpen -Name "MUIVerb" -Value "Normal"
    Add-RegistryItemChecked -Path $subOpen -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path $cmdOpen -Name "(default)" -Value "cmd.exe /s /k pushd \"%V\""

    # Submenu Elevado
    $subRunas = "$base\shell\runas"
    $cmdRunas = "$subRunas\command"
    New-Item -Path $subRunas -Force | Out-Null
    New-Item -Path $cmdRunas -Force | Out-Null
    Add-RegistryItemChecked -Path $subRunas -Name "MUIVerb" -Value "Elevado"
    Add-RegistryItemChecked -Path $subRunas -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path $subRunas -Name "HasLUAShield" -Value ""
    Add-RegistryItemChecked -Path $cmdRunas -Name "(default)" -Value "cmd.exe /s /k pushd \"%V\""

    # Esconde itens padrão antigos
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\cmd" -Name "Extended" -Value ""
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\cmd" -Name "Extended" -Value ""
}

# ---------------------------
# Copiar / Mover
# ---------------------------
function Add-CopiarMover {
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\CopiarPara" -Name "(default)" -Value "{C2FBB630-2971-11D1-A18C-00C04FD75D13}"
    Add-RegistryItemChecked -Path "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\MoverPara" -Name "(default)" -Value "{C2FBB631-2971-11D1-A18C-00C04FD75D13}"
}

# ---------------------------
# Painel de Controle
# ---------------------------
function Add-Painel {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\PainelControle"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Painel de Controle"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "control.exe"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "control.exe"
}

# ---------------------------
# Impressoras
# ---------------------------
function Add-Impressoras {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Impressoras"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Impressoras e Dispositivos"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "shell32.dll,222"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "control printers"
}

# ---------------------------
# Desinstalador
# ---------------------------
function Add-Desinstalador {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Desinstalador"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Desinstalador de Programas"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "appwiz.cpl"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "control appwiz.cpl"
}

# ---------------------------
# Limpar e desligar
# ---------------------------
function Add-LimparDesligar {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\LimparDesligar"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Limpar e Desligar"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "shell32.dll,27"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "powershell.exe -File C:\Scripts\limpar.ps1"
}

# ---------------------------
# Desligar PC
# ---------------------------
function Add-Desligar {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DesligarPC"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Desligar"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "shell32.dll,27"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "shutdown /s /t 0"
}

# ---------------------------
# Reiniciar PC
# ---------------------------
function Add-Reiniciar {
    $p = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ReiniciarPC"
    Add-RegistryItemChecked -Path $p -Name "(default)" -Value "Reiniciar"
    Add-RegistryItemChecked -Path $p -Name "Icon" -Value "shell32.dll,238"
    $cmdPath = "$p\command"
    New-Item -Path $cmdPath -Force | Out-Null
    Add-RegistryItemChecked -Path $cmdPath -Name "(default)" -Value "shutdown /r /t 0"
}

# ---------------------------
# Configurações do Windows (submenu completo)
# ---------------------------
function Add-Configuracoes {
    $base = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ConfiguracoesWindows"
    Add-RegistryItemChecked -Path $base -Name "MUIVerb" -Value "Configurações"
    Add-RegistryItemChecked -Path $base -Name "Icon" -Value "shell32.dll,104"
    Add-RegistryItemChecked -Path $base -Name "SubCommands" -Value ""
    
    $sub = "$base\shell"
    New-Item -Path $sub -Force | Out-Null

    function Add-ConfigItem {
        param(
            [string]$KeyName,
            [string]$Label,
            [string]$Uri,
            [string]$Icon = "imageres.dll,148"
        )
        $path = "$sub\$KeyName"
        $cmd = "$path\command"
        New-Item -Path $path -Force | Out-Null
        New-Item -Path $cmd -Force | Out-Null
        Add-RegistryItemChecked -Path $path -Name "MUIVerb" -Value $Label
        Add-RegistryItemChecked -Path $path -Name "Icon" -Value $Icon
        Add-RegistryItemChecked -Path $cmd -Name "(default)" -Value "explorer.exe $Uri"
    }

    Add-ConfigItem -KeyName "01Sistema"       -Label "Sistema"                  -Uri "ms-settings:system"
    Add-ConfigItem -KeyName "02Rede"          -Label "Rede e Internet"         -Uri "ms-settings:network-status"
    Add-ConfigItem -KeyName "03Personalizacao"-Label "Personalização"          -Uri "ms-settings:personalization"
    Add-ConfigItem -KeyName "04Aplicativos"   -Label "Aplicativos"             -Uri "ms-settings:appsfeatures"
    Add-ConfigItem -KeyName "05Bluetooth"     -Label "Bluetooth e Dispositivos" -Uri "ms-settings:bluetooth"
    Add-ConfigItem -KeyName "06DataHora"      -Label "Data e Hora"             -Uri "ms-settings:dateandtime"
    Add-ConfigItem -KeyName "07Contas"        -Label "Contas"                  -Uri "ms-settings:yourinfo"
    Add-ConfigItem -KeyName "08Privacidade"   -Label "Privacidade"             -Uri "ms-settings:privacy"
    Add-ConfigItem -KeyName "09Atualizacao"   -Label "Atualização e Segurança" -Uri "ms-settings:windowsupdate"
}

# ==========================================================
# DESINSTALADOR COMPLETO
# ==========================================================
function Remove-ContextMenuItems {
    $paths = @(
        "Registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell",
        "Registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd",
        "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\CopiarPara",
        "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\MoverPara",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\PainelControle",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Impressoras",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Desinstalador",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\LimparDesligar",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\DesligarPC",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ReiniciarPC",
        "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ConfiguracoesWindows",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\Powershell",
        "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\Powershell",
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\cmd",
        "Registry::HKEY_CLASSES_ROOT\Directory\background\shell\cmd"
    )
    
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "`nTodos os itens foram removidos com sucesso!" -ForegroundColor Green
}

# ==========================================================
# MENU
# ==========================================================
function Show-Menu {
    Clear-Host
    Write-Host "`n===== OPÇÕES DO MENU DE CONTEXTO =====" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [ 1 ]  Abrir o PowerShell" -ForegroundColor Yellow
    Write-Host " [ 2 ]  Abrir o Prompt (CMD)" -ForegroundColor Yellow
    Write-Host " [ 3 ]  Copiar / Mover para..." -ForegroundColor Yellow
    Write-Host " [ 4 ]  Painel de Controle" -ForegroundColor Yellow
    Write-Host " [ 5 ]  Impressoras e Dispositivos" -ForegroundColor Yellow
    Write-Host " [ 6 ]  Desinstalador de Programas" -ForegroundColor Yellow
    Write-Host " [ 7 ]  Limpar e desligar" -ForegroundColor Yellow
    Write-Host " [ 8 ]  Desligar" -ForegroundColor Yellow
    Write-Host " [ 9 ]  Reiniciar" -ForegroundColor Yellow
    Write-Host " [10 ]  Configurações (submenu completo)" -ForegroundColor Yellow
    Write-Host " [11 ]  REMOVER TODOS OS ITENS" -ForegroundColor Red
    Write-Host " [ 0 ]  Sair" -ForegroundColor Yellow
    Write-Host "=====================================`n"
}

# ==========================================================
# MAPA DE AÇÕES
# ==========================================================
$map = @{
    "1"  = "Add-PowerShellCascade"
    "2"  = "Add-CMDCascade"
    "3"  = "Add-CopiarMover"
    "4"  = "Add-Painel"
    "5"  = "Add-Impressoras"
    "6"  = "Add-Desinstalador"
    "7"  = "Add-LimparDesligar"
    "8"  = "Add-Desligar"
    "9"  = "Add-Reiniciar"
    "10" = "Add-Configuracoes"
}

# ==========================================================
# LOOP PRINCIPAL
# ==========================================================
while ($true) {
    Show-Menu
    $choice = Read-Host "Escolha uma opção"
    
    switch ($choice) {
        "0" {
            Write-Host "Saindo..." -ForegroundColor Yellow
            exit
        }
        "11" {
            $confirm = Read-Host "Tem certeza que deseja remover TUDO? (s/n)"
            if ($confirm -eq "s" -or $confirm -eq "S") {
                Remove-ContextMenuItems
                Start-Sleep -Seconds 2
            }
        }
        default {
            if ($map.ContainsKey($choice)) {
                $action = $map[$choice]
                Write-Host "`nVocê escolheu: $action" -ForegroundColor Cyan
                $confirm = Read-Host "Confirmar? (s/n)"
                if ($confirm -eq "s" -or $confirm -eq "S") {
                    & $action
                    Write-Host "Ação concluída com sucesso!" -ForegroundColor Green
                    Start-Sleep -Seconds 2
                }
            } else {
                Write-Host "Opção inválida!" -ForegroundColor Red
                Start-Sleep -Seconds 1.5
            }
        }
    }
}