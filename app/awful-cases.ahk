#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#Include lib\text-transforms.ahk
; Awful Cases
; Text case and typography utility for Windows.
; Copyright (c) 2026 Ivan Krushinsky
; Code license: MIT

global AppName := "Awful Cases"
global AppVersion := "0.1.0"
global ConfigPath := A_ScriptDir "\awful-cases.ini"
global AllowedFinalHotkeyKeys := ["Up", "Down", "Left", "Right", "Home", "End", "PgUp", "PgDn", "Tab", "Backspace", "Delete", "Insert"
, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
, "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24"]

EnsureConfig()
SetupTray()
RegisterHotkeys()

EnsureConfig() {
global ConfigPath
if FileExist(ConfigPath) {
return
}
FileAppend(GetDefaultConfig(), ConfigPath, "UTF-8")
}

GetDefaultConfig() {
return "
(
[Hotkeys]
Upper=Up
Lower=Down
Toggle=Right
Title=Left
Lint=PgDn
Sentence=Delete
Settings=Home

[Ui]
Language=ru

[Features]
FixDash=1
FixQuotes=1
FixHyphens=1
FixSpaces=1
FixShortWords=1
FixPunctuation=1
FixPhones=1
FixEmails=1
RemoveEmoji=1
ProtectCode=1
ProtectUrls=1
ProtectPaths=1
FixSymbols=1
FixEllipsis=1
FixNumbers=1
)"
}

GetDefaultHotkeys() {
return Map(
"Upper", "Up",
"Lower", "Down",
"Toggle", "Right",
"Title", "Left",
"Lint", "PgDn",
"Sentence", "Delete",
"Settings", "Home"
)
}

SetupTray() {
global AppName
A_TrayMenu.Delete()
A_TrayMenu.Add(AppName, (*) => ShowSettingsGui())
A_TrayMenu.Disable(AppName)
A_TrayMenu.Add()
A_TrayMenu.Add("Settings", (*) => ShowSettingsGui())
A_TrayMenu.Add("Open config", (*) => OpenConfig())
A_TrayMenu.Add("About", (*) => ShowAbout())
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Reset to defaults", (*) => ResetToDefaults())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
}

RegisterHotkeys() {
defaults := GetDefaultHotkeys()
keys := Map()
for name, defaultKey in defaults {
keys[name] := ReadKey(name, defaultKey)
}
if !ValidateUniqueHotkeys(keys) {
ShowToast("Duplicate hotkeys in config; defaults used")
keys := defaults
}
RegisterActionHotkey(keys["Upper"], "upper")
RegisterActionHotkey(keys["Lower"], "lower")
RegisterActionHotkey(keys["Toggle"], "toggle")
RegisterActionHotkey(keys["Title"], "title")
RegisterActionHotkey(keys["Lint"], "lint")
RegisterActionHotkey(keys["Sentence"], "sentence")
TryRegister("^!+" . keys["Settings"], (*) => ShowSettingsGui())
}

