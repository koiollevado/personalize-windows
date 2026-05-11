# Executar como Administrador

Write-Host "Obtendo quantidade de memória RAM instalada..."

# Memória total em bytes
$ramBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory

# Converter para GB
$ramGB = [Math]::Round($ramBytes / 1GB, 2)

# Converter para KB
$ramKB = [Math]::Floor($ramBytes / 1KB)

Write-Host "RAM instalada: $ramGB GB"
Write-Host "Valor para SvcHostSplitThresholdInKB: $ramKB"

# Caminho do registro
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control"

# Criar/alterar valor no registro
Set-ItemProperty `
    -Path $regPath `
    -Name "SvcHostSplitThresholdInKB" `
    -Value $ramKB `
    -Type DWord

Write-Host "Registro atualizado com sucesso."

Write-Host "Reiniciando o computador em 10 segundos..."
Start-Sleep -Seconds 10

Restart-Computer -Force
