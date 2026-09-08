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

; Issue #1: punctuation cleanup must not corrupt structured numeric tokens.
AssertEqual("decimal dot preserved", LintText("3.14"), "3.14")
AssertEqual("decimal comma preserved", LintText("3,14"), "3,14")
AssertEqual("semantic version preserved", LintText("v2.0.1"), "v2.0.1")
AssertEqual("IPv4 preserved", LintText("192.168.1.1"), "192.168.1.1")
AssertEqual("time preserved", LintText("12:30"), "12:30")
AssertEqual("prose punctuation spacing retained", LintText("hello!world"), "hello! world")

; Issue #2: preserve email local-part casing while normalizing domain and spaces.
AssertEqual("email local part casing preserved", NormalizeEmails("User.Name @ Example . COM"), "User.Name@example.com")
AssertEqual("normalized email remains stable", NormalizeEmails("User.Name@example.com"), "User.Name@example.com")
AssertEqual("lint preserves normalized email local part", LintText("User.Name @ Example . COM"), "User.Name@example.com")

; Issue #3: emoji removal must not erase ordinary typographic symbols.
AssertEqual("check mark preserved by emoji cleanup", RemoveEmoji("✓"), "✓")
AssertEqual("arrow preserved by emoji cleanup", RemoveEmoji("→"), "→")
AssertEqual("star preserved by emoji cleanup", RemoveEmoji("★"), "★")
AssertEqual("supplementary emoji removed", RemoveEmoji("A😀B"), "AB")
AssertEqual("ZWJ emoji sequence removed", RemoveEmoji("A👩‍💻B"), "AB")
AssertEqual("lint preserves ordinary symbols", LintText("✓ → ★"), "✓ → ★")

; Issue #6: only explicit Russian phone forms should be coerced to +7.
AssertEqual("Russian +7 phone normalized", NormalizePhones("+7 999 123 45 67"), "+7 (999) 123-45-67")
AssertEqual("Russian leading 8 phone normalized", NormalizePhones("8 (999) 123-45-67"), "+7 (999) 123-45-67")
AssertEqual("ambiguous 10 digit groups preserved", NormalizePhones("415 555 12 34"), "415 555 12 34")
AssertEqual("unprefixed Russian-looking groups preserved", NormalizePhones("999 123 45 67"), "999 123 45 67")

try FileDelete(A_ScriptDir . "\awful-cases.ini")

if Failures > 0 {
    FileAppend("`n" . Failures . " test(s) failed.`n", "**")
    ExitApp(1)
}

FileAppend("`nAll characterization tests passed.`n", "*")
ExitApp(0)
