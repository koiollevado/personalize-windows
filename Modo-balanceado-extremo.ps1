<#
.Synopsis
Script interativo para otimizar serviços do Windows e restaurar, preservando redes.
#>

param(
    [string]$LogPath = "$env:LOCALAPPDATATempoptimize_win.log",
    [string]$BackupPath = "$env:ProgramDataOptimizeWinBackup",
    [switch]$Restart
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp`t$Message" | Out-File -FilePath $LogPath -Append -Encoding utf8
    Write-Host $Message
}

function Backup-CurrentState {
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path -Path $BackupPath -ChildPath "services_backup_$date.json"

    $services = Get-WmiObject -Class Win32_Service | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            DisplayName = $_.DisplayName
            StartMode = $_.StartMode
            State = $_.State
        }
    }
    $services | ConvertTo-Json -Depth 3 | Out-File -FilePath $backupFile -Encoding utf8

    Write-Log "Backup salvo em $backupFile"
    return $backupFile
}

function Restore-FromBackup {
    param([string]$BackupFile)
    if (-not (Test-Path $BackupFile)) {
        Write-Log "Arquivo de backup não encontrado: $BackupFile"
        return
    }
    Write-Log "Iniciando restauração do backup: $BackupFile"

    $services = Get-Content $BackupFile | ConvertFrom-Json
    foreach ($svc in $services) {
        try {
            $svcCtrl = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($null -ne $svcCtrl) {
                sc.exe config $svc.Name start= $svc.StartMode | Out-Null
                if ($svc.State -eq 'Running') {
                    Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
                } else {
                    Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                }
                Write-Log "Restauração do serviço $($svc.Name): StartMode=$($svc.StartMode), State=$($svc.State)"
            }
        } catch {
            Write-Log "Erro restaurando $($svc.Name): $_"
        }
    }
    Write-Log "Restauração concluída."
}

function Stop-And-Disable-Service {
    param([string]$Name)
    $s = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $s) { return }

    if ($s.Status -eq 'Running') {
        try {
            Stop-Service -Name $Name -Force -ErrorAction Stop
            Write-Log "Parado: $Name"
        } catch {
            Write-Log "Falha ao parar $Name: $_"
        }
    }

    try {
        sc.exe config $Name start= disabled | Out-Null
        Write-Log "Desabilitado: $Name"
    } catch {
        Write-Log "Falha ao desabilitar $Name: $_"
    }
}

function Apply-Config {
    param([string[]]$ServicesToDisable)

    foreach ($svc in $ServicesToDisable) {
        Stop-And-Disable-Service -Name $svc
    }
}

# Listas de serviços balanceada e extrema sem afetar rede/internet
$ServicesBalanced = @(
    "DiagTrack",
    "SysMain",
    "Fax",
    "WSearch",
    "RetailDemo"
)

$ServicesExtreme = $ServicesBalanced + @(
    "doSvc",
    "PrintNotify",
    "XblAuthManager",
    "XblGameSave",
    "WMPNetworkSvc"
)

# Menu de opções para usuário
function Show-Menu {
    Write-Host ""
    Write-Host "Selecione uma opção:"
    Write-Host "[1] Modo balanceado"
    Write-Host "[2] Modo extremo"
    Write-Host "[3] Modo restauração"
    Write-Host "[s] Sair"
    Write-Host ""
    $choice = Read-Host "Escolha"
    return $choice
}

# Execução interativa
do {
    $option = Show-Menu
    switch ($option.ToLower()) {
        '1' {
            Write-Host "Você escolheu modo balanceado."
            $backupFile = Backup-CurrentState
            $confirm = Read-Host "Deseja aplicar alterações agora? (s/n)"
            if ($confirm.ToLower() -eq 's') {
                Apply-Config -ServicesToDisable $ServicesBalanced
                Write-Log "Configuração balanceada aplicada."
            } else {
                Write-Host "Nenhuma alteração aplicada."
            }
        }
        '2' {
            Write-Host "Você escolheu modo extremo."
            $backupFile = Backup-CurrentState
            $confirm = Read-Host "Deseja aplicar alterações agora? (s/n)"
            if ($confirm.ToLower() -eq 's') {
                Apply-Config -ServicesToDisable $ServicesExtreme
                Write-Log "Configuração extrema aplicada."
            } else {
                Write-Host "Nenhuma alteração aplicada."
            }
        }
        '3' {
            # Restauração - pega último backup
            $latestBackup = Get-ChildItem -Path $BackupPath -Filter "services_backup_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($null -eq $latestBackup) {
                Write-Host "Nenhum arquivo de backup encontrado para restauração."
                Write-Log "Nenhum arquivo backup para restauração"
            } else {
                $confirm = Read-Host "Deseja restaurar a configuração original agora? (s/n)"
                if ($confirm.ToLower() -eq 's') {
                    Restore-FromBackup -BackupFile $latestBackup.FullName
                    Write-Log "Restauração concluída."
                } else {
                    Write-Host "Restauração cancelada."
                }
            }
        }
        's' {
            Write-Host "Saindo..."
            break
        }
        default {
            Write-Host "Opção inválida. Tente novamente."
        }
    }
} while ($option.ToLower() -ne 's')

Write-Host "Script finalizado."
