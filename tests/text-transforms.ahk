#Requires AutoHotkey v2.0
#Include lib\assert.ahk
#Include ..\app\lib\text-transforms.ahk

AssertEqual("toggle case", ToggleCase("AbC 123"), "aBc 123")
AssertEqual("toggle Cyrillic case", ToggleCase("ПрИвЕт"), "пРиВеТ")
AssertEqual("title case", TitleCase("hello world"), "Hello World")
AssertEqual("sentence capitalization", SentenceAwareParagraphTypography("hello. world"), "Hello. World")
AssertEqual("sentence mode handles exclamation", SentenceAwareParagraphTypography("hello! world"), "Hello! World")
AssertEqual("sentence mode handles question", SentenceAwareParagraphTypography("hello? world"), "Hello? World")
AssertEqual("sentence mode protects URL", SentenceAwareParagraphTypography("visit https://example.com now"), "Visit https://example.com now")
AssertEqual("sentence mode protects email", SentenceAwareParagraphTypography("mail User.Name@example.com now"), "Mail User.Name@example.com now")
AssertEqual("sentence mode protects bare domain", SentenceAwareParagraphTypography("visit example.com now"), "Visit example.com now")
AssertEqual("sentence mode protects Windows path", SentenceAwareParagraphTypography("open C:\Work\file.txt now"), "Open C:\Work\file.txt now")
AssertEqual("sentence mode protects UNC path", SentenceAwareParagraphTypography("open \\server\share\file.txt now"), "Open \\server\share\file.txt now")
AssertEqual("ellipsis cleanup", LintText("hello..."), "hello…")
AssertEqual("URL protection", LintText("https://example.com/a--b"), "https://example.com/a--b")
AssertEqual("Windows path protection", LintText("C:\Work\my--file.txt"), "C:\Work\my--file.txt")
AssertEqual("UNC path protection", LintText("\\server\share\my--file.txt"), "\\server\share\my--file.txt")
AssertEqual("Russian hyphenation through lint", LintText("кое - кто"), "кое‑кто")
AssertEqual("Russian phone normalization", NormalizePhones("+7 999 123 45 67"), "+7 (999) 123-45-67")
AssertEqual("Russian phone with leading 8", NormalizePhones("8 (999) 123-45-67"), "+7 (999) 123-45-67")

; Regression coverage for destructive cleanup bugs.
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

; Safer default: destructive emoji removal is opt-in for new/reset configurations.
defaultFeatures := GetDefaultFeatureState()
AssertEqual("emoji removal default is disabled", defaultFeatures["RemoveEmoji"], 0)
AssertEqual("default lint preserves emoji", LintText("hello 😀 ✓"), "hello 😀 ✓")
emojiFeatures := GetDefaultFeatureState()
emojiFeatures["RemoveEmoji"] := 1
AssertEqual("explicit emoji removal still works", LintText("hello 😀 ✓", emojiFeatures), "hello ✓")

FinishTests("text transformation tests")