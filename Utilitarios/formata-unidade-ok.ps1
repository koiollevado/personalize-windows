

# ============================================
# Script: Formatador de Discos - Windows
# Requer: PowerShell como Administrador
# ============================================


[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
chcp 65001 | Out-Null


# Verifica se está rodando como administrador
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Execute este script como Administrador."
    exit
}

Clear-Host
Write-Host "=== FORMATADOR DE DISCOS ===" -ForegroundColor Cyan

# Lista discos físicos
$disks = Get-Disk | Where-Object { $_.PartitionStyle -ne 'RAW' -or $_.Size -gt 0 }

if ($disks.Count -eq 0) {
    Write-Error "Nenhum disco encontrado."
    exit
}

Write-Host "`nDiscos encontrados:`n"

$index = 1
$diskMap = @{}

foreach ($disk in $disks) {
    $sizeGB = [Math]::Round($disk.Size / 1GB, 2)
    Write-Host "[$index] Disco $($disk.Number) - $sizeGB GB - $($disk.FriendlyName)"
    $diskMap[$index] = $disk.Number
    $index++
}

# Escolha do disco
$choice = Read-Host "`nDigite o NÚMERO do disco que deseja formatar"

if (-not $diskMap.ContainsKey([int]$choice)) {
    Write-Error "Opção inválida."
    exit
}

$diskNumber = $diskMap[[int]$choice]

# Tipo de formatação
Write-Host "`nTipos suportados: FAT32 | NTFS | exFAT"
$fs = Read-Host "Digite o sistema de arquivos"

$fs = $fs.ToUpper()

if ($fs -notin @("FAT32", "NTFS", "EXFAT")) {
    Write-Error "Sistema de arquivos inválido."
    exit
}

# Confirmação final
Write-Host "`n⚠️  ATENÇÃO!"
Write-Host "TODOS os dados do Disco $diskNumber serão APAGADOS."
$confirm = Read-Host "Digite SIM para confirmar"

if ($confirm -ne "SIM") {
    Write-Host "Operação cancelada."
    exit
}

# Executa formatação
try {
    Write-Host "`nLimpando disco..."
    Get-Disk -Number $diskNumber | Set-Disk -IsReadOnly $false
    Get-Disk -Number $diskNumber | Clear-Disk -RemoveData -Confirm:$false

    Write-Host "Criando partição..."
    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter

    Write-Host "Formatando em $fs..."
    Format-Volume -Partition $partition -FileSystem $fs -NewFileSystemLabel "DISCO_FORMATADO" -Confirm:$false

    Write-Host "`n✅ Disco formatado com sucesso!" -ForegroundColor Green
}
catch {
    Write-Error "Erro durante a formatação: $_"
}
