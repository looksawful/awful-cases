#Requires AutoHotkey v2.0
#Include lib\assert.ahk
#Include ..\app\lib\app-links.ahk

AssertEqual(
    "training URL uses canonical Awful Cases course",
    GetTrainingUrl(),
    "https://looksawful.ru/work/awful-cases/"
)

AssertFalse(
    "training URL is not local-only",
    InStr(GetTrainingUrl(), "127.0.0.1") > 0 || InStr(GetTrainingUrl(), "localhost") > 0
)

FinishTests("training link tests")
