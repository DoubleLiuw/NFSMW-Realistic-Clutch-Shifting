; G29 H-shifter + clutch -> keyboard for NFS Most Wanted (AutoHotkey v2)
;
;   Shifter button 13-17  -> keys 1-5
;   Shifter button 18/19  -> Reverse  (tap 1, then tap Down)
;   No gear button        -> Neutral  (tap 1, then tap Z)
;
; Realistic clutch mode (default ON):
;   Clutch pressed fully  -> Neutral
;   Shifting while the clutch is in engages the gear immediately
;   Moving the shifter with the clutch up does nothing
;
; Hotkeys:
;   Ctrl+Alt+K  toggle realistic clutch mode
;   Ctrl+Alt+C  calibrate clutch
;   Ctrl+Alt+D  toggle debug overlay
;   Ctrl+Alt+T  toggle test mode (send keys in any window, e.g. Notepad)
;   Ctrl+Alt+Q  quit

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ---------- settings ----------
GAME_EXE   := "speed.exe"   ; NFS Most Wanted executable
KEY_HOLD   := 50            ; ms each key is held down (raise if the game misses keys)
KEY_GAP    := 60            ; ms between the two taps of Reverse
N_FIRST_MS := 17            ; ms the car spends in 1st on the way to Neutral (~1 frame at 60 fps)
CLUTCH_IN  := 60            ; clutch % that counts as "pressed in"
CLUTCH_OUT := 40            ; clutch % below which the clutch counts as released
POLL_MS    := 10

GEAR_BUTTONS := Map(13, "1", 14, "2", 15, "3", 16, "4", 17, "5", 18, "R", 19, "R")
INI := A_ScriptDir "\G29Shifter.ini"

; ---------- state ----------
joy        := 0
clutchAxis := IniRead(INI, "Clutch", "Axis", "")
clutchRest := Number(IniRead(INI, "Clutch", "Rest", "0"))
clutchFull := Number(IniRead(INI, "Clutch", "Full", "100"))
realistic  := IniRead(INI, "Options", "Realistic", "1") = "1"
debug      := false
testMode   := false
engaged    := "?"           ; gear we last sent to the game
clutchIn   := false
prevPos    := "N"           ; shifter position on the previous tick
calibrating := false

SendMode "Event"
SetKeyDelay KEY_GAP, KEY_HOLD
DllCall("winmm\timeBeginPeriod", "UInt", 1)   ; 1 ms Sleep precision for the fast Neutral shift
CoordMode "ToolTip", "Screen"
A_IconTip := "G29 Shifter"

joy := FindG29()
if !joy {
    MsgBox "Could not find the G29. Plug it in, then reload this script.", "G29 Shifter", "Icon!"
    ExitApp
}
if (clutchAxis = "")
    Calibrate()
SetTimer Tick, POLL_MS
Flash("G29 Shifter running (joystick " joy ")  -  realistic clutch: " (realistic ? "ON" : "OFF"))

; ---------- hotkeys ----------
^!k:: {
    global realistic, engaged, clutchIn
    realistic := !realistic
    IniWrite realistic ? "1" : "0", INI, "Options", "Realistic"
    engaged := "?", clutchIn := false
    Flash("Realistic clutch: " (realistic ? "ON" : "OFF"))
}
^!c:: Calibrate()
^!d:: {
    global debug
    debug := !debug
    if !debug
        ToolTip(, , , 1)
}
^!t:: {
    global testMode
    testMode := !testMode
    Flash("Test mode: " (testMode ? "ON (keys go to any window)" : "OFF (keys only go to " GAME_EXE ")"))
}
^!q:: ExitApp

