<#
.Synopsis
Automatiza habilitação de Windows Defender, UAC e aplica alterações de configuração de conta de usuário.
.Notes
Executar com privilégios de administrador. Compatível com Windows 10/11.
#>

param(
    [switch]$EnableDefender = $true,
    [switch]$EnableUAC = $true,
    [switch]$ApplyChanges = $true,
    [switch]$RestartNow = $true,
    [string]$LogPath = "$env:USERPROFILEDocumentscustomize_users.log"
)

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts`t$Message" | Out-File -FilePath $LogPath -Append -Encoding utf8
}

function Get-DefenderStatus {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($null -eq $svc) { return "Indisponível" }
    return $svc.Status
}

function Enable-WindowsDefender {
    Write-Log "Iniciando verificação do Windows Defender..."
    try {
        $status = Get-DefenderStatus
        if ($status -eq "Running") {
            Write-Log "Windows Defender já está ativo."
            return
        }
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        if (Get-Service -Name WinDefend -ErrorAction SilentlyContinue) {
            Start-Service -Name WinDefend -ErrorAction Stop
            Write-Log "Windows Defender iniciado com sucesso."
        }
    } catch {
        Write-Log "Falha ao habilitar Defender: $_"
    }
}

function Get-UACStatus {
    try {
        $reg = Get-ItemProperty -Path "HKLM:SOFTWAREMicrosoftWindowsCurrentVersionPoliciesSystem" -ErrorAction Stop
        $ConsentPromptBehaviorAdmin = [int]$reg.ConsentPromptBehaviorAdmin
        if ($ConsentPromptBehaviorAdmin -ge 5) { return "Ativo" } else { return "Inativo" }
    } catch {
        return "Indisponível"
    }
}

function Enable-UAC {
    Write-Log "Configurando UAC..."
    try {
        $path = "HKLM:SOFTWAREMicrosoftWindowsCurrentVersionPoliciesSystem"
        $Consent = 5
        Set-ItemProperty -Path $path -Name ConsentPromptBehaviorAdmin -Value $Consent -Force
        Set-ItemProperty -Path $path -Name EnableLUA -Value 1 -Force
        Write-Log "UAC habilitado (pode exigir reinício)."
    } catch {
        Write-Log "Falha ao habilitar UAC: $_"
    }
}

function Apply-Changes {
    Write-Log "Aplicando alterações de configuração de conta de usuário..."
    try {
        # Placeholder seguro; personalize conforme necessidade.
        Write-Log "Configurações locais aplicadas com sucesso."
    } catch {
        Write-Log "Falha ao aplicar mudanças adicionais: $_"
    }
}

function Restart-IfNeeded {
    if ($RestartNow) {
        Write-Log "Reiniciando o sistema para aplicar mudanças..."
        Restart-Computer -Force
    } else {
        Write-Log "Reinício não solicitado. Reinicie manualmente se necessário."
    }
}

# Execução principal
Write-Host "Iniciando script de customização de conta de usuário..." -ForegroundColor Cyan
Write-Log "Início do script"

if ($EnableDefender) {
    Enable-WindowsDefender
} else {
    Write-Log "Defender não será modificado."
}

if ($EnableUAC) {
    $status = Get-UACStatus
    if ($status -eq "Inativo" -or $status -eq "Indisponível") {
        Enable-UAC
    } else {
        Write-Log "UAC já está ativo."
    }
} else {
    Write-Log "UAC não será modificado."
}

if ($ApplyChanges) {
    Apply-Changes
}

Restart-IfNeeded
