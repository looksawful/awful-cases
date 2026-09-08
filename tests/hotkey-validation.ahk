#Requires AutoHotkey v2.0
#Include ..\app\awful-cases.ahk

global Failures := 0

AssertTrue(name, value) {
    global Failures
    if value {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    Failures += 1
    FileAppend("FAIL  " . name . "`n", "**")
}

source := FileRead(A_ScriptDir . "\..\app\awful-cases.ahk", "UTF-8")

; Runtime accepts F24, so the GUI must expose it as well.
RegExMatch(source, "s)keyChoices := \[(.*?)\]\s*captureLabel :=", &choicesMatch)
AssertTrue("settings GUI choices include F24", choicesMatch && InStr(choicesMatch[1], '"F24"'))

; Duplicate assignments must be validated before registration/save instead of silently overriding callbacks.
AssertTrue("duplicate hotkey validation exists", InStr(source, "ValidateUniqueHotkeys(") > 0)

try FileDelete(A_ScriptDir . "\awful-cases.ini")

if Failures > 0 {
    ExitApp(1)
}

ExitApp(0)
