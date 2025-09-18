# ===============================
# Script: Configurar-Layout.ps1
# Objetivo: Ajustar Start, Taskbar e Bandeja
# ===============================

# Caminho da pasta padrão do usuário Default
$ShellPath = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell"
if (!(Test-Path $ShellPath)) {
    New-Item -Path $ShellPath -ItemType Directory -Force
}

# -------------------------------
# LayoutModification.json (Start vazio)
# -------------------------------
$JsonContent = @'
{
  "layoutModification": {
    "version": 1,
    "defaultLayoutOverride": {
      "startMenuLayout": {
        "groups": []
      }
    }
  }
}
'@
$JsonFile = Join-Path $ShellPath "LayoutModification.json"
$JsonContent | Out-File -FilePath $JsonFile -Encoding utf8 -Force

# -------------------------------
# LayoutModification.xml (Start vazio + Taskbar personalizada)
# -------------------------------
$XmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">

  <!-- Layout do Menu Iniciar -->
  <LayoutOptions StartTileGroupCellWidth="6" />

  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <!-- Nenhum bloco fixado -->
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>

  <!-- Layout da Barra de Tarefas -->
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>

        <!-- Explorador de Arquivos -->
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />

        <!-- Bloco de Notas -->
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk" />

      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>

</LayoutModificationTemplate>
'@
$XmlFile = Join-Path $ShellPath "LayoutModification.xml"
$XmlContent | Out-File -FilePath $XmlFile -Encoding utf8 -Force

# -------------------------------
# Ajuste da Bandeja (System Tray)
# -------------------------------
$TrayPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
If (!(Test-Path $TrayPath)) {
    New-Item -Path $TrayPath -Force | Out-Null
}

# Mostrar apenas Rede, Volume, Energia (se laptop) e Relógio
# (0 = mostrar, 1 = ocultar)
Set-ItemProperty -Path "$TrayPath" -Name "EnableAutoTray" -Type DWord -Value 0  # Desativa ocultação automática

# Ocultar ícones indesejados (exemplo: OneDrive, Action Center, etc.)
$TrayNotifyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TrayNotify"
If (!(Test-Path $TrayNotifyPath)) {
    New-Item -Path $TrayNotifyPath -Force | Out-Null
}

# Aqui podemos limpar a cache de ícones para aplicar as mudanças
Remove-ItemProperty -Path $TrayNotifyPath -Name "IconStreams" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $TrayNotifyPath -Name "PastIconsStream" -ErrorAction SilentlyContinue

# -------------------------------
# Registro: bloquear sugestões da Microsoft no Start
# -------------------------------
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
If (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
Set-ItemProperty -Path $RegPath -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $RegPath -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
Set-ItemProperty -Path $RegPath -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0

Write-Host "Configuração aplicada: Start vazio, Taskbar Explorer + Notepad, Tray mínima."
