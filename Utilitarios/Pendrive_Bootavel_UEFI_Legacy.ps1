# =========================================================
# Pendrive_Bootavel_UEFI_Legacy.ps1
# Cria pendrive bootável BIOS + UEFI
# =========================================================

#Requires -RunAsAdministrator

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Clear-Host

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   CRIADOR DE PENDRIVE BOOTÁVEL UEFI + LEGACY"
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# =========================================================
# SELECIONAR ISO
# =========================================================

Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "Arquivos ISO (*.iso)|*.iso"
$dialog.Title = "Selecione a imagem ISO do Windows"

if ($dialog.ShowDialog() -ne "OK") {
    Write-Host "Nenhuma ISO selecionada." -ForegroundColor Red
    exit
}

$isoPath = $dialog.FileName

Write-Host ""
Write-Host "ISO selecionada:" -ForegroundColor Yellow
Write-Host $isoPath
Write-Host ""

# =========================================================
# OBTER TAMANHO DA ISO
# =========================================================

$isoSizeBytes = (Get-Item $isoPath).Length
$isoSizeGB = [math]::Round($isoSizeBytes / 1GB, 2)

Write-Host "Tamanho da ISO: $isoSizeGB GB" -ForegroundColor Cyan
Write-Host ""

# =========================================================
# LISTAR DISCOS USB
# =========================================================

Write-Host "Dispositivos removíveis disponíveis:" -ForegroundColor Yellow
Write-Host ""

$usbDisks = Get-Disk | Where-Object {
    $_.BusType -eq 'USB'
}

if (!$usbDisks) {
    Write-Host "Nenhum pendrive encontrado." -ForegroundColor Red
    exit
}

$usbDisks | Format-Table `
    Number,
    FriendlyName,
    @{Name="Tamanho(GB)";Expression={[math]::Round($_.Size/1GB,2)}},
    PartitionStyle,
    OperationalStatus -AutoSize

Write-Host ""

# =========================================================
# ESCOLHER DISCO
# =========================================================

$diskNumber = Read-Host "Digite o NÚMERO do disco USB"

$selectedDisk = Get-Disk -Number $diskNumber -ErrorAction SilentlyContinue

if (!$selectedDisk) {
    Write-Host "Disco inválido." -ForegroundColor Red
    exit
}

if ($selectedDisk.BusType -ne 'USB') {
    Write-Host "O disco selecionado não é USB." -ForegroundColor Red
    exit
}

# =========================================================
# VERIFICAR ESPAÇO
# =========================================================

if ($selectedDisk.Size -lt $isoSizeBytes) {
    Write-Host ""
    Write-Host "ERRO: O pendrive não possui espaço suficiente." -ForegroundColor Red
    Write-Host ""
    Write-Host "ISO:      $isoSizeGB GB"
    Write-Host "Pendrive: $([math]::Round($selectedDisk.Size / 1GB,2)) GB"
    exit
}

Write-Host ""
Write-Host "ATENÇÃO!" -ForegroundColor Yellow
Write-Host "TODOS os dados do disco $diskNumber serão APAGADOS."
Write-Host ""

$confirm = Read-Host "Digite SIM para continuar"

if ($confirm -ne "SIM") {
    Write-Host "Operação cancelada."
    exit
}

# =========================================================
# MONTAR ISO
# =========================================================

Write-Host ""
Write-Host "Montando ISO..." -ForegroundColor Cyan

$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru

Start-Sleep 3

$isoDriveLetter = (
    Get-Volume |
    Where-Object {
        $_.DriveType -eq 'CD-ROM'
    } |
    Sort-Object DriveLetter |
    Select-Object -Last 1
).DriveLetter

if (!$isoDriveLetter) {
    Write-Host "Falha ao montar ISO." -ForegroundColor Red
    exit
}

$isoDrive = "$isoDriveLetter`:"
Write-Host "ISO montada em $isoDrive"
Write-Host ""

# =========================================================
# PREPARAR DISKPART
# =========================================================

$tempDiskpart = "$env:TEMP\pendrive_boot.txt"

@"
select disk $diskNumber
clean
convert mbr
create partition primary
format fs=fat32 quick label=BOOT
active
assign
exit
"@ | Set-Content -Path $tempDiskpart -Encoding ASCII

Write-Host "Formatando pendrive..." -ForegroundColor Cyan

diskpart /s $tempDiskpart

Start-Sleep 3

# =========================================================
# OBTER LETRA DO PENDRIVE
# =========================================================

$usbLetter = (
    Get-Partition -DiskNumber $diskNumber |
    Get-Volume |
    Where-Object { $_.DriveLetter } |
    Select-Object -First 1
).DriveLetter

if (!$usbLetter) {
    Write-Host "Falha ao detectar letra do pendrive." -ForegroundColor Red
    exit
}

$usbDrive = "$usbLetter`:"

Write-Host ""
Write-Host "Pendrive preparado em $usbDrive"
Write-Host ""

# =========================================================
# COPIAR ARQUIVOS
# =========================================================

Write-Host "Copiando arquivos..." -ForegroundColor Cyan
Write-Host ""

# Detecta install.wim maior que 4GB
$installWim = "$isoDrive\sources\install.wim"

if (Test-Path $installWim) {

    $wimSize = (Get-Item $installWim).Length

    if ($wimSize -gt 4GB) {

        Write-Host "install.wim maior que 4GB detectado." -ForegroundColor Yellow
        Write-Host "Dividindo imagem para FAT32..." -ForegroundColor Yellow

        robocopy $isoDrive $usbDrive /E /XF install.wim

        New-Item -ItemType Directory -Path "$usbDrive\sources" -Force | Out-Null

        dism /Split-Image `
            /ImageFile:$installWim `
            /SWMFile:"$usbDrive\sources\install.swm" `
            /FileSize:3800

    }
    else {

        robocopy $isoDrive $usbDrive /E

    }

}
else {

    robocopy $isoDrive $usbDrive /E

}

# =========================================================
# BOOT LEGACY
# =========================================================

$bootsect = "$isoDrive\boot\bootsect.exe"

if (Test-Path $bootsect) {

    Write-Host ""
    Write-Host "Aplicando boot BIOS/Legacy..." -ForegroundColor Cyan

    & $bootsect /nt60 $usbDrive /mbr

}

# =========================================================
# DESMONTAR ISO
# =========================================================

Dismount-DiskImage -ImagePath $isoPath

# =========================================================
# FINALIZAÇÃO
# =========================================================

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host " Pendrive bootável criado com sucesso!"
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Modo suportado:"
Write-Host "- UEFI"
Write-Host "- BIOS Legacy"
Write-Host ""

Pause 
