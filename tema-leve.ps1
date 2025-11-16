# ================================
# Tema Leve Windows com Escolha de Cores
# Transparência DESLIGADA
# ================================

Write-Host "===== Tema Leve do Windows ====="
Write-Host "Escolha uma categoria de cor:"
Write-Host "1 - Azul (claro → escuro)"
Write-Host "2 - Verde (claro → escuro)"
Write-Host "3 - Cinza (claro → escuro)"
$opcao = Read-Host "Digite o número da opção desejada"

# Paletas ARGB - 100% opacas (FF)
$cores = @{
    AzulClaro   = "0xFFCCE0FF"
    AzulMedio   = "0xFF99B3FF"
    AzulEscuro  = "0xFF3366CC"

    VerdeClaro  = "0xFFCCFFCC"
    VerdeMedio  = "0xFF66CC66"
    VerdeEscuro = "0xFF2E8B57"

    CinzaClaro  = "0xFFE6E6E6"
    CinzaMedio  = "0xFFB3B3B3"
    CinzaEscuro = "0xFF666666"
}

switch ($opcao) {
    1 {
        Write-Host "Você escolheu: Azul"
        $corEscolhida = $cores["AzulMedio"]
    }
    2 {
        Write-Host "Você escolheu: Verde"
        $corEscolhida = $cores["VerdeMedio"]
    }
    3 {
        Write-Host "Você escolheu: Cinza"
        $corEscolhida = $cores["CinzaMedio"]
    }
    default {
        Write-Host "Opção inválida. Usando Azul Médio."
        $corEscolhida = $cores["AzulMedio"]
    }
}

# Converte ARGB para decimal (Windows usa formato decimal)
$corDecimal = [convert]::ToInt32($corEscolhida, 16)

Write-Host "Aplicando cor: $corEscolhida ($corDecimal)"

# Caminho do Registro
$regPath = "HKCU:\Software\Microsoft\Windows\DWM"
$regPathColors = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"

# Desligar transparência
Set-ItemProperty -Path $regPath -Name "ColorPrevalence" -Value 1
Set-ItemProperty -Path $regPath -Name "EnableTransparency" -Value 0

# Aplicar cor
Set-ItemProperty -Path $regPath       -Name AccentColor       -Value $corDecimal
Set-ItemProperty -Path $regPathColors -Name AccentColorMenu   -Value $corDecimal
Set-ItemProperty -Path $regPathColors -Name StartColorMenu    -Value $corDecimal

# Força a atualização do Explorer
Stop-Process -Name explorer -Force

Write-Host "Tema leve aplicado com sucesso!"
