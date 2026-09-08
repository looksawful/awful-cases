#Requires AutoHotkey v2.0
#Include ..\app\awful-cases.ahk

class FakeDropDown {
    __New(text := "") {
        this.Text := text
        this.Choice := 0
    }

    Choose(index) {
        this.Choice := index
    }
}

class FakeCheckbox {
    __New(value := 0) {
        this.Value := value
    }
}

originalConfigPath := ConfigPath
testConfigPath := A_Temp . "\awful-cases-reset-test.ini"
try FileDelete(testConfigPath)
FileAppend("[Ui]`nLanguage=en`n[Hotkeys]`nUpper=F13`n", testConfigPath, "UTF-8")
ConfigPath := testConfigPath

hotkeyControls := Map("Upper", FakeDropDown("F13"))
featureControls := Map("FixDash", FakeCheckbox(0))
langDdl := FakeDropDown("EN")
keyChoices := ["Up", "F13"]

ResetSettingsInPlace(hotkeyControls, featureControls, langDdl, keyChoices)
actual := FileRead(testConfigPath, "UTF-8")
expected := "[Ui]`nLanguage=en`n[Hotkeys]`nUpper=F13`n"

ConfigPath := originalConfigPath
try FileDelete(testConfigPath)
try FileDelete(A_ScriptDir . "\awful-cases.ini")

if (actual != expected) {
    FileAppend("FAIL  reset must not persist defaults before Save`n", "**")
    ExitApp(1)
}

FileAppend("PASS  reset must not persist defaults before Save`n", "*")
ExitApp(0)
