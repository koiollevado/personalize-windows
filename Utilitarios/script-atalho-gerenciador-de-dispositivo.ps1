$TargetFile = "$env:SystemRoot\System32\devmgmt.msc"
$ShortcutFile = "$env:USERPROFILE\Desktop\Gerenciador de Dispositivos.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()