RegisterActionHotkey(key, mode) {
TryRegister("^!+" . key, (*) => TransformSelectedText(mode))
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

ReadKey(name, defaultKey) {
global ConfigPath
value := IniRead(ConfigPath, "Hotkeys", name, defaultKey)
value := NormalizeKeyInput(value)
if value = "" {
value := defaultKey
}
return value
}

FeatureEnabled(name, defaultValue := 1) {
global ConfigPath
return IniRead(ConfigPath, "Features", name, defaultValue) = 1
}

GetRuntimeFeatureState() {
features := GetDefaultFeatureState()
for name, defaultValue in features {
features[name] := FeatureEnabled(name, defaultValue)
}
return features
}

GetUiLang() {
global ConfigPath
return IniRead(ConfigPath, "Ui", "Language", "ru")
}

CaptureHotkey(ddl, keyChoices, *) {
ih := InputHook("L1 B T3")
ih.KeyOpt("{All}", "SE")
ih.Start()
ih.Wait()
raw := ih.EndKey
if raw = "" {
return
}
captured := NormalizeKeyInput(raw)
if captured = "" {
captured := CanonicalizeKeyName(raw)
}
if captured = "" || !IsAllowedFinalHotkeyKey(captured) {
return
}
for i, k in keyChoices {
if k = captured {
ddl.Choose(i)
return
}
}
}

ShowSettingsGui() {
global ConfigPath, AllowedFinalHotkeyKeys
lang := GetUiLang()
isRu := lang = "ru"
bg := "0F1411"
panel2 := "1B251F"
fg := "F3F7F1"
muted := "B6C3B8"
accent := "78C98B"
accentSoft := "24392B"
accentSoft2 := "2B4734"
buttonText := "E9F6EC"
contentWidth := 980
labelWidth := 290
modifierWidth := 170
hotkeyWidth := 128
captureWidth := 102
columnGap := 28
checkboxColumnWidth := 420
buttonWidth := 184
buttonHeight := 44

g := Gui("+AlwaysOnTop", AppName)
g.BackColor := bg
g.MarginX := 52
g.MarginY := 48
g.SetFont("s14 c" . fg, "Segoe UI")
g.AddText("x" . (52 + contentWidth - 160) . " y50 w54 h22", isRu ? "Язык" : "Lang")
langDdl := g.AddDropDownList("x" . (52 + contentWidth - 98) . " y46 w98 Background" . panel2 . " c" . fg . " Choose" . (isRu ? 2 : 1), ["EN", "RU"])

g.SetFont("s24 c" . accent . " Bold", "Segoe UI")
g.AddText("xm y+28", isRu ? "Горячие клавиши" : "Hotkeys")
hotkeyControls := Map()
hotkeys := [
["Upper",    isRu ? "Верхний регистр"        : "Uppercase",              "Up"],
["Lower",    isRu ? "Нижний регистр"          : "Lowercase",              "Down"],
["Toggle",   isRu ? "Инвертировать регистр"   : "Toggle case",            "Right"],
["Title",    isRu ? "Заголовочный регистр"    : "Title case",             "Left"],
["Lint",     isRu ? "Очистить типографику"    : "Clean typography",       "PgDn"],
["Sentence", isRu ? "Типографика предложений" : "Sentence typography",    "Delete"],
["Settings", isRu ? "Открыть настройки"       : "Open settings",          "Home"]
]
keyChoices := AllowedFinalHotkeyKeys
captureBtnLabel := isRu ? "Захват" : "Capture"

g.SetFont("s13 c" . fg, "Segoe UI")
for item in hotkeys {
iniKey := item[1]
label := item[2]
defaultKey := item[3]
currentKey := ReadKey(iniKey, defaultKey)
chooseIdx := 1
for i, k in keyChoices {
if k = currentKey {
chooseIdx := i
break
}
}
g.AddText("xm y+14 w" . labelWidth . " h24", label)
g.SetFont("s13 c" . muted, "Segoe UI")
g.AddText("x+12 yp w" . modifierWidth . " h24", "Ctrl + Alt + Shift +")
g.SetFont("s13 c" . fg, "Segoe UI")
ddl := g.AddDropDownList("x+10 yp-4 w" . hotkeyWidth . " Background" . panel2 . " c" . fg . " Choose" . chooseIdx, keyChoices)
hotkeyControls[iniKey] := ddl
captureBtn := AddUiActionButton(g, "x+12 yp-1 w" . captureWidth . " h32 Background" . accentSoft . " c" . buttonText . " Center Border", captureBtnLabel)
captureBtn.OnEvent("Click", CaptureHotkey.Bind(ddl, keyChoices))
}

g.SetFont("s24 c" . accent . " Bold", "Segoe UI")
g.AddText("xm y+30", isRu ? "Типографика" : "Typography")
g.SetFont("s14 c" . fg, "Segoe UI")
featureControls := Map()
features := [
["FixDash",        isRu ? "Исправить тире"               : "Fix dashes"],
["FixQuotes",      isRu ? "Исправить кавычки"            : "Fix quotes"],
["FixHyphens",     isRu ? "Исправить дефисы"             : "Fix hyphens"],
["FixSpaces",      isRu ? "Пробелы"                      : "Fix spaces"],
["FixShortWords",  isRu ? "NBSP у коротких слов"         : "Fix short-word NBSP"],
["FixPunctuation", isRu ? "Пробелы у знаков пунктуации"  : "Fix punctuation spaces"],
["FixPhones",      isRu ? "Нормализовать телефоны"       : "Normalize phones"],
["FixEmails",      isRu ? "Нормализовать email"          : "Normalize emails"],
["RemoveEmoji",    isRu ? "Удалить эмодзи"               : "Remove emoji"],
["ProtectCode",    isRu ? "Защитить код"                 : "Protect code"],
["ProtectUrls",    isRu ? "Защитить URL и email"         : "Protect URLs and emails"],
["ProtectPaths",   isRu ? "Защитить пути"                : "Protect paths"],
["FixSymbols",     isRu ? "Исправить © ® ™"              : "Fix © ® ™"],
["FixEllipsis",    isRu ? "Исправить многоточие"         : "Fix ellipsis"],
["FixNumbers",     isRu ? "Исправить № и §"              : "Fix № and §"]
]
col := 0
for index, item in features {
key := item[1]
label := item[2]
value := IniRead(ConfigPath, "Features", key, 1)
xOpt := col = 0 ? "xm" : "x+" . columnGap
yOpt := col = 0 ? (index = 1 ? "y+16" : "y+10") : "yp"
cb := g.AddCheckbox(xOpt . " " . yOpt . " w" . checkboxColumnWidth . " h28 c" . fg, Chr(8194) . label)
cb.Value := value
featureControls[key] := cb
col := col = 0 ? 1 : 0
}

saveBtn := AddUiActionButton(g, "xm y+34 w" . buttonWidth . " h" . buttonHeight . " Background" . accentSoft2 . " c" . buttonText . " Center Border", isRu ? "Сохранить" : "Save")
resetBtn := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "Сбросить" : "Reset")
aboutBtn := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "О программе" : "About")
closeBtn := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "Закрыть" : "Close")
saveBtn.OnEvent("Click", (*) => SaveSettingsGui(g, hotkeyControls, featureControls, langDdl))
resetBtn.OnEvent("Click", (*) => ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices))
aboutBtn.OnEvent("Click", (*) => ShowAbout())
closeBtn.OnEvent("Click", (*) => g.Destroy())
g.Show("AutoSize")
}

