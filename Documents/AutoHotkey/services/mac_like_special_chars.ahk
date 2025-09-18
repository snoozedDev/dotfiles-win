#Requires AutoHotkey v2.0
#SingleInstance Force
; Alt+E for vowels with accents, Alt+N for ñ

; Set custom tray icon - keyboard/language icon
TraySetIcon("shell32.dll", 174) ; Keyboard icon

global AccentMode := false
global EnneMode := false

!e:: { ; Alt+E for vowels
    global AccentMode := true
    ; activate for 3s
    SetTimer(() => AccentMode := false, -3000)
}

!n:: { ; Alt+N for ñ
    global EnneMode := true
    ; activate for 3s
    SetTimer(() => EnneMode := false, -3000)
}

#HotIf AccentMode
*a:: {
    global AccentMode := false
    Send("á")
}
*e:: {
    global AccentMode := false
    Send("é")
}
*i:: {
    global AccentMode := false
    Send("í")
}
*o:: {
    global AccentMode := false
    Send("ó")
}
*u:: {
    global AccentMode := false
    Send("ú")
}
+a:: {
    global AccentMode := false
    Send("Á")
}
+e:: {
    global AccentMode := false
    Send("É")
}
+i:: {
    global AccentMode := false
    Send("Í")
}
+o:: {
    global AccentMode := false
    Send("Ó")
}
+u:: {
    global AccentMode := false
    Send("Ú")
}
#HotIf

#HotIf EnneMode
*n:: {
    global EnneMode := false
    Send("ñ")
}
+n:: {
    global EnneMode := false
    Send("Ñ")
}
#HotIf