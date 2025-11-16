# ==========================================================
#  SCRIPT DE ADIÇÃO / REMOÇÃO DE ITENS DO MENU DE CONTEXTO
#  Compatível com PowerShell 5.1 e PowerShell 7+
#  Inclui ícones, submenus e loop interativo
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

    if ($Path.StartsWith("HKCR")) {
        $Path = $Path.Replace("HKCR:", "Registry::HKEY_CLASSES_ROOT")
        $Path = $Path.Replace("HKCR", "Registry::HKEY_CLASSES_ROOT")
    }

    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
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

    $subOpen = "$base\shell\open"
    $cmdOpen = "$subOpen\command"
    New-Item -Path $subOpen -Force | Out-Null
    New-Item -Path $cmdOpen -Force | Out-Null
    Add-RegistryItemChecked -Path $subOpen -Name "MUIVerb" -Value "Normal"
    Add-RegistryItemChecked -Path $subOpen -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path $cmdOpen -Name "(default)" -Value "powershell.exe -noexit -command Set-Location '%V'"

    $subRunas = "$base\shell\runas"
    $cmdRunas = "$subRunas\command"
    New-Item -Path $subRunas -Force | Out-Null
    New-Item -Path $cmdRunas -Force | Out-Null
    Add-RegistryItemChecked -Path $subRunas -Name "MUIVerb" -Value "Elevado"
    Add-RegistryItemChecked -Path $subRunas -Name "Icon" -Value "powershell.exe"
    Add-RegistryItemChecked -Path $subRunas -Name "HasLUAShield" -Value ""
    Add-RegistryItemChecked -Path $cmdRunas -Name "(default)" -Value "powershell.exe -noexit -command Set-Location '%V'"

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

    $subOpen = "$base\shell\open"
    $cmdOpen = "$subOpen\command"
    New-Item -Path $subOpen -Force | Out-Null
    New-Item -Path $cmdOpen -Force | Out-Null
    Add-RegistryItemChecked -Path $subOpen -Name "MUIVerb" -Value "Normal"
    Add-RegistryItemChecked -Path $subOpen -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path $cmdOpen -Name "(default)" -Value "cmd.exe /s /k pushd \"%V\""

    $subRunas = "$base\shell\runas"
    $cmdRunas = "$subRunas\command"
    New-Item -Path $subRunas -Force | Out-Null
    New-Item -Path $cmdRunas -Force | Out-Null
    Add-RegistryItemChecked -Path $subRunas -Name "MUIVerb" -Value "Elevado"
    Add-RegistryItemChecked -Path $subRunas -Name "Icon" -Value "cmd.exe"
    Add-RegistryItemChecked -Path $subRunas -Name "HasLUAShield" -Value ""
    Add-RegistryItemChecked -Path $cmdRunas -Name "(default)" -Value "cmd.exe /s /k pushd \"%V\""

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

# ==========================================================
# Configurações do Windows (submenu completo)
# ==========================================================
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

    Add-ConfigItem -KeyName "01Sistema"          -Label "Sistema"                   -Uri "ms-settings:system"
    Add-ConfigItem -KeyName "02Rede"             -Label "Rede e Internet"           -Uri "ms-settings:network-status"
    Add-ConfigItem -KeyName "03Personalizacao"   -Label "Personalização"            -Uri "ms-settings:personalization"
    Add-ConfigItem -KeyName "04Aplicativos"      -Label "Aplicativos"               -Uri "ms-settings:appsfeatures"
    Add-ConfigItem -KeyName "05Bluetooth"        -Label "Bluetooth e Dispositivos"  -Uri "ms-settings:bluetooth"
    Add-ConfigItem -KeyName "06DataHora"         -Label "Data e Hora"               -Uri "ms-settings:dateandtime"
    Add-ConfigItem -KeyName "07Contas"           -Label "Contas"                    -Uri "ms-settings:yourinfo"
    Add-ConfigItem -KeyName "08Privacidade"      -Label "Privacidade"               -Uri "ms-settings:privacy"
    Add-ConfigItem -KeyName "09Atualizacao"      -Label "Atualização e Segurança"   -Uri "ms-settings:windowsupdate"
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
        "Registry::HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "`nTodos os itens foram removidos!" -ForegroundColor Green
}

# ==========================================================
# MENU COM CORES
# ==========================================================
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host " " -ForegroundColor Cyan
    Write-Host "===== OPÇÕES AO MENU DE CONTEXTO =====" -ForegroundColor Cyan
    Write-Host " " -ForegroundColor Cyan
    Write-Host (" [ 1 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Abrir o PowerShell"
    Write-Host (" [ 2 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Abrir o Prompt (CMD)"
    Write-Host (" [ 3 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Copiar / Mover para..."
    Write-Host (" [ 4 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Painel de Controle"
    Write-Host (" [ 5 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Impressoras e Dispositivos"
    Write-Host (" [ 6 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Desinstalador de Programas"
    Write-Host (" [ 7 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Limpar e desligar"
    Write-Host (" [ 8 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Desligar"
    Write-Host (" [ 9 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Reiniciar"
    Write-Host (" [ 10]") -ForegroundColor Yellow -NoNewline; Write-Host "  REMOVER TODOS OS ITENS" -ForegroundColor Red
    Write-Host (" [ 11]") -ForegroundColor Yellow -NoNewline; Write-Host "  Configurações (submenu completo)"
    Write-Host (" [ 0 ]") -ForegroundColor Yellow -NoNewline;  Write-Host "  Sair"

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

# ==========================================================
# MAPA DE AÇÕES
# ==========================================================
$map = @{
    "1" = "Add-PowerShellCascade"
    "2" = "Add-CMDCascade"
    "3" = "Add-CopiarMover"
    "4" = "Add-Painel"
    "5" = "Add-Impressoras"
    "6" = "Add-Desinstalador"
    "7" = "Add-LimparDesligar"
    "8" = "Add-Desligar"
    "9" = "Add-Reiniciar"
    "11" = "Add-Configuracoes"
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

        "10" {
            $confirm = Read-Host "Tem certeza que deseja remover TUDO? (s/n)"
            if ($confirm -eq "s") { 
                Remove-ContextMenuItems
                Write-Host "Ação concluída!" -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        }

        default {
            if ($map.ContainsKey($choice)) {

                $action = $map[$choice]
                Write-Host "`nVocê escolheu: $action"

                $confirm = Read-Host "Confirmar? (s/n)"
                if ($confirm -eq "s") { 
                    & $action
                    Write-Host "Ação concluída!" -ForegroundColor Green
                    Start-Sleep -Seconds 2
                }

            } else {
                Write-Host "Opção inválida!" -ForegroundColor Red
                Start-Sleep -Seconds 1.2
            }
        }
    }

    Clear-Host
}
