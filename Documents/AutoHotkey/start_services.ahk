; AutoHotkey Services Launcher
; This script automatically starts all .ahk scripts in the services folder
; Place this script in Windows startup to run all services at boot

#Requires AutoHotkey v2.0
#SingleInstance Force

; Get the directory where this script is located
ScriptDir := A_ScriptDir
ServicesDir := ScriptDir . "\services"

; Check if services directory exists
if !DirExist(ServicesDir) {
    MsgBox("Services directory not found: " . ServicesDir, "AutoHotkey Services Launcher", "OK Icon!")
    ExitApp
}

; Loop through all .ahk files in the services directory
ServicesStarted := 0
Loop Files, ServicesDir . "\*.ahk"
{
    try {
        ; Run each AutoHotkey script
        Run('"' . A_LoopFileFullPath . '"')
        ServicesStarted++
    }
    catch as err {
        MsgBox("Failed to start service: " . A_LoopFileName . "`nError: " . err.Message, "Error", "OK Icon!")
    }
}

; Show notification of started services
if (ServicesStarted > 0) {
    TrayTip(ServicesStarted . " service(s) launched successfully.", "AutoHotkey Services Started", 1)
}

; Exit the launcher (the individual services will keep running)
ExitApp

