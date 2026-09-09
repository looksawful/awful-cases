; Pure text transformation core for Awful Cases.
; No tray, GUI, clipboard, hotkey, or filesystem side effects.

GetDefaultFeatureState() {
return Map(
"FixDash", 1,
"FixQuotes", 1,
"FixHyphens", 1,
"FixSpaces", 1,
"FixShortWords", 1,
"FixPunctuation", 1,
"FixPhones", 1,
"FixEmails", 1,
"RemoveEmoji", 0,
"ProtectCode", 1,
"ProtectUrls", 1,
"ProtectPaths", 1,
"FixSymbols", 1,
"FixEllipsis", 1,
"FixNumbers", 1
)
}

FeatureValue(features, name, defaultValue := 1) {
if IsObject(features) && features.Has(name) {
return features[name]
}
return defaultValue
}

ToggleCase(text) {
result := ""
Loop Parse text {
char := A_LoopField
upper := StrUpper(char)
lower := StrLower(char)
if (char == upper && char !== lower) {
result .= lower
} else if (char == lower && char !== upper) {
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
features := GetDefaultFeatureState()
protected := ProtectFragments(&text, features)
result := SentenceAwareParagraphTypographyCore(text)
return RestoreFragments(result, protected)
}

SentenceAwareParagraphTypographyCore(text) {
result := ""
len := StrLen(text)
i := 1
capitalizeNextWord := true
nb := Chr(160)
tokenOpen := Chr(0xE000)
tokenClose := Chr(0xE001)

while i <= len {
ch := SubStr(text, i, 1)

if (ch = tokenOpen) {
endPos := InStr(text, tokenClose, true, i + 1)
if endPos {
result .= SubStr(text, i, endPos - i + 1)
capitalizeNextWord := false
i := endPos + 1
continue
}
}

if (ch = ".") {
result .= ch
if IsSentenceBoundaryDot(text, i) {
nextPos := NextNonSpacePosition(text, i + 1)
if (nextPos <= len && IsSentenceStartAt(text, nextPos)) {
result .= " "
capitalizeNextWord := true
i := nextPos
continue
}
}
i += 1
continue
}

if (ch = "!" || ch = "?") {
result .= ch
nextPos := NextNonSpacePosition(text, i + 1)
if (nextPos <= len && IsSentenceStartAt(text, nextPos)) {
result .= " "
capitalizeNextWord := true
i := nextPos
continue
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

NextNonSpacePosition(text, startPos) {
len := StrLen(text)
pos := startPos
while pos <= len {
ch := SubStr(text, pos, 1)
if (ch = " " || ch = "`t" || ch = Chr(160)) {
pos += 1
continue
}
break
}
return pos
}

IsSentenceStartAt(text, pos) {
ch := SubStr(text, pos, 1)
return RegExMatch(ch, "[A-Za-zА-Яа-яЁё]") || ch = Chr(0xE000)
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
nextPos := NextNonSpacePosition(text, dotPos + 1)
prevChar := prevPos >= 1 ? SubStr(text, prevPos, 1) : ""
nextChar := nextPos <= len ? SubStr(text, nextPos, 1) : ""
if RegExMatch(prevChar, "\d") && RegExMatch(nextChar, "\d") {
return false
}
if RegExMatch(prevChar, "[A-Za-zА-Яа-яЁё]") && RegExMatch(nextChar, "[A-Za-zА-Яа-яЁё]") {
lookAhead := NextNonSpacePosition(text, nextPos + 1)
if (lookAhead <= len && SubStr(text, lookAhead, 1) = ".") {
return false
}
}
return true
}

LintText(text, features := "") {
if !IsObject(features) {
features := GetDefaultFeatureState()
}
text := StrReplace(text, Chr(11), "`r`n")
text := StrReplace(text, Chr(8232), "`r`n")
if FeatureValue(features, "FixEmails") {
text := NormalizeEmails(text)
}
protected := ProtectFragments(&text, features)
if FeatureValue(features, "RemoveEmoji") {
text := RemoveEmoji(text)
}
if FeatureValue(features, "FixSymbols") {
text := RegExReplace(text, "i)\(c\)", "©")
text := RegExReplace(text, "i)\(r\)", "®")
text := RegExReplace(text, "i)\(tm\)", "™")
}
if FeatureValue(features, "FixEllipsis") {
text := StrReplace(text, "...", "…")
}
if FeatureValue(features, "FixQuotes") {
text := ConvertQuotes(text)
text := FixQuoteSpaces(text)
}
if FeatureValue(features, "FixDash") {
text := StrReplace(text, "--", "—")
text := RegExReplace(text, "[ \t" . Chr(160) . "]*—[ \t" . Chr(160) . "]*", Chr(160) . "— ")
}
if FeatureValue(features, "FixHyphens") {
text := FixRussianHyphenation(text)
text := RegExReplace(text, "(\p{L})[ \t" . Chr(160) . "]*-[ \t" . Chr(160) . "]*(\p{L})", "$1" . Chr(8209) . "$2")
}
if FeatureValue(features, "FixSpaces") {
text := RegExReplace(text, "[ \t" . Chr(160) . "]{2,}", " ")
}
if FeatureValue(features, "FixPunctuation") {
text := FixPunctuationSpaces(text)
}
if FeatureValue(features, "FixShortWords") {
text := FixShortWordSpaces(text)
}
if FeatureValue(features, "FixNumbers") {
text := RegExReplace(text, "([№§])[ \t" . Chr(160) . "]*(\d)", "$1" . Chr(160) . "$2")
}
if FeatureValue(features, "FixPhones") {
text := NormalizePhones(text)
}
text := RestoreFragments(text, protected)
return text
}

FixPunctuationSpaces(text) {
nb := Chr(160)
text := RegExReplace(text, "[ \t" . nb . "]+([.,:;!?])", "$1")
text := RegExReplace(text, "([;!?])([^\s`r`n\)\]\}»”.,:;!?…])", "$1 $2")
text := RegExReplace(text, "((?<!\d)[.,:]|[.,:](?!\d))([^\s`r`n\)\]\}»”.,:;!?…])", "$1 $2")
return text
}

NormalizeEmails(text) {
pos := 1
while RegExMatch(text, "i)([A-Z0-9._%+\-]+)\s*@\s*([A-Z0-9.\-]+)\s*\.\s*([A-Z]{2,})", &m, pos) {
original := m[0]
normalized := m[1] . "@" . StrLower(m[2] . "." . m[3])
text := SubStr(text, 1, m.Pos - 1) . normalized . SubStr(text, m.Pos + StrLen(original))
pos := m.Pos + StrLen(normalized)
}
return text
}

NormalizePhones(text) {
pos := 1
pattern := "(?<!\d)(?:\+7|8)[ \t" . Chr(160) . "\(\).-]*(\d{3})[ \t" . Chr(160) . "\).-]*(\d{3})[ \t" . Chr(160) . ".-]*(\d{2})[ \t" . Chr(160) . ".-]*(\d{2})(?!\d)"
while RegExMatch(text, pattern, &m, pos) {
original := m[0]
normalized := "+7 (" . m[1] . ") " . m[2] . "-" . m[3] . "-" . m[4]
text := SubStr(text, 1, m.Pos - 1) . normalized . SubStr(text, m.Pos + StrLen(original))
pos := m.Pos + StrLen(normalized)
}
return text
}

ProtectFragments(&text, features := "") {
if !IsObject(features) {
features := GetDefaultFeatureState()
}
protected := Map()
index := 1
dq := Chr(34)
tick := Chr(96)
patterns := []
if FeatureValue(features, "ProtectCode") {
patterns.Push("s)" . tick . tick . tick . ".*?" . tick . tick . tick)
patterns.Push(tick . "[^" . tick . "`r`n]+" . tick)
}
if FeatureValue(features, "ProtectUrls") {
patterns.Push("i)\bhttps?://[^\s<>()" . dq . "'«»]+")
patterns.Push("i)\bwww\.[^\s<>()" . dq . "'«»]+")
patterns.Push("i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b")
patterns.Push("i)\b(?:[A-Z0-9](?:[A-Z0-9-]*[A-Z0-9])?\.)+[A-Z]{2,}\b")
}
if FeatureValue(features, "ProtectPaths") {
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
Loop protected.Count {
before := text
for token, value in protected {
text := StrReplace(text, token, value)
}
if (text == before) {
break
}
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
emojiBase := "(?:[\x{1F000}-\x{1FAFF}]\x{FE0F}?|[\x{2600}-\x{27BF}]\x{FE0F})"
text := RegExReplace(text, emojiBase . "(?:\x{200D}" . emojiBase . ")*", "")
text := RegExReplace(text, "[#*0-9]\x{FE0F}?\x{20E3}", "")
return text
}