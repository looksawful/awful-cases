#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
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
global ConfigPath
lang := GetUiLang()
isRu := lang = "ru"
bg := "0F1411"
panel := "151D18"
panel2 := "1B251F"
fg := "F3F7F1"
muted := "B6C3B8"
accent := "78C98B"
accentSoft := "24392B"
accentSoft2 := "2B4734"
border := "2F4336"
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
["Upper",    isRu ? "Верхний регистр"      : "Uppercase",           "Up"],
["Lower",    isRu ? "Нижний регистр"        : "Lowercase",           "Down"],
["Toggle",   isRu ? "Инвертировать регистр" : "Toggle case",         "Right"],
["Title",    isRu ? "Заголовочный регистр"  : "Title case",          "Left"],
["Lint",     isRu ? "Очистить типографику"  : "Clean typography",   "PgDn"],
["Sentence", isRu ? "Типографика предложений" : "Sentence typography",  "Delete"],
["Settings", isRu ? "Открыть настройки"     : "Open settings",       "Home"]
]
keyChoices := ["Up", "Down", "Left", "Right", "Home", "End", "PgUp", "PgDn", "Tab", "Backspace", "Delete", "Insert"
, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
, "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
captureLabel := isRu ? "Нажмите клавишу..." : "Press a key..."
captureBtnLabel := isRu ? "Захват" : "Capture"
g.SetFont("s13 c" . fg, "Segoe UI")
for item in hotkeys {
iniKey    := item[1]
label     := item[2]
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
["FixSpaces",      isRu ? "Пробелы" : "Fix spaces"],
["FixShortWords",  isRu ? "NBSP у коротких слов"         : "Fix short-word NBSP"],
["FixPunctuation", isRu ? "Пробелы у знаков пунктуации" : "Fix punctuation spaces"],
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
key   := item[1]
label := item[2]
value := IniRead(ConfigPath, "Features", key, 1)
xOpt := col = 0 ? "xm" : "x+" . columnGap
yOpt := col = 0 ? (index = 1 ? "y+16" : "y+10") : "yp"
cb := g.AddCheckbox(xOpt . " " . yOpt . " w" . checkboxColumnWidth . " h28 c" . fg, Chr(8194) . label)
cb.Value := value
featureControls[key] := cb
col := col = 0 ? 1 : 0
}
saveBtn   := AddUiActionButton(g, "xm y+34 w" . buttonWidth . " h" . buttonHeight . " Background" . accentSoft2 . " c" . buttonText . " Center Border", isRu ? "Сохранить" : "Save")
resetBtn  := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "Сбросить" : "Reset")
reloadBtn := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "О программе" : "About")
closeBtn  := AddUiActionButton(g, "x+12 w" . buttonWidth . " h" . buttonHeight . " Background" . panel2 . " c" . buttonText . " Center Border", isRu ? "Закрыть" : "Close")
saveBtn.OnEvent("Click",   (*) => SaveSettingsGui(g, hotkeyControls, featureControls, langDdl))
resetBtn.OnEvent("Click",  (*) => ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices))
reloadBtn.OnEvent("Click", (*) => ShowAbout())
closeBtn.OnEvent("Click",  (*) => g.Destroy())
g.Show("AutoSize")
}
AddUiActionButton(g, options, label) {
g.SetFont("s13 cFFFFFF Bold", "Segoe UI")
return g.AddText(options . " 0x200", label)
}
CreateLangToggle(g, x, y, state, onColor, offColor, thumbColor) {
trackColor := state["isRu"] ? onColor : offColor
thumbX := state["isRu"] ? x + 28 : x + 4
track := g.AddText("x" . x . " y" . y . " w52 h28 Background" . trackColor . " Border")
thumb := g.AddText("x" . thumbX . " y" . (y + 4) . " w20 h20 Background" . thumbColor . " Border")
state["track"] := track
state["thumb"] := thumb
track.OnEvent("Click", ToggleLangToggle.Bind(state, x, y, onColor, offColor, thumbColor))
thumb.OnEvent("Click", ToggleLangToggle.Bind(state, x, y, onColor, offColor, thumbColor))
}
ToggleLangToggle(state, x, y, onColor, offColor, thumbColor, *) {
state["isRu"] := !state["isRu"]
RefreshLangToggle(state, x, y, onColor, offColor, thumbColor)
}
RefreshLangToggle(state, x, y, onColor, offColor, thumbColor) {
trackColor := state["isRu"] ? onColor : offColor
thumbX := state["isRu"] ? x + 28 : x + 4
state["track"].Opt("Background" . trackColor)
state["thumb"].Opt("Background" . thumbColor)
state["thumb"].Move(thumbX, y + 4)
}
SaveSettingsGui(g, hotkeyControls, featureControls, langDdl) {
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
NormalizeKeyInput(value) {
value := Trim(value)
if value = "" {
return ""
}
; Accept both AHK symbols (^!+#) and readable forms like Ctrl+Alt+Shift+PgDn.
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
ResetToDefaults() {
global ConfigPath
try FileDelete(ConfigPath)
FileAppend(GetDefaultConfig(), ConfigPath, "UTF-8")
ShowToast("Defaults restored")
Sleep 300
Reload()
}
ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices) {
global ConfigPath
try FileDelete(ConfigPath)
FileAppend(GetDefaultConfig(), ConfigPath, "UTF-8")
defaults := Map(
"Upper", "Up", "Lower", "Down", "Toggle", "Right",
"Title", "Left", "Lint", "PgDn", "Sentence", "Delete", "Settings", "Home"
)
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
ShowToast("Defaults restored")
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
changedText := LintText(originalText)
message := "Text linted"
case "sentence":
changedText := SentenceAwareParagraphTypography(originalText)
message := "Sentence typography applied"
default:
try A_Clipboard := savedClipboard
ShowToast("Unknown action")
return
}
A_Clipboard := changedText
Sleep 60
Send "^v"
Sleep 120
try A_Clipboard := savedClipboard
ShowToast(message)
}
ToggleCase(text) {
result := ""
Loop Parse text {
char := A_LoopField
upper := StrUpper(char)
lower := StrLower(char)
if (char = upper && char != lower) {
result .= lower
} else if (char = lower && char != upper) {
result .= upper
} else {
result .= char
}
}
return result
}
TitleCase(text) {
result := ""
makeUpper := true
Loop Parse text {
char := A_LoopField
if RegExMatch(char, "\p{L}") {
if makeUpper {
result .= StrUpper(char)
makeUpper := false
} else {
result .= StrLower(char)
}
} else {
result .= char
makeUpper := true
}
}
return result
}
SentenceAwareParagraphTypography(text) {
result := ""
len := StrLen(text)
i := 1
capitalizeNextWord := true
nb := Chr(160)
while i <= len {
ch := SubStr(text, i, 1)
if (ch = ".") {
result .= ch
if IsSentenceBoundaryDot(text, i) {
j := i + 1
while j <= len {
c := SubStr(text, j, 1)
if (c = " " || c = "`t" || c = nb) {
j += 1
continue
}
break
}
if (j <= len && RegExMatch(SubStr(text, j, 1), "[A-Za-zА-Яа-яЁё]")) {
result .= " "
capitalizeNextWord := true
i := j
continue
}
}
i += 1
continue
}
if (ch = "`r" || ch = "`n") {
result .= ch
capitalizeNextWord := true
i += 1
continue
}
if (capitalizeNextWord && RegExMatch(ch, "[A-Za-zА-Яа-яЁё]")) {
result .= StrUpper(ch)
capitalizeNextWord := false
i += 1
continue
}
result .= ch
i += 1
}
return result
}
IsSentenceBoundaryDot(text, dotPos) {
len := StrLen(text)
prevPos := dotPos - 1
while prevPos >= 1 {
c := SubStr(text, prevPos, 1)
if (c = " " || c = "`t" || c = Chr(160)) {
prevPos -= 1
continue
}
break
}
nextPos := dotPos + 1
while nextPos <= len {
c := SubStr(text, nextPos, 1)
if (c = " " || c = "`t" || c = Chr(160)) {
nextPos += 1
continue
}
break
}
prevChar := prevPos >= 1 ? SubStr(text, prevPos, 1) : ""
nextChar := nextPos <= len ? SubStr(text, nextPos, 1) : ""
if RegExMatch(prevChar, "\d") && RegExMatch(nextChar, "\d") {
return false
}
if RegExMatch(prevChar, "[A-Za-zА-Яа-яЁё]") && RegExMatch(nextChar, "[A-Za-zА-Яа-яЁё]") {
lookAhead := nextPos + 1
while lookAhead <= len {
c := SubStr(text, lookAhead, 1)
if (c = " " || c = "`t" || c = Chr(160)) {
lookAhead += 1
continue
}
break
}
if (lookAhead <= len && SubStr(text, lookAhead, 1) = ".") {
return false
}
}
return true
}
LintText(text) {
text := StrReplace(text, Chr(11), "`r`n")
text := StrReplace(text, Chr(8232), "`r`n")
if FeatureEnabled("FixEmails") {
text := NormalizeEmails(text)
}
protected := ProtectFragments(&text)
if FeatureEnabled("RemoveEmoji") {
text := RemoveEmoji(text)
}
if FeatureEnabled("FixSymbols") {
text := RegExReplace(text, "i)\(c\)", "©")
text := RegExReplace(text, "i)\(r\)", "®")
text := RegExReplace(text, "i)\(tm\)", "™")
}
if FeatureEnabled("FixEllipsis") {
text := StrReplace(text, "...", "…")
}
if FeatureEnabled("FixQuotes") {
text := ConvertQuotes(text)
text := FixQuoteSpaces(text)
}
if FeatureEnabled("FixDash") {
text := StrReplace(text, "--", "—")
text := RegExReplace(text, "[ \t" . Chr(160) . "]*—[ \t" . Chr(160) . "]*", Chr(160) . "— ")
}
if FeatureEnabled("FixHyphens") {
text := FixRussianHyphenation(text)
text := RegExReplace(text, "(\p{L})[ \t" . Chr(160) . "]*-[ \t" . Chr(160) . "]*(\p{L})", "$1" . Chr(8209) . "$2")
}
if FeatureEnabled("FixSpaces") {
text := RegExReplace(text, "[ \t" . Chr(160) . "]{2,}", " ")
}
if FeatureEnabled("FixPunctuation") {
text := RegExReplace(text, "[ \t" . Chr(160) . "]+([.,:;!?])", "$1")
text := RegExReplace(text, "([.,:;!?])([^\s`r`n\)\]\}»”.,:;!?…])", "$1 $2")
}
if FeatureEnabled("FixShortWords") {
text := FixShortWordSpaces(text)
}
if FeatureEnabled("FixNumbers") {
text := RegExReplace(text, "([№§])[ \t" . Chr(160) . "]*(\d)", "$1" . Chr(160) . "$2")
}
if FeatureEnabled("FixPhones") {
text := NormalizePhones(text)
}
; Do not convert every regular space to NBSP. NBSP is only applied by targeted rules
; such as short-word spaces and number markers.
text := RestoreFragments(text, protected)
return text
}
NormalizeEmails(text) {
pos := 1
while RegExMatch(text, "i)([A-Z0-9._%+\-]+)\s*@\s*([A-Z0-9.\-]+)\s*\.\s*([A-Z]{2,})", &m, pos) {
original := m[0]
normalized := StrLower(m[1] . "@" . m[2] . "." . m[3])
text := SubStr(text, 1, m.Pos - 1) . normalized . SubStr(text, m.Pos + StrLen(original))
pos := m.Pos + StrLen(normalized)
}
return text
}
NormalizePhones(text) {
pos := 1
while RegExMatch(text, "(?<!\d)(?:\+7|8)?[ \t" . Chr(160) . "\(\).-]*(\d{3})[ \t" . Chr(160) . "\).-]*(\d{3})[ \t" . Chr(160) . ".-]*(\d{2})[ \t" . Chr(160) . ".-]*(\d{2})(?!\d)", &m, pos) {
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
ProtectFragments(&text) {
protected := Map()
index := 1
dq := Chr(34)
tick := Chr(96)
patterns := []
if FeatureEnabled("ProtectCode") {
patterns.Push("s)" . tick . tick . tick . ".*?" . tick . tick . tick)
patterns.Push(tick . "[^" . tick . "`r`n]+" . tick)
}
if FeatureEnabled("ProtectUrls") {
patterns.Push("i)\bhttps?://[^\s<>()" . dq . "'«»]+")
patterns.Push("i)\bwww\.[^\s<>()" . dq . "'«»]+")
patterns.Push("i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b")
}
if FeatureEnabled("ProtectPaths") {
patterns.Push("[A-Za-z]:\\(?:[^\\/:*?" . dq . "<>|\r\n]+\\)*[^\\/:*?" . dq . "<>|\r\n]*")
patterns.Push("\\\\[A-Za-z0-9._-]+\\[^\r\n]+")
patterns.Push("(?:^|[\s])\/(?:[^\/\s]+\/)+[^\/\s]+")
}
for pattern in patterns {
while RegExMatch(text, pattern, &m) {
token := Chr(0xE000) . index . Chr(0xE001)
protected[token] := m[0]
text := SubStr(text, 1, m.Pos - 1) . token . SubStr(text, m.Pos + StrLen(m[0]))
index += 1
}
}
return protected
}
RestoreFragments(text, protected) {
for token, value in protected {
text := StrReplace(text, token, value)
}
return text
}
ConvertQuotes(text) {
result := ""
depth := 0
len := StrLen(text)
Loop Parse text {
char := A_LoopField
if (char != Chr(34)) {
result .= char
continue
}
i := A_Index
prev := i > 1 ? SubStr(text, i - 1, 1) : ""
next := i < len ? SubStr(text, i + 1, 1) : ""
isOpening := false
if (depth = 0) {
isOpening := true
} else if RegExMatch(prev, "^[\s\(\[\{«„—-]$") && !RegExMatch(next, "^[\s\)\]\}»”.,:;!?]$") {
isOpening := true
}
if isOpening {
depth += 1
result .= depth = 1 ? "«" : "„"
} else {
result .= depth > 1 ? "“" : "»"
if (depth > 0) {
depth -= 1
}
}
}
return result
}
FixQuoteSpaces(text) {
text := RegExReplace(text, "«[ \t" . Chr(160) . "]+", "«")
text := RegExReplace(text, "[ \t" . Chr(160) . "]+»", "»")
text := RegExReplace(text, "„[ \t" . Chr(160) . "]+", "„")
text := RegExReplace(text, "[ \t" . Chr(160) . "]+“", "“")
return text
}
FixShortWordSpaces(text) {
nb := Chr(160)
words := "в|к|с|у|о|а|и|я|по|на|за|из|от|до|со|ко|об|во|не|ни|но|да|же|ли|бы|ль"
text := RegExReplace(text, "i)(^|[^\p{L}])(" . words . ")[ \t" . nb . "]+(?=[\p{L}\d])", "$1$2" . nb)
return text
}
FixRussianHyphenation(text) {
nbHyphen := Chr(8209)
sp := "[ \t" . Chr(160) . "]*"
hy := "[-" . nbHyphen . "]"
text := RegExReplace(text, "i)\bточь" . sp . hy . sp . "в" . sp . hy . sp . "точь\b", "точь" . nbHyphen . "в" . nbHyphen . "точь")
text := RegExReplace(text, "i)\bкрест" . sp . hy . sp . "накрест\b", "крест" . nbHyphen . "накрест")
text := RegExReplace(text, "i)\bволей" . sp . hy . sp . "неволей\b", "волей" . nbHyphen . "неволей")
text := RegExReplace(text, "i)\bхудо" . sp . hy . sp . "бедно\b", "худо" . nbHyphen . "бедно")
text := RegExReplace(text, "i)\bдавным" . sp . hy . sp . "давно\b", "давным" . nbHyphen . "давно")
text := RegExReplace(text, "i)\bмало" . sp . hy . sp . "помалу\b", "мало" . nbHyphen . "помалу")
text := RegExReplace(text, "i)\bтихо" . sp . hy . sp . "смирно\b", "тихо" . nbHyphen . "смирно")
text := RegExReplace(text, "i)\bболее" . sp . hy . sp . "менее\b", "более" . nbHyphen . "менее")
text := RegExReplace(text, "i)\bхочешь" . sp . hy . sp . "не" . sp . hy . sp . "хочешь\b", "хочешь" . nbHyphen . "не" . nbHyphen . "хочешь")
text := RegExReplace(text, "i)\b(из|по)" . sp . hy . sp . "(за|под|над)\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(кое|кой)" . sp . hy . sp . "(\p{L}+)\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(\p{L}+)" . sp . hy . sp . "(то|либо|нибудь|ка|де|с|таки)\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(по)" . sp . hy . sp . "(\p{L}+(?:ски|цки|ьи|ому|ему|ыми|ими|латыни|английски|французски|немецки|испански|китайски|японски))\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(во?|в)" . sp . hy . sp . "(первых|вторых|третьих|четвертых|четвёртых|пятых|шестых|седьмых|восьмых|девятых|десятых|главных|последних)\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(еле|едва|чуть|ой|ах|ох|ха|хи|ей|ну|нука)" . sp . hy . sp . "(еле|едва|чуть|ой|ах|ох|ха|хи|богу|ну|ка)\b", "$1" . nbHyphen . "$2")
text := RegExReplace(text, "i)\b(e|web|ui|ux|seo|smm|it|hr|pr|vip|pdf|psd|figma|front|back|full|no|low|high|mid)" . sp . hy . sp . "(mail|site|дизайн|дизайнер|специалист|менеджер|директор|файл|макет|end|office|stack|code|poly|fi|res)\b", "$1" . nbHyphen . "$2")
return text
}
RemoveEmoji(text) {
text := RegExReplace(text, "[\x{1F000}-\x{1FAFF}]", "")
text := RegExReplace(text, "[\x{2600}-\x{27BF}]", "")
text := RegExReplace(text, "[\x{FE00}-\x{FE0F}]", "")
text := RegExReplace(text, "[\x{1F3FB}-\x{1F3FF}]", "")
text := StrReplace(text, Chr(8205), "")
return text
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