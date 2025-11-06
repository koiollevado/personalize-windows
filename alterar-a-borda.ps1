# Alterar-BordaCinza.ps1
# Script para alterar a cor da borda no Windows 10 entre quatro tons de cinza
# Reinicia automaticamente o Explorer após aplicar a nova cor

Write-Host ""
Write-Host "=== Alterar Cor da Borda do Windows ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Escolha um tom de cinza para aplicar:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1) Cinza Claro   - 0xFFD3D3D3"
Write-Host "2) Cinza Médio   - 0xFFA9A9A9"
Write-Host "3) Cinza Escuro  - 0xFF696969"
Write-Host "4) Cinza Neutro  - 0xFFB0B0B0"
Write-Host ""

$escolha = Read-Host "Digite o número da opção desejada (1-4)"

switch ($escolha) {
    1 { $cor = "0xFFD3D3D3"; $nome = "Cinza Claro" }
    2 { $cor = "0xFFA9A9A9"; $nome = "Cinza Médio" }
    3 { $cor = "0xFF696969"; $nome = "Cinza Escuro" }
    4 { $cor = "0xFFB0B0B0"; $nome = "Cinza Neutro" }
    Default {
        Write-Host "Opção inválida. Encerrando script." -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "Aplicando cor da borda: $nome ($cor)..." -ForegroundColor Green

# Caminho no registro
$regPath = "HKCU:\Software\Microsoft\Windows\DWM"

# Aplica a cor
Set-ItemProperty -Path $regPath -Name "AccentColor" -Value ([int]$cor)

Write-Host "Cor aplicada com sucesso!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Reiniciando o Explorer para aplicar as alterações..." -ForegroundColor Yellow

# Reinicia o Explorer automaticamente
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Host ""
Write-Host "Explorer reiniciado. Nova cor da borda aplicada com sucesso!" -ForegroundColor Green
Write-Host ""
