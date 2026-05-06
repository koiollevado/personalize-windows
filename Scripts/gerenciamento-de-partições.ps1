# =====================================================================
# Script: GerenciadorDeParticoes.ps1
# Objetivo: Criar, remover, expandir e listar partições no Windows
# Observação: EXECUTAR COMO ADMINISTRADOR
# Revisado: 2025-11-09 (versão com saída correta)
# =====================================================================

$executando = $true

while ($executando) {
    Clear-Host
    Write-Host "=== GERENCIADOR DE PARTICOES ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Criar nova particao (reduzindo uma existente)"
    Write-Host "2 - Remover e expandir particao existente"
    Write-Host "3 - Listar particoes e volumes"
    Write-Host "0 - Sair"
    $opcao = Read-Host "`nEscolha uma opcao"

    switch ($opcao) {

        # === OPÇÃO 1: CRIAR NOVA PARTIÇÃO ===
        1 {
            Write-Host "`n=== CRIAR NOVA PARTICAO ===" -ForegroundColor Cyan

            # Mostrar discos e partições
            Write-Host "`nDiscos e particoes atuais:" -ForegroundColor Yellow
            Get-Disk | Format-Table Number, FriendlyName, Size, PartitionStyle, OperationalStatus
            Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size | Format-Table

            # Selecionar partição
            $partitionLetter = Read-Host "`nInforme a letra da particao que deseja reduzir (ex: C)"
            $partition = Get-Partition -DriveLetter $partitionLetter -ErrorAction SilentlyContinue

            if (-not $partition) {
                Write-Host "Particao nao encontrada. Retornando ao menu." -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Obter informações do disco e limites de redimensionamento
            $diskNumber = ($partition | Get-Disk).Number
            $supportedSize = Get-PartitionSupportedSize -DriveLetter $partitionLetter

            $partSizeGB = [math]::Round($partition.Size / 1GB, 2)
            $maxReduceGB = [math]::Round(($partition.Size - $supportedSize.SizeMin) / 1GB, 2)

            Write-Host ("Espaco atual da particao {0}: {1} GB" -f $partitionLetter, $partSizeGB)
            Write-Host ("Maximo possivel para reduzir: {0} GB" -f $maxReduceGB)

            # Solicitar tamanho da nova partição
            $newPartSizeGB = Read-Host "Informe o tamanho da nova particao em GB"
            [int64]$newPartSizeGBParsed = 0
            if (-not [int64]::TryParse($newPartSizeGB, [ref]$newPartSizeGBParsed) -or $newPartSizeGBParsed -le 0) {
                Write-Host "Tamanho invalido. Retornando ao menu." -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Cálculos usando Int64
            [int64]$newPartSizeBytes = $newPartSizeGBParsed * 1GB
            [int64]$newPartitionSize = [int64]$partition.Size - $newPartSizeBytes

            if ($newPartitionSize -lt $supportedSize.SizeMin) {
                Write-Host "Espaco insuficiente na particao para reduzir esse valor." -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Reduzir partição existente
            Write-Host ("Reduzindo a particao {0} para liberar {1} GB..." -f $partitionLetter, $newPartSizeGBParsed) -ForegroundColor Yellow
            try {
                Resize-Partition -DriveLetter $partitionLetter -Size $newPartitionSize -ErrorAction Stop
                Write-Host "Particao reduzida com sucesso." -ForegroundColor Green
            } catch {
                Write-Host ("Erro ao reduzir particao: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Atualizar disco e verificar espaço
            Write-Host "`nAguardando atualizacao do disco..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            Update-Disk -Number $diskNumber

            $freeSpace = (Get-Disk -Number $diskNumber).LargestFreeExtent
            if (-not $freeSpace -or $freeSpace -lt $newPartSizeBytes) {
                Write-Host ("Espaco livre real insuficiente ({0} GB disponiveis)." -f [math]::Round($freeSpace/1GB,2)) -ForegroundColor Red
                Write-Host "Tente reduzir menos espaço ou verificar se o redimensionamento ocorreu corretamente." -ForegroundColor Yellow
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Criar nova partição
            Write-Host "`nCriando nova particao..." -ForegroundColor Cyan
            try {
                $newPart = New-Partition -DiskNumber $diskNumber -Size $newPartSizeBytes -AssignDriveLetter -ErrorAction Stop
                Write-Host "Nova particao criada com sucesso." -ForegroundColor Green
            } catch {
                Write-Host ("Erro ao criar particao: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            # Formatá-la
            $label = Read-Host "Informe um rotulo (nome) para a nova particao"
            try {
                Format-Volume -DriveLetter $newPart.DriveLetter -FileSystem NTFS -NewFileSystemLabel $label -Confirm:$false
                Write-Host "Particao formatada com sucesso." -ForegroundColor Green
            } catch {
                Write-Host ("Erro ao formatar nova particao: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }

            # Exibir resultado
            Write-Host "`nNova particao criada e formatada com sucesso!" -ForegroundColor Green
            Get-Partition -DiskNumber $diskNumber | Format-Table DriveLetter, Size, GptType, PartitionNumber
            Read-Host "`nPressione ENTER para voltar ao menu..."
        }

        # === OPÇÃO 2: REMOVER E EXPANDIR PARTIÇÃO ===
        2 {
            Write-Host "`n=== REMOVER E EXPANDIR PARTICAO ===" -ForegroundColor Cyan

            $PartitionToExpand = Read-Host "Informe a letra da unidade a ser expandida (ex: C)"

            Write-Host "`nParticoes disponiveis:" -ForegroundColor Yellow
            Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size, GptType | Format-Table

            Write-Host "`nComo deseja identificar a particao a remover?" -ForegroundColor Yellow
            Write-Host "1 - Pela letra da unidade"
            Write-Host "2 - Pelo rotulo (Label)"
            Write-Host "3 - Pelo tamanho (GB)"
            $option = Read-Host "Escolha 1, 2 ou 3"

            switch ($option) {
                1 {
                    $DriveLetter = Read-Host "Digite a letra da unidade a remover (ex: D)"
                    $part = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
                }
                2 {
                    $Label = Read-Host "Digite o rotulo (nome) da particao a remover"
                    $vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq $Label }
                    if ($vol) {
                        $part = Get-Partition -DriveLetter $vol.DriveLetter
                    }
                }
                3 {
                    $SizeInput = Read-Host "Digite o tamanho aproximado da particao a remover (em GB)"
                    [int64]$SizeInputParsed = 0
                    if (-not [int64]::TryParse($SizeInput, [ref]$SizeInputParsed)) {
                        Write-Host "Valor invalido." -ForegroundColor Red
                        continue
                    }
                    $part = Get-Partition | Where-Object { [math]::Round($_.Size / 1GB, 0) -eq $SizeInputParsed }
                }
                default {
                    Write-Host "Opcao invalida." -ForegroundColor Red
                    continue
                }
            }

            if (-not $part) {
                Write-Host "Particao nao encontrada." -ForegroundColor Red
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            Write-Host "`nParticao selecionada para remocao:" -ForegroundColor Yellow
            $part | Format-List

            $confirm = Read-Host "Tem certeza que deseja REMOVER esta particao? (S/N)"
            if ($confirm -notin @('S','s')) {
                Write-Host "Operacao cancelada." -ForegroundColor Cyan
                Read-Host "Pressione ENTER para voltar ao menu..."
                continue
            }

            $diskNumber = ($part | Get-Disk).Number

            # Remover partição
            Write-Host "`nRemovendo particao..." -ForegroundColor Yellow
            try {
                Remove-Partition -DiskNumber $diskNumber -PartitionNumber $part.PartitionNumber -Confirm:$false -ErrorAction Stop
                Write-Host "Particao removida com sucesso." -ForegroundColor Green
            } catch {
                Write-Host ("Erro ao remover particao: {0}" -f $_.Exception.Message) -ForegroundColor Red
                continue
            }

            Start-Sleep -Seconds 2

            # Expandir a partição desejada
            Write-Host "`nExpandindo particao $PartitionToExpand..." -ForegroundColor Yellow
            try {
                $supportedSize = Get-PartitionSupportedSize -DriveLetter $PartitionToExpand
                Resize-Partition -DriveLetter $PartitionToExpand -Size $supportedSize.SizeMax -ErrorAction Stop
                Write-Host "Particao $PartitionToExpand expandida com sucesso!" -ForegroundColor Green
            } catch {
                Write-Host ("Erro ao expandir particao: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }

            Read-Host "`nPressione ENTER para voltar ao menu..."
        }

        # === OPÇÃO 3: LISTAR PARTIÇÕES E VOLUMES ===
        3 {
            Write-Host "`n=== LISTAR PARTICOES E VOLUMES ===" -ForegroundColor Cyan
            Write-Host "`nParticoes:" -ForegroundColor Yellow
            Get-Partition | Format-Table DiskNumber, PartitionNumber, DriveLetter, Size, GptType
            Write-Host "`nVolumes:" -ForegroundColor Yellow
            Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size
            Read-Host "`nPressione ENTER para voltar ao menu..."
        }

        # === SAIR ===
        0 {
            Write-Host "`nSaindo do gerenciador de particoes..." -ForegroundColor Cyan
            $executando = $false
        }

        default {
            Write-Host "Opcao invalida." -ForegroundColor Red
            Read-Host "Pressione ENTER para voltar ao menu..."
        }
    }

}
