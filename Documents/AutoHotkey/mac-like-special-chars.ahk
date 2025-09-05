#Requires AutoHotkey v2.0
#SingleInstance Force
; Alt+E for special spanish characters

global AccentMode := false

!e:: { ; Alt+E
    global AccentMode := true
    ; activate for 3s
    SetTimer(() => AccentMode := false, -3000)
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
*n:: {
    global AccentMode := false
    Send("ñ")
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
+n:: {
    global AccentMode := false
    Send("Ñ")
}
#HotIf