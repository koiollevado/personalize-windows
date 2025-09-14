<#
.AUTOR: Gerado por assistente (baseado em seu script)
.DESCR: Launcher gráfico com checkboxes — funções integradas (autônomo)
.OBS: Execute COM PERMISSÕES de Administrador
#>

# ---------------- Elevation check ----------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    } catch {
        Write-Error "Este script precisa ser executado como Administrador."
        Exit 1
    }
}

# ---------------- Load UI assemblies ----------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- Helper: pause only if interactive ----------------
function Wait-IfInteractive {
    param([bool]$message = $true)
    if ($Host.Name -ne 'ServerRemoteHost' -and $message) {
        Pause
    }
}

# ---------------- Utility: Test internet connection ----------------
function Test-InternetConnection {
    try {
        $r = Test-Connection -ComputerName www.microsoft.com -Count 1 -Quiet -ErrorAction SilentlyContinue
        return [bool]$r
    } catch { return $false }
}

# ---------------- .NET Framework 3.5 function ----------------
function Enable-DotNetFramework {
    Write-Host "Procurando fonte para .NET Framework 3.5..." -ForegroundColor Yellow
    $sourceFound = $false
    $sourceCabFile = ""
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $driveLetter = "$($drive.Name):"
        $sxsFolderPath = Join-Path $driveLetter "sources\sxs"
        if (Test-Path $sxsFolderPath) {
            Write-Host "Found sources folder at $sxsFolderPath" -ForegroundColor Green
            $cabFile = Get-ChildItem -Path $sxsFolderPath -Filter "*.cab" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "netfx3.*ondemand-package" }
            if ($cabFile) {
                $sourceCabFile = $sxsFolderPath
                $sourceFound = $true
                break
            }
        }
    }

    if ($sourceFound) {
        $dismCommand = "/Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:`"$sourceCabFile`""
        Write-Host "Executando DISM: $dismCommand" -ForegroundColor Yellow
        Start-Process -FilePath dism.exe -ArgumentList $dismCommand -Wait -NoNewWindow
        Write-Host ".NET Framework 3.5 ativado (se a fonte for válida)." -ForegroundColor Green
    } else {
        [System.Windows.Forms.MessageBox]::Show(".NET 3.5: arquivo .cab não encontrado nas unidades. Copie a pasta sources\sxs para uma unidade e tente novamente.","Fonte não encontrada",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}

# ---------------- Install Store (simple) ----------------
function Install-Store {
    if (-not (Test-InternetConnection)) {
        [System.Windows.Forms.MessageBox]::Show("Sem conexão com a internet. Conecte-se e tente novamente.","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    try {
        Write-Host "Tentando reinstalar Microsoft Store..." -ForegroundColor Yellow
        wsreset -i -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Microsoft Store: comando enviado. Aguarde alguns minutos e verifique.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao tentar reinstalar Microsoft Store: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- WinGet installer/helpers ----------------
function Test-WinGetInstalled { try { winget --version | Out-Null; return $true } catch { return $false } }

function Install-WinGetDependencies {
    Write-Host "Instalando dependências do WinGet..." -ForegroundColor Yellow
    $dependencyUrls = @(
        @{Url="https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"; Path=Join-Path $env:TEMP "Microsoft.UI.Xaml.2.8.appx"},
        @{Url="https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"; Path=Join-Path $env:TEMP "Microsoft.VCLibs.140.00.UWPDesktop.x64.appx"}
    )
    foreach ($dep in $dependencyUrls) {
        try {
            Start-BitsTransfer -Source $dep.Url -Destination $dep.Path -TransferType Download -ErrorAction Stop | Out-Null
            Add-AppxPackage -Path $dep.Path -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Falha em baixar/instalar dependência: $($dep.Url)" -ForegroundColor Red
            throw
        }
    }
}

function Install-WinGet {
    if (-not (Test-InternetConnection)) { throw "Sem internet para instalar WinGet." }
    Write-Host "Instalando WinGet..." -ForegroundColor Yellow
    Install-WinGetDependencies
    $wingetDownloadUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $wingetInstallerPath = Join-Path $env:TEMP "WinGetInstaller.msixbundle"
    Start-BitsTransfer -Source $wingetDownloadUrl -Destination $wingetInstallerPath -TransferType Download -ErrorAction Stop
    Add-AppxPackage -Path $wingetInstallerPath -ErrorAction SilentlyContinue
}

function Test-WinGetStatus {
    if (-not (Test-WinGetInstalled)) { Install-WinGet }
    # attempt to upgrade winget package if needed (best-effort)
    try { winget upgrade --id Microsoft.WinGet -e --accept-package-agreements --accept-source-agreements | Out-Null } catch {}
}

function Install-AppWithWinGet {
    param([string]$AppName,[string]$FriendlyName)
    if (-not (Test-InternetConnection)) {
        [System.Windows.Forms.MessageBox]::Show("Sem conexão com a internet para instalar $FriendlyName.","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    Test-WinGetStatus
    try {
        Write-Host "Instalando $FriendlyName via WinGet..." -ForegroundColor Yellow
        $output = winget install --id $AppName -e --silent --accept-package-agreements --accept-source-agreements 2>&1
        if ($output -match "No package found" -or $output -match "No installed package found") {
            [System.Windows.Forms.MessageBox]::Show("Pacote $FriendlyName não encontrado via WinGet.","Aviso",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
        } else {
            [System.Windows.Forms.MessageBox]::Show("$FriendlyName: processo de instalação executado.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao instalar $FriendlyName: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- Remove/Uninstall OneDrive ----------------
function Remove-OneDrive {
    # remove setup files from default user (installation-time)
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\OneDriveSetup.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SysWOW64\OneDriveSetup.exe" -ErrorAction SilentlyContinue
}

function Uninstall-OneDrive {
    try {
        Stop-Process -Force -Name OneDrive -ErrorAction SilentlyContinue | Out-Null
        cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall >nul 2>&1"
        Get-ScheduledTask | Where-Object { $_.TaskName -match 'OneDrive' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        cmd /c "C:\Windows\System32\OneDriveSetup.exe -uninstall >nul 2>&1"
        [System.Windows.Forms.MessageBox]::Show("OneDrive: desinstalação tentada (se aplicável).","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao tentar remover OneDrive: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- Disable Recall (feature) ----------------
function Disable-Recall {
    try { Dism /Online /Disable-Feature /Featurename:Recall /NoRestart | Out-Null } catch {}
}

# ---------------- Apps registry tweaks (prevent reinstallation etc.) ----------------
function Set-AppsRegistry {
    $reg = @'
Windows Registry Editor Version 5.00

; --Application and Feature Restrictions--
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001

; Prevent Dev Home/Outlook auto-installs/removals
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate]
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate]

; Disables Cortana
[HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windows Search]
"AllowCortana"=dword:00000000

; Disables OneDrive KFM opt-in
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive]
"KFMBlockOptIn"=dword:00000001
'@
    $path = Join-Path $env:TEMP "Windows_Apps.reg"
    Set-Content -Path $path -Value $reg -Force
    Regedit.exe /S $path
}

# ---------------- Remove ALL Bloatware (UWP) ----------------
# list taken from your source
$appxPackages = @(
    'Microsoft.Microsoft3DViewer','Microsoft.BingSearch','Microsoft.WindowsCamera','Clipchamp.Clipchamp',
    'Microsoft.WindowsAlarms','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome',
    'MicrosoftCorporationII.MicrosoftFamily','Microsoft.WindowsFeedbackHub','Microsoft.GetHelp',
    'microsoft.windowscommunicationsapps','Microsoft.WindowsMaps','Microsoft.ZuneVideo',
    'Microsoft.BingNews','Microsoft.MicrosoftOfficeHub','Microsoft.Office.OneNote',
    'Microsoft.OutlookForWindows','Microsoft.People','Microsoft.Windows.Photos',
    'Microsoft.PowerAutomateDesktop','MicrosoftCorporationII.QuickAssist','Microsoft.SkypeApp',
    'Microsoft.MicrosoftSolitaireCollection','Microsoft.MicrosoftStickyNotes','MSTeams',
    'Microsoft.Getstarted','Microsoft.Todos','Microsoft.WindowsSoundRecorder','Microsoft.BingWeather',
    'Microsoft.ZuneMusic','Microsoft.WindowsTerminal','Microsoft.Xbox.TCUI','Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay','Microsoft.GamingApp','Microsoft.YourPhone','Microsoft.OneDrive',
    'Microsoft.MixedReality.Portal','Microsoft.ScreenSketch','Microsoft.Windows.Ai.Copilot.Provider',
    'Microsoft.Copilot','Microsoft.Copilot_8wekyb3d8bbwe','Microsoft.WindowsMeetNow','Microsoft.WindowsStore',
    'Microsoft.Paint','Microsoft.MSPaint'
)

$capabilities = @(
    'MathRecognizer','OpenSSH.Client','Microsoft.Windows.PowerShell.ISE','App.Support.QuickAssist',
    'App.StepsRecorder','Media.WindowsMediaPlayer','Microsoft.Windows.WordPad','Microsoft.Windows.MSPaint'
)

function Remove-Apps {
    $confirm = [System.Windows.Forms.MessageBox]::Show("Remover TODOS apps pré-instalados (OneDrive, Teams, etc.)? (irreversível)","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        Write-Host "Removendo apps UWP (melhor esforço)..." -ForegroundColor Yellow
        Get-AppxPackage -AllUsers | Where-Object { $appxPackages -contains $_.Name } | ForEach-Object {
            try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {}
        }
        Get-WindowsCapability -Online | Where-Object { $capabilities -contains ($_.Name -split '~')[0] } | ForEach-Object {
            try { Remove-WindowsCapability -Online -Name $_.Name -ErrorAction SilentlyContinue } catch {}
        }
        Set-AppsRegistry
        Uninstall-OneDrive
        Disable-Recall
        [System.Windows.Forms.MessageBox]::Show("Remoção de apps finalizada (se aplicável).","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao remover apps: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- Windows Defender control ----------------
function Disable-WindowsDefender {
    $r = [System.Windows.Forms.MessageBox]::Show("Tem certeza que deseja DESATIVAR o Windows Defender?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Defender" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        $svcNames = @("WinDefend","Sense")
        foreach ($s in $svcNames) {
            if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
                try { Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue } catch {}
                try { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
        Get-ScheduledTask -TaskName "*Windows Defender*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Windows Defender: alterações aplicadas. Reinicie para completar.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao desativar Defender: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Enable-WindowsDefender {
    $r = [System.Windows.Forms.MessageBox]::Show("Deseja ATIVAR o Windows Defender?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    try {
        if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Defender") {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        }
        if (Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue) {
            Set-Service -Name "WinDefend" -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue
        }
        [System.Windows.Forms.MessageBox]::Show("Windows Defender: ativado.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao ativar Defender: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- UAC control ----------------
function Disable-UAC {
    $r = [System.Windows.Forms.MessageBox]::Show("Desabilitar UAC reduz a segurança. Continuar?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    try {
        cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f | Out-Null
        cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f | Out-Null
        [System.Windows.Forms.MessageBox]::Show("UAC desativado. Reinicie para aplicar.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao desativar UAC: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Enable-UAC {
    $r = [System.Windows.Forms.MessageBox]::Show("Ativar UAC?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    try {
        cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f | Out-Null
        cmd.exe /c reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f | Out-Null
        [System.Windows.Forms.MessageBox]::Show("UAC ativado.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao ativar UAC: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- Windows Update control ----------------
function Disable-WindowsUpdate {
    $r = [System.Windows.Forms.MessageBox]::Show("Desativar Windows Update pode deixar sistema sem atualizações de segurança. Continuar?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        if (Get-Service -Name wuauserv -ErrorAction SilentlyContinue) { Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue; Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue }
        if (Get-Service -Name BITS -ErrorAction SilentlyContinue) { Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue; Set-Service -Name BITS -StartupType Disabled -ErrorAction SilentlyContinue }
        [System.Windows.Forms.MessageBox]::Show("Windows Update desativado (melhor esforço). Reinicie para garantir.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao desativar Windows Update: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Enable-WindowsUpdate {
    $r = [System.Windows.Forms.MessageBox]::Show("Reativar Windows Update?","Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    try {
        if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU") {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -ErrorAction SilentlyContinue
        }
        if (Get-Service -Name wuauserv -ErrorAction SilentlyContinue) { Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name wuauserv -ErrorAction SilentlyContinue }
        if (Get-Service -Name BITS -ErrorAction SilentlyContinue) { Set-Service -Name BITS -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name BITS -ErrorAction SilentlyContinue }
        [System.Windows.Forms.MessageBox]::Show("Windows Update reativado.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao ativar Windows Update: $_","Erro",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ---------------- Recommended Windows Update (reg file) ----------------
function Set-RecommendedUpdateSettings {
    $reg = @'
Windows Registry Editor Version 5.00

; --Windows Update Settings--
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoUpdate"=dword:00000001
"AUOptions"=dword:00000002
"AutoInstallMinorUpdates"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"TargetReleaseVersion"=dword:00000001
"TargetReleaseVersionInfo"="22H2"
"ProductVersion"="Windows 10"
"DeferFeatureUpdates"=dword:00000001
"DeferFeatureUpdatesPeriodInDays"=dword:0000016d
"DeferQualityUpdates"=dword:00000001
"DeferQualityUpdatesPeriodInDays"=dword:00000007

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization]
"DODownloadMode"=dword:00000000
'@
    $p = Join-Path $env:TEMP "Recommended_Windows_Update_Settings.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Configurações recomendadas de Windows Update aplicadas.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Set-DefaultUpdateSettings {
    $reg = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoUpdate"=-
"AUOptions"=-
"AutoInstallMinorUpdates"=-

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"TargetReleaseVersion"=-
"TargetReleaseVersionInfo"=-
"ProductVersion"=-
"DeferFeatureUpdates"=-
"DeferFeatureUpdatesPeriodInDays"=-
"DeferQualityUpdates"=-
"DeferQualityUpdatesPeriodInDays"=-

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization]
"DODownloadMode"=-
'@
    $p = Join-Path $env:TEMP "Default_Windows_Update_Settings.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Windows Update: restaurado ao padrão.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# ---------------- Registry optimizations (HKLM) ----------------
function Set-RecommendedHKLMRegistry {
    $reg = @'
Windows Registry Editor Version 5.00

; Example optimizations (taken from original)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem]
"LongPathsEnabled"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"SystemResponsiveness"=dword:00000000
"NetworkThrottlingIndex"=dword:0000000a

; Disable startup sound
[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation]
"DisableStartupSound"=dword:00000001

; Hide Meet Now
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
"HideSCAMeetNow"=dword:00000001

'@
    $p = Join-Path $env:TEMP "Optimize_LocalMachine_Registry.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Otimizações HKLM aplicadas.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Set-DefaultHKLMRegistry {
    $reg = @'
Windows Registry Editor Version 5.00

; Revert sample keys to defaults (as needed)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem]
"LongPathsEnabled"=dword:00000000
'@
    $p = Join-Path $env:TEMP "Restore_LocalMachine_Registry.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("HKLM restaurado ao padrão (algumas chaves).","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# ---------------- Registry optimizations (HKCU) ----------------
function Set-RecommendedHKCURegistry {
    # Set wallpaper helper
    function Set-Wallpaper ($wallpaperPath) {
        reg.exe add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$wallpaperPath" /f | Out-Null
        rundll32.exe user32.dll, UpdatePerUserSystemParameters
    }
    $defaultWallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img0_3840x2160.jpg"
    $darkModeWallpaperPath = "C:\Windows\Web\4K\Wallpaper\Windows\img19_1920x1200.jpg"
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    if ($build -ge 22000 -and (Test-Path $darkModeWallpaperPath)) { Set-Wallpaper -wallpaperPath $darkModeWallpaperPath } else { Set-Wallpaper -wallpaperPath $defaultWallpaperPath }

    $reg = @'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"LaunchTo"=dword:00000001
"HideFileExt"=dword:00000000
"ShowPreviewHandlers"=dword:00000000
"ShowStatusBar"=dword:00000000
"ShowSyncProviderNotifications"=dword:00000000
"TaskbarAnimations"=dword:0
"ShowTaskViewButton"=dword:00000000
"ShowCopilotButton"=dword:00000000
'@
    $p = Join-Path $env:TEMP "Optimize_User_Registry.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Otimizações HKCU aplicadas (usuário atual).","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Set-DefaultHKCURegistry {
    $reg = @'
Windows Registry Editor Version 5.00

[-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
'@
    $p = Join-Path $env:TEMP "Restore_User_Registry.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("HKCU restaurado (algumas chaves).","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# ---------------- Recommended Privacy Settings ----------------
function Set-RecommendedPrivacySettings {
    $reg = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"EnableActivityFeed"=dword:00000000
"PublishUserActivities"=dword:00000000
"UploadUserActivities"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location]
"Value"="Deny"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}]
"SensorPermissionState"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration]
"Status"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection]
"AllowTelemetry"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"AllowTelemetry"=dword:00000000
"DoNotShowFeedbackNotifications"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace]
"AllowWindowsInkWorkspace"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo]
"DisabledByGroupPolicy"=dword:00000001
'@
    $p = Join-Path $env:TEMP "Recommended_Privacy_Settings.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Configurações de privacidade recomendadas aplicadas.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

function Set-DefaultPrivacySettings {
    $reg = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"EnableActivityFeed"=-
"PublishUserActivities"=-
"UploadUserActivities"=-
'@
    $p = Join-Path $env:TEMP "Default_Privacy_Settings.reg"
    Set-Content -Path $p -Value $reg -Force
    Regedit.exe /S $p
    [System.Windows.Forms.MessageBox]::Show("Privacidade: restaurado ao padrão (algumas chaves).","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

# ---------------- UI: helper to add checkbox groups ----------------
function Add-CheckboxGroup {
    param (
        [string]$title,
        [string[]]$items,
        [int]$yStart
    )
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = $title
    $groupBox.Location = New-Object System.Drawing.Point(10,$yStart)
    $groupBox.Size = New-Object System.Drawing.Size(460,($items.Count * 25 + 30))
    $form.Controls.Add($groupBox)

    $checkboxes = @{}
    $y = 20
    foreach ($item in $items) {
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = $item
        $chk.Location = New-Object System.Drawing.Point(15,$y)
        $chk.AutoSize = $true
        $groupBox.Controls.Add($chk)
        $checkboxes[$item] = $chk
        $y += 25
    }
    return $checkboxes
}

# ---------------- Build UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Central de Ajustes Windows (Standalone)"
$form.Size = New-Object System.Drawing.Size(500,720)
$form.StartPosition = "CenterScreen"

$funcionalidades = Add-CheckboxGroup -title "Funcionalidades do Windows" -items @(
    "Habilitar .NET Framework 3.5",
    "Remover OneDrive",
    "Remover Apps Bloatware"
) -yStart 10

$privacidade = Add-CheckboxGroup -title "Privacidade & Segurança" -items @(
    "Aplicar Configurações de Privacidade Recomendadas",
    "Ativar Windows Defender",
    "Desativar Windows Defender",
    "Ativar UAC",
    "Desativar UAC"
) -yStart 120

$updates = Add-CheckboxGroup -title "Atualizações" -items @(
    "Aplicar Ajustes Recomendados de Windows Update",
    "Voltar ao Padrão do Windows Update",
    "Desativar Windows Update",
    "Ativar Windows Update"
) -yStart 260

$otimizacao = Add-CheckboxGroup -title "Otimização" -items @(
    "Otimizar Registro (HKLM + HKCU)",
    "Configurações de Energia (Desempenho)"
) -yStart 380

$apps = Add-CheckboxGroup -title "Instalação de Apps (WinGet)" -items @(
    "Firefox","Chrome","Brave","Edge","Thorium","Microsoft Store","UniGetUI"
) -yStart 460

# ---------------- Mapping ----------------
$mapaFuncoes = @{
    "Habilitar .NET Framework 3.5" = { Enable-DotNetFramework }
    "Remover OneDrive"             = { Uninstall-OneDrive }
    "Remover Apps Bloatware"       = { Remove-Apps }

    "Aplicar Configurações de Privacidade Recomendadas" = { Set-RecommendedPrivacySettings }
    "Ativar Windows Defender"     = { Enable-WindowsDefender }
    "Desativar Windows Defender"  = { Disable-WindowsDefender }
    "Ativar UAC"                  = { Enable-UAC }
    "Desativar UAC"               = { Disable-UAC }

    "Aplicar Ajustes Recomendados de Windows Update" = { Set-RecommendedUpdateSettings }
    "Voltar ao Padrão do Windows Update"             = { Set-DefaultUpdateSettings }
    "Desativar Windows Update"                       = { Disable-WindowsUpdate }
    "Ativar Windows Update"                         = { Enable-WindowsUpdate }

    "Otimizar Registro (HKLM + HKCU)" = { Set-RecommendedHKLMRegistry; Set-RecommendedHKCURegistry }
    "Configurações de Energia (Desempenho)" = { 
        # Placeholder: if you have Set-RecommendedPowerSettings function add here; otherwise inform user
        [System.Windows.Forms.MessageBox]::Show("Configurações de energia: função não implementada (adicione Set-RecommendedPowerSettings se desejar).","Aviso")
    }

    "Firefox" = { Install-AppWithWinGet -AppName "Mozilla.Firefox" -FriendlyName "Mozilla Firefox" }
    "Chrome"  = { Install-AppWithWinGet -AppName "Google.Chrome" -FriendlyName "Google Chrome" }
    "Brave"   = { Install-AppWithWinGet -AppName "Brave.Brave" -FriendlyName "Brave Browser" }
    "Edge"    = { Install-AppWithWinGet -AppName "Microsoft.Edge" -FriendlyName "Microsoft Edge" }
    "Thorium" = { Install-AppWithWinGet -AppName "Alex313031.Thorium" -FriendlyName "Thorium Browser" }
    "Microsoft Store" = { Install-Store }
    "UniGetUI" = { Install-AppWithWinGet -AppName "MartiCliment.UniGetUI" -FriendlyName "UniGetUI (Software Manager)" }
}

# ---------------- Apply / Execute Button ----------------
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "Aplicar Selecionados"
$okButton.Location = New-Object System.Drawing.Point(120,640)
$okButton.Size = New-Object System.Drawing.Size(120,30)
$okButton.Add_Click({
    $selections = @()
    foreach ($group in @($funcionalidades,$privacidade,$updates,$otimizacao,$apps)) {
        foreach ($k in $group.Keys) { if ($group[$k].Checked) { $selections += $k } }
    }
    if ($selections.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhuma opção selecionada.","Aviso")
        return
    }

    $summary = "Você selecionou:`n" + ($selections -join "`n") + "`n`nDeseja continuar?"
    $resp = [System.Windows.Forms.MessageBox]::Show($summary,"Confirmar execução",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    foreach ($item in $selections) {
        try {
            Write-Host "Executando: $item" -ForegroundColor Cyan
            if ($mapaFuncoes.ContainsKey($item)) {
                & $mapaFuncoes[$item]
            } else {
                Write-Host "Função não mapeada para: $item" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Erro executando $item : $_" -ForegroundColor Red
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Execução concluída. Algumas alterações podem exigir reinício.","Concluído",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

$form.Controls.Add($okButton)

# ---------------- Close Button ----------------
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Fechar"
$cancelButton.Location = New-Object System.Drawing.Point(260,640)
$cancelButton.Size = New-Object System.Drawing.Size(120,30)
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

# ---------------- Show UI ----------------
$form.ShowDialog()
