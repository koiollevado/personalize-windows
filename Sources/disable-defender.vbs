' Mensagem inicial
WScript.Echo "Verificando o arquivo hive do registro SYSTEM recém-criado para desabilitar os serviços do Windows Defender..."

' Criação de objetos
Set fso = CreateObject("Scripting.FileSystemObject")
Set dic = CreateObject("Scripting.Dictionary")

initialized = False

' Função para executar comandos no shell
Function Execute(command)
    WScript.Echo "Comando em execução '" & command & "'"
    
    Set shell = CreateObject("WScript.Shell")
    Set exec = shell.Exec(command)
    
    Do While exec.Status = 0
        WScript.Sleep 100
    Loop

    WScript.Echo exec.StdOut.ReadAll
    WScript.Echo exec.StdErr.ReadAll

    Execute = exec.ExitCode
End Function

' Loop principal
Do
    For Each drive In fso.Drives
        If drive.IsReady Then
            If drive.DriveLetter <> "X" Then
                For Each folder In Array("$Windows.~BT\NewOS\Windows", "Windows")
                    file = fso.BuildPath(fso.BuildPath(drive.RootFolder, folder), "System32\config\SYSTEM")
                    
                    If fso.FileExists(file) And fso.FileExists(file & ".LOG1") And fso.FileExists(file & ".LOG2") Then
                        If Not initialized Then
                            dic.Add file, Nothing
                        ElseIf Not dic.Exists(file) Then
                            Set shell = CreateObject("WScript.Shell")
                            ret = 1

                            ' Tenta carregar o hive até ter sucesso
                            Do
                                WScript.Sleep 500
                                ret = Execute("reg.exe LOAD HKLM\mount " & file)
                            Loop While ret > 0

                            ' Desativa os serviços do Windows Defender
                            For Each service In Array("Sense", "WdBoot", "WdFilter", "WdNisDrv", "WdNisSvc", "WinDefend")
                                ret = Execute("reg.exe ADD HKLM\mount\ControlSet001\Services\" & service & " /v Start /t REG_DWORD /d 4 /f")
                            Next

                            ' Descarrega o hive e finaliza
                            ret = Execute("reg.exe UNLOAD HKLM\mount")
                            WScript.Echo "Arquivo de seção de registro SYSTEM encontrado em '" & file & "'. Esta janela será fechada agora."
                            WScript.Sleep 5000
                            Exit Do
                        End If
                    End If
                Next
            End If
        End If
    Next

    initialized = True
    WScript.Sleep 1000
Loop
