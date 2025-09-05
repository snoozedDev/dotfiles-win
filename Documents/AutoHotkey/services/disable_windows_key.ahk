#Requires AutoHotkey v2.0
#SingleInstance Force
; Disable Windows key when pressed alone
; This script prevents the Windows key from opening the Start menu
; but preserves Windows key combinations (Win+R, Win+L, etc.)

; Disable Left Windows key when pressed alone
LWin::return

; Disable Right Windows key when pressed alone  
RWin::return

; Optional: Show notification when script starts
; TrayTip, Windows Key Disabled, The Windows key has been disabled when pressed alone., 3, 1