AddUiActionButton(g, options, label) {
g.SetFont("s13 cFFFFFF Bold", "Segoe UI")
return g.AddText(options . " 0x200", label)
}

SaveSettingsGui(g, hotkeyControls, featureControls, langDdl) {
global ConfigPath
proposedHotkeys := Map()
for key, control in hotkeyControls {
value := control.Text
if !IsAllowedFinalHotkeyKey(value) {
ShowToast("Unsupported key: " . value)
return
}
proposedHotkeys[key] := value
}
if !ValidateUniqueHotkeys(proposedHotkeys) {
ShowToast("Each action needs a unique hotkey")
return
}

newLang := langDdl.Text = "RU" ? "ru" : "en"
IniWrite(newLang, ConfigPath, "Ui", "Language")
for key, value in proposedHotkeys {
IniWrite(value, ConfigPath, "Hotkeys", key)
}
for key, control in featureControls {
IniWrite(control.Value, ConfigPath, "Features", key)
}
ShowToast("Settings saved")
Sleep 300
Reload()
}

NormalizeKeyInput(value) {
value := Trim(value)
if value = "" {
return ""
}
value := RegExReplace(value, "i)\b(control|ctrl|alt|shift|win|windows)\b\s*\+?\s*", "")
value := StrReplace(value, "^", "")
value := StrReplace(value, "!", "")
value := StrReplace(value, "+", "")
value := StrReplace(value, "#", "")
value := RegExReplace(value, "\s+", "")
value := ConvertRuLayoutKeyToEn(value)
value := CanonicalizeKeyName(value)
if !IsAllowedFinalHotkeyKey(value) {
return ""
}
return value
}

ConvertRuLayoutKeyToEn(value) {
static ruMap := ""
if ruMap = "" {
ruMap := Map(
"й", "Q", "ц", "W", "у", "E", "к", "R", "е", "T", "н", "Y", "г", "U", "ш", "I", "щ", "O", "з", "P", "х", "[", "ъ", "]",
"ф", "A", "ы", "S", "в", "D", "а", "F", "п", "G", "р", "H", "о", "J", "л", "K", "д", "L", "ж", ";", "э", "'",
"я", "Z", "ч", "X", "с", "C", "м", "V", "и", "B", "т", "N", "ь", "M", "б", ",", "ю", "."
)
}
lower := StrLower(value)
if ruMap.Has(lower) {
return ruMap[lower]
}
return value
}

