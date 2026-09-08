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

ContainsValue(values, expected) {
    for value in values {
        if (value = expected) {
            return true
        }
    }
    return false
}

choices := GetHotkeyChoices()
AssertTrue("GUI choices include F24", ContainsValue(choices, "F24"))
AssertTrue("unique hotkeys are accepted", ValidateUniqueHotkeys(Map("Upper", "Up", "Lower", "Down")))
AssertTrue("duplicate hotkeys are rejected", !ValidateUniqueHotkeys(Map("Upper", "Up", "Lower", "Up")))

try FileDelete(A_ScriptDir . "\awful-cases.ini")

if Failures > 0 {
    ExitApp(1)
}

ExitApp(0)
