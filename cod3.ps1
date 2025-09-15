#requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- Funções ----------------
function Enable-DotNetFramework {
    Write-Host "Ativando .NET Framework 3.5..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart
    Write-Host ".NET Framework 3.5 ativado." -ForegroundColor Green
}

function Install-Store {
    Write-Host "Instalando Microsoft Store..." -ForegroundColor Yellow
    Get-AppxPackage -AllUsers Microsoft.WindowsStore | Foreach {
        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
    }
    Write-Host "Microsoft Store instalado/restaurado." -ForegroundColor Green
}

function Uninstall-OneDrive {
    Write-Host "Removendo OneDrive..." -ForegroundColor Yellow
    Stop-Process -Name OneDrive -ErrorAction SilentlyContinue
    Start-Process -FilePath "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
    Start-Process -FilePath "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$env:UserProfile\OneDrive" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$env:LocalAppData\Microsoft\OneDrive" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$env:ProgramData\Microsoft OneDrive" -ErrorAction SilentlyContinue
    Write-Host "OneDrive removido." -ForegroundColor Green
}

function Remove-Bloatware {
    Write-Host "Removendo aplicativos pré-instalados (exceto Microsoft Store e Paint)..." -ForegroundColor Yellow
    $apps = Get-AppxPackage | Where-Object {
        $_.Name -notmatch "Microsoft.WindowsStore" -and
        $_.Name -notmatch "Microsoft.Paint"
    }
    foreach ($app in $apps) {
        try {
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
            Write-Host "Removido: $($app.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "Falha ao remover: $($app.Name)"
        }
    }
}

function Set-DefaultPrivacySettings {
    $reg = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"AllowTelemetry"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"PublishUserActivities"=dword:00000001
"UploadUserActivities"=dword:00000001
'@
    $regFile = "$env:TEMP\privacy_restore.reg"
    $reg | Out-File -Encoding ASCII -FilePath $regFile
    reg import $regFile
    Remove-Item $regFile -Force
    Write-Host "Configurações de privacidade restauradas para padrão." -ForegroundColor Green
}

function Disable-Defender {
    Write-Host "Desativando Windows Defender (Opção Avançada)..." -ForegroundColor Yellow
    Set-MpPreference -DisableRealtimeMonitoring $true
    Write-Host "Windows Defender desativado." -ForegroundColor Green
}

function Disable-UAC {
    Write-Host "Desativando UAC (Opção Avançada)..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
    Write-Host "UAC desativado. Reinicie o sistema para aplicar." -ForegroundColor Green
}

function Disable-Update {
    Write-Host "Desativando Windows Update (Opção Avançada)..." -ForegroundColor Yellow
    Stop-Service wuauserv -Force
    Set-Service wuauserv -StartupType Disabled
    Write-Host "Windows Update desativado." -ForegroundColor Green
}

# ---------------- Interface gráfica ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Configurações do Windows"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(470,300)
$tabControl.Location = New-Object System.Drawing.Point(10,10)

$tabBasic = New-Object System.Windows.Forms.TabPage
$tabBasic.Text = "Básico"

$tabAdvanced = New-Object System.Windows.Forms.TabPage
$tabAdvanced.Text = "Avançado"

$tabControl.TabPages.AddRange(@($tabBasic,$tabAdvanced))
$form.Controls.Add($tabControl)

# ---- Checkboxes Básico ----
$chkDotNet   = New-Object System.Windows.Forms.CheckBox
$chkDotNet.Text = ".NET Framework 3.5"
$chkDotNet.Location = New-Object System.Drawing.Point(20,20)

$chkStore    = New-Object System.Windows.Forms.CheckBox
$chkStore.Text = "Instalar Microsoft Store"
$chkStore.Location = New-Object System.Drawing.Point(20,50)

$chkOneDrive = New-Object System.Windows.Forms.CheckBox
$chkOneDrive.Text = "Remover OneDrive"
$chkOneDrive.Location = New-Object System.Drawing.Point(20,80)

$chkBloat    = New-Object System.Windows.Forms.CheckBox
$chkBloat.Text = "Remover Apps Nativos (exceto Store e Paint)"
$chkBloat.Location = New-Object System.Drawing.Point(20,110)

$chkPrivacy  = New-Object System.Windows.Forms.CheckBox
$chkPrivacy.Text = "Restaurar Configurações de Privacidade"
$chkPrivacy.Location = New-Object System.Drawing.Point(20,140)

$tabBasic.Controls.AddRange(@($chkDotNet,$chkStore,$chkOneDrive,$chkBloat,$chkPrivacy))

# ---- Checkboxes Avançado ----
$chkDefender = New-Object System.Windows.Forms.CheckBox
$chkDefender.Text = "Desativar Windows Defender"
$chkDefender.Location = New-Object System.Drawing.Point(20,20)

$chkUAC = New-Object System.Windows.Forms.CheckBox
$chkUAC.Text = "Desativar UAC"
$chkUAC.Location = New-Object System.Drawing.Point(20,50)

$chkUpdate = New-Object System.Windows.Forms.CheckBox
$chkUpdate.Text = "Desativar Windows Update"
$chkUpdate.Location = New-Object System.Drawing.Point(20,80)

$tabAdvanced.Controls.AddRange(@($chkDefender,$chkUAC,$chkUpdate))

# ---- Botão Executar ----
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Executar Selecionados"
$btnRun.Location = New-Object System.Drawing.Point(180,320)
$btnRun.Size = New-Object System.Drawing.Size(120,30)

$btnRun.Add_Click({
    if ($chkDotNet.Checked)   { Enable-DotNetFramework }
    if ($chkStore.Checked)    { Install-Store }
    if ($chkOneDrive.Checked) { Uninstall-OneDrive }
    if ($chkBloat.Checked)    { Remove-Bloatware }
    if ($chkPrivacy.Checked)  { Set-DefaultPrivacySettings }
    if ($chkDefender.Checked) { Disable-Defender }
    if ($chkUAC.Checked)      { Disable-UAC }
    if ($chkUpdate.Checked)   { Disable-Update }
})

$form.Controls.Add($btnRun)

[void]$form.ShowDialog()
