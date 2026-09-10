#Requires AutoHotkey v2.0
#Include lib\assert.ahk
#Include ..\app\lib\app-paths.ahk

AssertEqual(
    "source uses side-by-side config",
    ResolveConfigPath("C:\repo\app", "C:\Users\ivan\AppData\Roaming", false, false),
    "C:\repo\app\awful-cases.ini"
)

AssertEqual(
    "compiled portable mode uses side-by-side config",
    ResolveConfigPath("D:\Portable\Awful Cases", "C:\Users\ivan\AppData\Roaming", true, true),
    "D:\Portable\Awful Cases\awful-cases.ini"
)

AssertEqual(
    "installed compiled mode uses AppData",
    ResolveConfigPath("C:\Users\ivan\AppData\Local\Programs\Awful Cases", "C:\Users\ivan\AppData\Roaming", true, false),
    "C:\Users\ivan\AppData\Roaming\Awful Cases\awful-cases.ini"
)

FinishTests("app path tests")