; ---------- main loop ----------
Tick() {
    global engaged, clutchIn, prevPos
    if calibrating
        return
    pos := ReadShifter()
    c := ClutchPct()
    active := testMode || WinActive("ahk_exe " GAME_EXE)

    if active {
        if !realistic {
            if (pos != engaged)
                Engage(pos)
        } else if (!clutchIn && c >= CLUTCH_IN) {
            clutchIn := true
            if (engaged != "N")
                Engage("N")
        } else if (clutchIn && c < CLUTCH_OUT) {
            ; clutch lifted without moving the shifter: stick is still in its gear
            clutchIn := false
            if (pos != engaged)
                Engage(pos)
        } else if (clutchIn && pos != prevPos) {
            ; shifted while the clutch is in: gear goes in right away
            Engage(pos)
        }
    }
    prevPos := pos

    if debug
        ToolTip("Shifter: " pos "   Clutch: " Round(c) "%" (clutchIn ? " (IN)" : "")
            . "`nEngaged: " engaged "   Realistic: " (realistic ? "ON" : "OFF")
            . "`nSending: " (active ? "yes" : "no - " GAME_EXE " not active") (testMode ? "  [TEST MODE]" : ""),
            10, 10, 1)
}

Engage(gear) {
    global engaged
    switch gear {
        case "N":                           ; 1, Z - pass through 1st as briefly as possible
            SetKeyDelay -1, -1
            Send "{sc002 down}"
            Sleep N_FIRST_MS
            Send "{sc002 up}{sc02C down}"
            Sleep KEY_HOLD
            Send "{sc02C up}"
        case "R": Send "{sc002}{Down}"      ; 1, Down
        default:  Send "{sc00" (gear + 1) "}" ; 1-5 -> sc002-sc006
    }
    engaged := gear
}

ReadShifter() {
    for btn, gear in GEAR_BUTTONS
        if GetKeyState(joy "Joy" btn)
            return gear
    return "N"
}

ClutchPct() {
    if (clutchAxis = "" || clutchFull = clutchRest)
        return 0
    v := GetKeyState(joy "Joy" clutchAxis)
    if (v = "")
        return 0
    p := (v - clutchRest) / (clutchFull - clutchRest) * 100
    return Max(0, Min(100, p))
}

; ---------- setup helpers ----------
FindG29() {
    fallback := 0
    Loop 16 {
        name := GetKeyState(A_Index "JoyName")
        if (name = "")
            continue
        if InStr(name, "G29")
            return A_Index
        if (!fallback && GetKeyState(A_Index "JoyButtons") >= 19)
            fallback := A_Index
    }
    return fallback
}

ReadAxes() {
    axes := Map()
    for a in ["X", "Y", "Z", "R", "U", "V"] {
        v := GetKeyState(joy "Joy" a)
        if (v != "")
            axes[a] := v
    }
    return axes
}

Calibrate() {
    global calibrating, clutchAxis, clutchRest, clutchFull, engaged, clutchIn
    calibrating := true
    ; press first: G29 pedals report 50% until they've been moved once
    Countdown("Clutch calibration: press the CLUTCH fully and HOLD it", 4)
    full := ReadAxes()
    Countdown("Now RELEASE all pedals", 3)
    rest := ReadAxes()

    best := "", bestDelta := 0
    for a, v in rest
        if full.Has(a) && Abs(full[a] - v) > bestDelta
            best := a, bestDelta := Abs(full[a] - v)

    if (bestDelta < 20) {
        MsgBox "Calibration failed: no clutch movement detected.`n`nRealistic clutch mode won't shift until the clutch is calibrated. Press Ctrl+Alt+C to retry.", "G29 Shifter", "Icon!"
    } else {
        clutchAxis := best, clutchRest := rest[best], clutchFull := full[best]
        IniWrite clutchAxis, INI, "Clutch", "Axis"
        IniWrite clutchRest, INI, "Clutch", "Rest"
        IniWrite clutchFull, INI, "Clutch", "Full"
        Flash("Clutch = axis " best "  (" Round(clutchRest) " -> " Round(clutchFull) "). Release the clutch.", 3000)
    }
    engaged := "?", clutchIn := false
    calibrating := false
}

Countdown(msg, secs) {
    Loop secs {
        ToolTip(msg "  (" (secs - A_Index + 1) ")", 10, 10, 2)
        Sleep 1000
    }
    ToolTip(, , , 2)
}

Flash(msg, ms := 2500) {
    ToolTip(msg, 10, 60, 3)
    SetTimer () => ToolTip(, , , 3), -ms
}
