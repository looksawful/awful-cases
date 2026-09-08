#Requires AutoHotkey v2.0
#Include ..\app\awful-cases.ahk

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
AssertEqual("Russian phone with leading 8", NormalizePhones("8 (999) 123-45-67"), "+7 (999) 123-45-67")
AssertEqual("readable hotkey normalization", NormalizeKeyInput("Ctrl+Alt+Shift+PgDn"), "PgDn")
AssertEqual("Russian keyboard hotkey normalization", NormalizeKeyInput("н"), "Y")
AssertTrue("F24 allowed by runtime validator", IsAllowedFinalHotkeyKey("F24"))

; Regression coverage for audit issues #1, #2, #3 and #6.
AssertEqual("decimal dot is preserved", LintText("3.14"), "3.14")
AssertEqual("decimal comma is preserved", LintText("3,14"), "3,14")
AssertEqual("semantic version is preserved", LintText("v2.0.1"), "v2.0.1")
AssertEqual("IPv4-like value is preserved", LintText("192.168.1.1"), "192.168.1.1")
AssertEqual("time is preserved", LintText("12:30"), "12:30")
AssertEqual("ratio is preserved", LintText("16:9"), "16:9")
AssertEqual("prose punctuation still gains a space", LintText("hello,world"), "hello, world")
AssertEqual("email local-part casing is preserved", NormalizeEmails("User.Name @ Example . COM"), "User.Name@example.com")
AssertEqual("ordinary symbols survive emoji removal", RemoveEmoji("✓ ★ → 😀"), "✓ ★ → ")
AssertEqual("emoji ZWJ sequence is removed cleanly", RemoveEmoji("A👨‍👩‍👧‍👦B"), "AB")
AssertEqual("ambiguous non-Russian phone-like value is preserved", NormalizePhones("415 555 26 71"), "415 555 26 71")
AssertEqual("bare ten-digit number is preserved", NormalizePhones("999 123 45 67"), "999 123 45 67")

try FileDelete(A_ScriptDir . "\awful-cases.ini")

if Failures > 0 {
    FileAppend("`n" . Failures . " test(s) failed.`n", "**")
    ExitApp(1)
}

FileAppend("`nAll text transformation tests passed.`n", "*")
ExitApp(0)
