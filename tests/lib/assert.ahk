global TestFailures := 0

TestValuesEqual(actual, expected) {
    return actual == expected
}

AssertEqual(name, actual, expected) {
    global TestFailures
    if TestValuesEqual(actual, expected) {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    TestFailures += 1
    FileAppend("FAIL  " . name . "`n  expected: " . expected . "`n  actual:   " . actual . "`n", "**")
}

AssertTrue(name, value) {
    global TestFailures
    if value {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    TestFailures += 1
    FileAppend("FAIL  " . name . "`n  expected truthy value`n", "**")
}

AssertFalse(name, value) {
    global TestFailures
    if !value {
        FileAppend("PASS  " . name . "`n", "*")
        return
    }

    TestFailures += 1
    FileAppend("FAIL  " . name . "`n  expected falsy value`n", "**")
}

FinishTests(label := "tests") {
    global TestFailures
    if TestFailures > 0 {
        FileAppend("`n" . TestFailures . " " . label . " failed.`n", "**")
        ExitApp(1)
    }

    FileAppend("`nAll " . label . " passed.`n", "*")
    ExitApp(0)
}
