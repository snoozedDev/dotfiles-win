#Requires AutoHotkey v2.0
#SingleInstance Force
; Remap Capslock to Escape key
; This script converts Capslock key presses to Escape key presses
; Useful for Vim users and general ergonomics

; Set custom tray icon - escape/exit icon
TraySetIcon("shell32.dll", 16) ; Exit/escape icon

; Remap Capslock to Escape
CapsLock::Esc

; Optional: Show notification when script starts (uncomment if desired)
; TrayTip("Capslock remapped to Escape", "AutoHotkey Service", 1)


