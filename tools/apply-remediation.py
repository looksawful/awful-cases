from pathlib import Path

path = Path("app/awful-cases.ahk")
text = path.read_text(encoding="utf-8")


def replace_once(label: str, old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    text = text.replace(old, new, 1)


replace_once(
    "hotkey registration",
    '''RegisterHotkeys() {
RegisterHotkey("Upper", "Up", "upper")
RegisterHotkey("Lower", "Down", "lower")
RegisterHotkey("Toggle", "Right", "toggle")
RegisterHotkey("Title", "Left", "title")
RegisterHotkey("Lint", "PgDn", "lint")
RegisterHotkey("Sentence", "Delete", "sentence")
key := ReadKey("Settings", "Home")
TryRegister("^!+" . key, (*) => ShowSettingsGui(), "^!+Home")
}
RegisterHotkey(name, defaultKey, mode) {
key := ReadKey(name, defaultKey)
TryRegister("^!+" . key, (*) => TransformSelectedText(mode), "^!+" . defaultKey)
}
TryRegister(hotkeyString, callback, fallbackHotkey := "") {
try {
Hotkey(hotkeyString, callback)
} catch {
if fallbackHotkey != "" {
try Hotkey(fallbackHotkey, callback)
}
}
}
''',
    '''RegisterHotkeys() {
assignments := GetConfiguredHotkeyAssignments()
duplicate := FindDuplicateHotkey(assignments)
if duplicate != "" {
ShowToast("Duplicate hotkey: Ctrl + Alt + Shift + " . duplicate)
return
}
TryRegister("^!+" . assignments["Upper"], (*) => TransformSelectedText("upper"))
TryRegister("^!+" . assignments["Lower"], (*) => TransformSelectedText("lower"))
TryRegister("^!+" . assignments["Toggle"], (*) => TransformSelectedText("toggle"))
TryRegister("^!+" . assignments["Title"], (*) => TransformSelectedText("title"))
TryRegister("^!+" . assignments["Lint"], (*) => TransformSelectedText("lint"))
TryRegister("^!+" . assignments["Sentence"], (*) => TransformSelectedText("sentence"))
TryRegister("^!+" . assignments["Settings"], (*) => ShowSettingsGui())
}
GetConfiguredHotkeyAssignments() {
return Map(
"Upper", ReadKey("Upper", "Up"),
"Lower", ReadKey("Lower", "Down"),
"Toggle", ReadKey("Toggle", "Right"),
"Title", ReadKey("Title", "Left"),
"Lint", ReadKey("Lint", "PgDn"),
"Sentence", ReadKey("Sentence", "Delete"),
"Settings", ReadKey("Settings", "Home")
)
}
TryRegister(hotkeyString, callback) {
try {
Hotkey(hotkeyString, callback)
return true
} catch as err {
ShowToast("Cannot register hotkey: " . hotkeyString)
return false
}
}
''',
)

replace_once(
    "settings globals",
    '''ShowSettingsGui() {
global ConfigPath
''',
    '''ShowSettingsGui() {
global ConfigPath, AllowedFinalHotkeyKeys
''',
)

replace_once(
    "settings key choices",
    '''keyChoices := ["Up", "Down", "Left", "Right", "Home", "End", "PgUp", "PgDn", "Tab", "Backspace", "Delete", "Insert"
, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
, "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
''',
    '''keyChoices := AllowedFinalHotkeyKeys
''',
)

replace_once(
    "settings save validation",
    '''SaveSettingsGui(g, hotkeyControls, featureControls, langDdl) {
global ConfigPath
newLang := langDdl.Text = "RU" ? "ru" : "en"
IniWrite(newLang, ConfigPath, "Ui", "Language")
for key, control in hotkeyControls {
value := control.Text
if !IsAllowedFinalHotkeyKey(value) {
ShowToast("Unsupported key: " . value)
return
}
IniWrite(value, ConfigPath, "Hotkeys", key)
}
for key, control in featureControls {
IniWrite(control.Value, ConfigPath, "Features", key)
}
ShowToast("Settings saved")
Sleep 300
Reload()
}
''',
    '''SaveSettingsGui(g, hotkeyControls, featureControls, langDdl) {
global ConfigPath
newLang := langDdl.Text = "RU" ? "ru" : "en"
assignments := Map()
for key, control in hotkeyControls {
value := control.Text
if !IsAllowedFinalHotkeyKey(value) {
ShowToast("Unsupported key: " . value)
return
}
assignments[key] := value
}
duplicate := FindDuplicateHotkey(assignments)
if duplicate != "" {
ShowToast("Duplicate hotkey: Ctrl + Alt + Shift + " . duplicate)
return
}
IniWrite(newLang, ConfigPath, "Ui", "Language")
for key, value in assignments {
IniWrite(value, ConfigPath, "Hotkeys", key)
}
for key, control in featureControls {
IniWrite(control.Value, ConfigPath, "Features", key)
}
ShowToast("Settings saved")
Sleep 300
Reload()
}
''',
)

replace_once(
    "duplicate hotkey helper",
    '''IsAllowedFinalHotkeyKey(value) {
global AllowedFinalHotkeyKeys
if value = "" {
return false
}
for k in AllowedFinalHotkeyKeys {
if (k = value) {
return true
}
}
return false
}
''',
    '''IsAllowedFinalHotkeyKey(value) {
global AllowedFinalHotkeyKeys
if value = "" {
return false
}
for k in AllowedFinalHotkeyKeys {
if (k = value) {
return true
}
}
return false
}
FindDuplicateHotkey(assignments) {
seen := Map()
for name, value in assignments {
key := CanonicalizeKeyName(value)
if key = "" {
continue
}
if seen.Has(key) {
return key
}
seen[key] := name
}
return ""
}
''',
)

replace_once(
    "non destructive settings reset",
    '''ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices) {
global ConfigPath
try FileDelete(ConfigPath)
FileAppend(GetDefaultConfig(), ConfigPath, "UTF-8")
''',
    '''ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices) {
''',
)

replace_once(
    "clipboard restore delay",
    '''Send "^v"
Sleep 120
try A_Clipboard := savedClipboard
''',
    '''Send "^v"
Sleep 500
try A_Clipboard := savedClipboard
''',
)

replace_once(
    "punctuation preservation",
    '''text := RegExReplace(text, "[ \\t" . Chr(160) . "]+([.,:;!?])", "$1")
text := RegExReplace(text, "([.,:;!?])([^\\s`r`n\\)\\]\\}»”.,:;!?…])", "$1 $2")
''',
    '''text := RegExReplace(text, "[ \\t" . Chr(160) . "]+([.,:;!?])", "$1")
text := RegExReplace(text, "([;!?])([^\\s`r`n\\)\\]\\}»”.,:;!?…])", "$1 $2")
text := RegExReplace(text, "([.,:])(?!\\d)([^\\s`r`n\\)\\]\\}»”.,:;!?…])", "$1 $2")
''',
)

replace_once(
    "email local part casing",
    '''normalized := StrLower(m[1] . "@" . m[2] . "." . m[3])''',
    '''normalized := m[1] . "@" . StrLower(m[2] . "." . m[3])''',
)

replace_once(
    "phone normalization scope",
    '''NormalizePhones(text) {
pos := 1
while RegExMatch(text, "(?<!\\d)(?:\\+7|8)?[ \\t" . Chr(160) . "\\(\\).-]*(\\d{3})[ \\t" . Chr(160) . "\\).-]*(\\d{3})[ \\t" . Chr(160) . ".-]*(\\d{2})[ \\t" . Chr(160) . ".-]*(\\d{2})(?!\\d)", &m, pos) {
original := m[0]
if !(InStr(original, "+7") || RegExMatch(original, "^8") || InStr(original, "(") || InStr(original, "-") || InStr(original, " ")) {
pos := m.Pos + StrLen(original)
continue
}
normalized := "+7 (" . m[1] . ") " . m[2] . "-" . m[3] . "-" . m[4]
text := SubStr(text, 1, m.Pos - 1) . normalized . SubStr(text, m.Pos + StrLen(original))
pos := m.Pos + StrLen(normalized)
}
return text
}
''',
    '''NormalizePhones(text) {
pos := 1
while RegExMatch(text, "(?<!\\d)(?:\\+7|8)[ \\t" . Chr(160) . "\\(\\).-]*(\\d{3})[ \\t" . Chr(160) . "\\).-]*(\\d{3})[ \\t" . Chr(160) . ".-]*(\\d{2})[ \\t" . Chr(160) . ".-]*(\\d{2})(?!\\d)", &m, pos) {
original := m[0]
normalized := "+7 (" . m[1] . ") " . m[2] . "-" . m[3] . "-" . m[4]
text := SubStr(text, 1, m.Pos - 1) . normalized . SubStr(text, m.Pos + StrLen(original))
pos := m.Pos + StrLen(normalized)
}
return text
}
''',
)

replace_once(
    "emoji cleanup scope",
    '''RemoveEmoji(text) {
text := RegExReplace(text, "[\\x{1F000}-\\x{1FAFF}]", "")
text := RegExReplace(text, "[\\x{2600}-\\x{27BF}]", "")
text := RegExReplace(text, "[\\x{FE00}-\\x{FE0F}]", "")
text := RegExReplace(text, "[\\x{1F3FB}-\\x{1F3FF}]", "")
text := StrReplace(text, Chr(8205), "")
return text
}
''',
    '''RemoveEmoji(text) {
emoji := "[\\x{1F000}-\\x{1FAFF}]"
modifier := "[\\x{1F3FB}-\\x{1F3FF}]"
variation := "[\\x{FE0E}\\x{FE0F}]"
sequence := emoji . "(?:" . modifier . "|" . variation . ")?(?:\\x{200D}" . emoji . "(?:" . modifier . "|" . variation . ")?)*"
return RegExReplace(text, sequence, "")
}
''',
)

path.write_text(text, encoding="utf-8", newline="\r\n")
print("Applied audited Awful Cases runtime fixes.")
