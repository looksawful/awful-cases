#Requires AutoHotkey v2.0
#Include lib\assert.ahk
#Include ..\app\lib\text-transforms.ahk

; The harness must remain case-sensitive. This catches the exact class of regression that
; previously let email/case bugs pass when tests used AutoHotkey's case-insensitive `=`.
AssertFalse("strict comparator distinguishes case", TestValuesEqual("A", "a"))
AssertTrue("strict comparator accepts exact match", TestValuesEqual("A", "A"))

; This file intentionally includes only the pure core. If the core starts depending on
; tray, GUI, hotkeys, clipboard, or filesystem startup state, this test should stop loading.
AssertEqual("pure core toggles case", ToggleCase("AbC"), "aBc")
AssertEqual("pure core lints prose", LintText("hello,world"), "hello, world")
AssertEqual("pure core protects structured numbers", LintText("v2.0.1 3.14 12:30"), "v2.0.1 3.14 12:30")

FinishTests("pure transform core tests")
