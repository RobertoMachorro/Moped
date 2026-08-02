; Sample.ahk — declared/openable by Moped but has no tokenizer.
; Should open and display as plain text with no syntax coloring.

#Requires AutoHotkey v2.0

Greet(name) {
    MsgBox "Hello, " . name . "!"
}

^g::Greet("Moped")
