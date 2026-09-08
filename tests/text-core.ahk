#Requires AutoHotkey v2.0
#Include ..\app\lib\text-transforms.ahk

global Failures := 0

AssertEqual(name, actual, expected) {
    global Failures
    if (actual == expected) {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    Failures += 1
    FileAppend("FAIL  " . name . "`n  expected: " . expected . "`n  actual:   " . actual . "`n", "**")
}

; This file intentionally includes only the pure core. If the core starts depending on
; tray, GUI, hotkeys, clipboard, or filesystem startup state, this test should stop loading.
AssertEqual("pure core toggles case", ToggleCase("AbC"), "aBc")
AssertEqual("pure core lints prose", LintText("hello,world"), "hello, world")
AssertEqual("pure core protects structured numbers", LintText("v2.0.1 3.14 12:30"), "v2.0.1 3.14 12:30")

if Failures > 0 {
    FileAppend("`n" . Failures . " core test(s) failed.`n", "**")
    ExitApp(1)
}

FileAppend("`nPure transform core loaded and passed without application startup.`n", "*")
ExitApp(0)
