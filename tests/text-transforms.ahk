#Requires AutoHotkey v2.0
#Include ..\app\awful-cases.ahk

global Failures := 0

AssertEqual(name, actual, expected) {
    global Failures
    if (actual = expected) {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    Failures += 1
    FileAppend("FAIL  " . name . "`n  expected: " . expected . "`n  actual:   " . actual . "`n", "**")
}

AssertTrue(name, value) {
    global Failures
    if value {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    Failures += 1
    FileAppend("FAIL  " . name . "`n  expected truthy value`n", "**")
}

AssertEqual("toggle case", ToggleCase("AbC 123"), "aBc 123")
AssertEqual("title case", TitleCase("hello world"), "Hello World")
AssertEqual("sentence capitalization", SentenceAwareParagraphTypography("hello. world"), "Hello. World")
AssertEqual("ellipsis cleanup", LintText("hello..."), "hello…")
AssertEqual("URL protection", LintText("https://example.com/a--b"), "https://example.com/a--b")
AssertEqual("Windows path protection", LintText("C:\Work\my--file.txt"), "C:\Work\my--file.txt")
AssertEqual("Russian hyphenation through lint", LintText("кое - кто"), "кое‑кто")
AssertEqual("Russian phone normalization", NormalizePhones("+7 999 123 45 67"), "+7 (999) 123-45-67")
AssertEqual("readable hotkey normalization", NormalizeKeyInput("Ctrl+Alt+Shift+PgDn"), "PgDn")
AssertEqual("Russian keyboard hotkey normalization", NormalizeKeyInput("н"), "Y")
AssertTrue("F24 allowed by runtime validator", IsAllowedFinalHotkeyKey("F24"))

try FileDelete(A_ScriptDir . "\awful-cases.ini")

if Failures > 0 {
    FileAppend("`n" . Failures . " test(s) failed.`n", "**")
    ExitApp(1)
}

FileAppend("`nAll characterization tests passed.`n", "*")
ExitApp(0)
