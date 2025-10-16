#Requires AutoHotkey v2.0
#SingleInstance Force

; === CONFIGURATION ===
privateServerLink := "https://www.roblox.com/share?code=2a04e742a8d8a64ea94c73f41c66ac5b&type=Server"
rejoinIntervalMs := 7200000   ; 2 hours
macroStartDelayMs := 20000     ; Delay before macro starts (20 seconds)
robloxProcess := "RobloxPlayerBeta.exe"
browserProcess := "brave.exe"

LeftX := 200
RightX := 1200
CenterY := 490
Amplitude := 150
speed := 15

global isRunning := false
global step := 0
global stepStart := 0
global mousePosX := LeftX
global nextRejoin := A_TickCount + rejoinIntervalMs

; === STARTUP ===
SetTimer(Rejoin, rejoinIntervalMs)
SetTimer(UpdateCountdown, 1000)
F6::ToggleMacro()
F8::Rejoin()

; === MACRO TOGGLE ===
ToggleMacro() {
    global isRunning
    isRunning := !isRunning

    if (isRunning) {
        ToolTip("Macro: Starting in " Round(macroStartDelayMs / 1000) "s...")
        Sleep(macroStartDelayMs)
        ToolTip("Macro: STARTED")
        Sleep(800)
        ToolTip()
        SetTimer(RunMacroStep, 25)
    } else {
        ToolTip("Macro: STOPPED")
        Sleep(800)
        ToolTip()
        SetTimer(RunMacroStep, 0)
    }
}

; === MACRO LOGIC ===
RunMacroStep() {
    global isRunning, step, stepStart, mousePosX
    global LeftX, RightX, CenterY, Amplitude, speed

    if !isRunning
        return

    ; Step 0: Hold O + Up briefly, then press 3
    if (step = 0) {
        Send("{o down}")
        Send("{Up down}")
        Sleep(20)
        Send("{Up up}")
        Sleep(300)
        Send("{o up}")
        Send("3")
        stepStart := A_TickCount
        step := 1
        return
    }

    ; Step 1: Move in wavy motion for 25 seconds
    if (step = 1) {
        Click("Down")
        elapsed := A_TickCount - stepStart
        mousePosX += speed
        if (mousePosX > RightX)
            mousePosX := LeftX
        mousePosY := CenterY + Sin(mousePosX / 50) * Amplitude
        MouseMove(mousePosX, mousePosY, 0)
        if (elapsed >= 25000) {
            Click("Up")
            stepStart := A_TickCount
            step := 2
        }
        return
    }

    ; Step 2: Press Esc → r → Enter with pauses
    if (step = 2) {
        Send("{Esc}")
        Sleep(1000)
        Send("r")
        Sleep(1000)
        Send("{Enter}")
        stepStart := A_TickCount
        step := 3
        return
    }

    ; Step 3: Wait 5 seconds before looping
    if (step = 3) {
        if (A_TickCount - stepStart >= 5000) {
            step := 0
            mousePosX := LeftX
        }
    }
}

; === AUTO REJOIN LOGIC ===
Rejoin() {
    global privateServerLink, robloxProcess, browserProcess, rejoinIntervalMs
    global isRunning, step, stepStart, mousePosX, LeftX, macroStartDelayMs, nextRejoin

    ToolTip("Auto Rejoin: Starting...")
    Sleep(500)

    ; Stop macro safely
    isRunning := false
    SetTimer(RunMacroStep, 0)

    ; Close Roblox if running
    try {
        if ProcessExist(robloxProcess) {
            ToolTip("Auto Rejoin: Closing Roblox...")
            ProcessClose(robloxProcess)
            Sleep(3000)
        }
    }

    ; Launch private server link
    ToolTip("Auto Rejoin: Opening server link...")
    Run(privateServerLink)
    Sleep(4000)

    ; Wait up to 15s for Roblox
    loop 15 {
        if ProcessExist(robloxProcess) {
            ToolTip("Auto Rejoin: Roblox detected, closing browser...")
            Sleep(2000)
            break
        }
        Sleep(1000)
    }

    ; Close browser
    try {
        if ProcessExist(browserProcess)
            ProcessClose(browserProcess)
    }

    ; Wait before starting macro again
    ToolTip("Auto Rejoin: Waiting " Round(macroStartDelayMs / 1000) "s before restarting macro...")
    Sleep(macroStartDelayMs)

    ; Reset and restart macro
    step := 0
    mousePosX := LeftX
    isRunning := true
    SetTimer(RunMacroStep, 25)

    nextRejoin := A_TickCount + rejoinIntervalMs
    ToolTip("Auto Rejoin: Completed — Macro Restarted")
    Sleep(1500)
    ToolTip()
}

; === COUNTDOWN DISPLAY ===
UpdateCountdown() {
    global nextRejoin, rejoinIntervalMs
    remaining := nextRejoin - A_TickCount
    if (remaining <= 0) {
        nextRejoin := A_TickCount + rejoinIntervalMs
        remaining := rejoinIntervalMs
    }
    hours := Floor(remaining / 3600000)               ; 1 hour = 3600000 ms
    mins := Floor(Mod(remaining / 60000, 60))        ; remaining minutes
    secs := Floor(Mod(remaining / 1000, 60))         ; remaining seconds
    ToolTip("Next Auto Rejoin in " hours "h " mins "m " secs "s", 10, 10)
}

; === HELPER ===
ProcessExist(Name) {
    for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process Where Name='" Name "'")
        return true
    return false
}

Persistent