CanonicalizeKeyName(value) {
if value = "" {
return ""
}
if RegExMatch(value, "i)^f([1-9]|1[0-9]|2[0-4])$") {
return "F" . SubStr(StrUpper(value), 2)
}
if RegExMatch(value, "^[A-Za-z]$") {
return StrUpper(value)
}
if RegExMatch(value, "^\d$") {
return value
}
aliases := Map(
"pgup", "PgUp", "pageup", "PgUp",
"pgdn", "PgDn", "pagedown", "PgDn",
"up", "Up", "down", "Down", "left", "Left", "right", "Right",
"home", "Home", "end", "End",
"tab", "Tab", "backspace", "Backspace", "delete", "Delete", "del", "Delete", "insert", "Insert", "ins", "Insert"
)
key := StrLower(value)
return aliases.Has(key) ? aliases[key] : value
}

IsAllowedFinalHotkeyKey(value) {
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

ValidateUniqueHotkeys(assignments) {
seen := Map()
for name, key in assignments {
normalized := NormalizeKeyInput(key)
if normalized = "" {
return false
}
if seen.Has(normalized) {
return false
}
seen[normalized] := name
}
return true
}

ResetToDefaults() {
global ConfigPath
try FileDelete(ConfigPath)
FileAppend(GetDefaultConfig(), ConfigPath, "UTF-8")
ShowToast("Defaults restored")
Sleep 300
Reload()
}

ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices) {
defaults := GetDefaultHotkeys()
for iniKey, ddl in hotkeyControls {
defKey := defaults.Has(iniKey) ? defaults[iniKey] : "Up"
for i, k in keyChoices {
if k = defKey {
ddl.Choose(i)
break
}
}
}
for key, cb in featureControls {
cb.Value := 1
}
langDdl.Choose(2)
ShowToast("Defaults staged; save to apply")
}

TransformSelectedText(mode) {
savedClipboard := ClipboardAll()
A_Clipboard := ""
Send "^c"
if !ClipWait(1) {
try A_Clipboard := savedClipboard
ShowToast("No selected text")
return
}
originalText := A_Clipboard
switch mode {
case "upper":
changedText := StrUpper(originalText)
message := "Uppercase"
case "lower":
changedText := StrLower(originalText)
message := "Lowercase"
case "toggle":
changedText := ToggleCase(originalText)
message := "Case toggled"
case "title":
changedText := TitleCase(originalText)
message := "Title case"
case "lint":
changedText := LintText(originalText, GetRuntimeFeatureState())
message := "Text linted"
case "sentence":
changedText := SentenceAwareParagraphTypography(originalText)
message := "Sentence typography applied"
default:
try A_Clipboard := savedClipboard
ShowToast("Unknown action")
return
}
try A_Clipboard := savedClipboard
SendText changedText
ShowToast(message)
}

OpenConfig() {
global ConfigPath
EnsureConfig()
try Run("notepad.exe " . Chr(34) . ConfigPath . Chr(34))
catch as err
ShowToast("Cannot open config")
}

ShowAbout() {
global AppName, AppVersion
text := AppName "`nVersion " AppVersion "`n`nText case and typography utility for Windows.`n`nAuthor: Ivan Krushinsky / looksawful`nLicense: MIT`nWebsite: looksawful.ru"
MsgBox(text, AppName, "Iconi")
}

ShowToast(message) {
toast := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
toast.BackColor := "111111"
toast.MarginX := 8
toast.MarginY := 4
toast.SetFont("s8 cFFFFFF", "Segoe UI")
toast.AddText("xm ym", message)
toast.Show("AutoSize NoActivate")
WinGetPos(, , &w, &h, toast.Hwnd)
x := A_ScreenWidth - w - 18
y := A_ScreenHeight - h - 42
WinMove(x, y, , , toast.Hwnd)
WinSetTransparent(180, toast.Hwnd)
SetTimer(() => toast.Destroy(), -700)
}
