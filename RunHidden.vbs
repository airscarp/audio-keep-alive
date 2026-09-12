Option Explicit
On Error Resume Next

Dim shell
Dim executable
Dim exitCode

Set shell = CreateObject("WScript.Shell")
executable = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%\AudioKeepAlive\AudioKeepAlive.exe")
exitCode = shell.Run(Chr(34) & executable & Chr(34), 0, True)

If Err.Number <> 0 Then
    WScript.Quit 1
End If

WScript.Quit exitCode
