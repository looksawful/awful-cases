#Requires AutoHotkey v2.0
#Include lib\assert.ahk
#Include ..\app\awful-cases.ahk

source := FileRead(A_ScriptDir . "\..\app\awful-cases.ahk", "UTF-8")

AssertEqual("readable hotkey normalization", NormalizeKeyInput("Ctrl+Alt+Shift+PgDn"), "PgDn")
AssertEqual("Russian keyboard hotkey normalization", NormalizeKeyInput("н"), "Y")
AssertTrue("F24 allowed by runtime validator", IsAllowedFinalHotkeyKey("F24"))

; Runtime accepts F24, so the GUI must either reuse the shared allowed-key array
; or expose F24 explicitly.
usesSharedChoices := InStr(source, "keyChoices := AllowedFinalHotkeyKeys") > 0
RegExMatch(source, "s)keyChoices := \[(.*?)\]\s*captureLabel :=", &choicesMatch)
hasLiteralF24 := choicesMatch && InStr(choicesMatch[1], '"F24"')
AssertTrue("settings GUI choices include F24", usesSharedChoices || hasLiteralF24)

; Duplicate assignments must be validated before registration/save instead of silently overriding callbacks.
AssertTrue("duplicate hotkey validation exists", InStr(source, "ValidateUniqueHotkeys(") > 0)

try FileDelete(A_ScriptDir . "\awful-cases.ini")
FinishTests("hotkey validation tests")
