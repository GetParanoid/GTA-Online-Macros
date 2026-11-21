#NoEnv
SetWorkingDir %A_ScriptDir%
#IfWinActive ahk_exe GTA5_Enhanced.exe
#SingleInstance, Off               ; handled manually below (a non-admin copy can't close an admin one)

; --- Hotkeys ---  (^ = Ctrl, + = Shift, > = right-side modifier only)
SuspendKey := "f8"                  ; F8: toggle all macros on/off
DebugKey := "f7"                    ; F7: toggle debug mode (slow, step-by-step key presses)
MissionKey := "f6"                  ; F6: toggle mission mode (no CEO/MC row, so menu rows shift up 1)
KeepAwake := "f5"                   ; F5: toggle anti-AFK (taps Numpad+ every 60s)
BST := "["                          ; [: drop Bull Shark Testosterone (CEO/MC Abilities)
Armor := "F1"                       ; F1: use Body Armor from Inventory
Snack := "F2"                       ; F2: eat a Snack from Inventory
Outfit := "f9"                      ; F9: open the Style/Outfit menu
CallSimeon := "f12"                 ; F12: open phone and call Simeon
CallLester := "f11"                 ; F11: open phone and call Lester
IncInventoryLocation := "'"         ; ': Inventory is one row lower in the Interaction Menu (+1)
DecInventoryLocation := ";"         ; ;: Inventory is one row higher in the Interaction Menu (-1)
NoSaveModeOn := ">^f9"              ; RCtrl+F9: firewall-block the save server (no-save mode)
NoSaveModeOff := ">^f12"            ; RCtrl+F12: remove that firewall rule
InternetKillSwitchOn := ">^f5"      ; RCtrl+F5: disable all network adapters
InternetKillSwitchOff := ">^f6"     ; RCtrl+F6: re-enable all network adapters

global KeepAwakeBool := false
global InvLocation := 4
global MissionMode := false         ; true in missions/heists: the CEO/MC row is missing from the menu
global NoSaveRuleName := "GTAV Macros - No-Save Mode (block 192.81.241.171)"

global ToolTip1 := false
global ToolTip2 := false
global ToolTip3 := false

EnterKey := "XButton1"              ; Mouse back button: press Enter
Interaction := "m"                  ; M: your in-game Interaction Menu key (sent by macros, not a hotkey)

global IntMenuDelay := 150          ; ms to wait for the Interaction Menu to open
global SubMenuDelay := 100          ; ms to wait after entering a submenu (e.g. Inventory)
global KeySendDelay := 50           ; ms between key presses
global KeyPressDuration := 30       ; ms each key is held (keep above one frame, ~17ms at 60fps)
global PhoneMenuDelay := 550
global PhoneScrollDelay := 55

; --- Debug mode ---
global DebugMode := false
global DebugStepDelay := 600        ; ms to wait after each key press in debug mode
global DebugPressDuration := 80     ; ms each key is held down in debug mode
global DebugMenuDelay := 1000       ; ms to wait after opening a menu in debug mode

; --- Startup: run as admin, single instance ---
; Relaunch as Administrator, then exit this non-admin copy.
if not A_IsAdmin {
  try {
    if A_IsCompiled
      Run *RunAs "%A_ScriptFullPath%"
    else
      Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
  }
  ExitApp
}

; Now running as admin: close any older copy of this script so this one replaces it.
DetectHiddenWindows, On
SetTitleMatchMode, 2
WinGet, oldCopies, List, %A_ScriptFullPath% ahk_class AutoHotkey
Loop, %oldCopies% {
  oldHwnd := oldCopies%A_Index%
  if (oldHwnd != A_ScriptHwnd) {
    PostMessage, 0x111, 65307,,, ahk_id %oldHwnd%   ; ask it to exit (same as tray > Exit)
    WinWaitClose, ahk_id %oldHwnd%,, 2
  }
}
DetectHiddenWindows, Off
SetTitleMatchMode, 1

SetKeyDelay, %KeySendDelay%, %KeyPressDuration%   ; default for every macro

Hotkey, %SuspendKey%, SuspendToggle
Hotkey, %DebugKey%, DebugToggle
Hotkey, %MissionKey%, MissionToggle
Hotkey, %EnterKey%, EnterKey
Hotkey, %KeepAwake%, KeepAwake
Hotkey, %BST%, BST
Hotkey, %Armor%, Armor
Hotkey, %Snack%, Snack
Hotkey, %Outfit%, Outfit
Hotkey, %CallSimeon%, CallSimeon
Hotkey, %CallLester%, CallLester
Hotkey, %IncInventoryLocation%, IncInventoryLocation
Hotkey, %DecInventoryLocation%, DecInventoryLocation
Hotkey, %NoSaveModeOn%, NoSaveModeOn
Hotkey, %NoSaveModeOff%, NoSaveModeOff
Hotkey, %InternetKillSwitchOn%, InternetKillSwitchOn
Hotkey, %InternetKillSwitchOff%, InternetKillSwitchOff
return

SuspendToggle:
  Suspend
  return

DebugToggle:
  DebugMode := !DebugMode
  if (DebugMode) {
    TrayTip, Debug Mode, ON - macros will press keys slowly, 1
    ToolTip, DEBUG MODE, 10, 200, 5
  } else {
    TrayTip, Debug Mode, OFF, 1
    ToolTip,,,,5
  }
  return

MissionToggle:
  MissionMode := !MissionMode
  if (MissionMode) {
    TrayTip, Mission Mode, ON - Interaction Menu rows shifted up 1 (no CEO/MC menu), 1
    ToolTip, MISSION MODE, 10, 170, 6
  } else {
    TrayTip, Mission Mode, OFF, 1
    ToolTip,,,,6
  }
  return

EnterKey:
  Send {Enter down}
  Sleep 50
  Send {Enter up}
  return

KeepAwake:
  KeepAwakeBool := !KeepAwakeBool
  if (KeepAwakeBool) {
    SetTimer, SendKeepAwake, 60000
    TrayTip, Keep-Awake, ACTIVATED, 1
  } else {
    SetTimer, SendKeepAwake, Off
    TrayTip, Keep-Awake, DEACTIVATED, 1
  }
  return

SendKeepAwake:
  Send {NumpadAdd}
  return

BST:
  if (MissionMode) {                ; BST lives in the CEO/MC menu, which isn't there in missions
    ToolTip, BST unavailable in Mission Mode, 10, 140, 7
    SetTimer, RemoveToolTip7, -2000
    return
  }
  SendSeq("{" Interaction "}")
  MenuWait(IntMenuDelay)
  SendSeq("{enter}{up 3}{enter}{down}{enter}")
  return

Armor:
  SendSeq("{" Interaction "}")
  MenuWait(IntMenuDelay)
  SendSeq("{down " MenuRow(InvLocation) "}{enter}")
  MenuWait(SubMenuDelay)
  SendSeq("{down 1}{enter}{up 3}{enter}{" Interaction "}")
  return

Snack:
  SendSeq("{" Interaction "}")
  MenuWait(IntMenuDelay)
  SendSeq("{down " MenuRow(InvLocation) "}{enter}")
  MenuWait(SubMenuDelay)
  SendSeq("{down 2}{enter 4}{" Interaction "}")
  return

Outfit:
  StyleLocation := MenuRow(InvLocation + 1)
  SendSeq("{" Interaction "}")
  MenuWait(IntMenuDelay)
  SendSeq("{down " StyleLocation "}{enter}{down 3}")
  return

CallSimeon:
  ; dialNumber(6115550120)
  CallContact(1)
  return

CallLester:
  CallContact(15)
  return

; Opens the phone's Contacts list and leaves the cursor on the first contact.
OpenContacts() {
  SendSeq("{up}")                   ; Up arrow opens the phone
  MenuWait(PhoneMenuDelay)          ; give the phone time to come up
  SetKeyDelay, %PhoneScrollDelay%, %KeyPressDuration%
  SendSeq("{right}{up}{enter}")     ; move to the Contacts app and open it
}

; Opens Contacts, presses Up `ups` times to reach a contact, then calls them.
CallContact(ups) {
  OpenContacts()
  SetKeyDelay, %PhoneScrollDelay%, %KeyPressDuration%
  SendSeq("{up " ups "}{enter}")
}

; Sends a key sequence like "{down 4}{enter}". In debug mode, presses each key
; one at a time, slowly, and shows which key/step is being pressed in a tooltip.
SendSeq(seq) {
  if (!DebugMode) {
    Send %seq%
    return
  }
  SetKeyDelay, 0, %DebugPressDuration%
  pos := 1
  while (pos := RegExMatch(seq, "\{(\w+)(?: (\d+))?\}", m, pos)) {
    count := (m2 != "") ? m2 : 1
    Loop, %count%
    {
      ToolTip, DEBUG: %m1%  (%A_Index% of %count%)`nsequence: %seq%, 10, 230, 4
      Send {%m1%}
      Sleep, %DebugStepDelay%
    }
    pos += StrLen(m)
  }
  ToolTip,,,,4
}

; Converts a normal Interaction Menu row to the actual one: in Mission Mode the
; CEO/MC row is missing, so everything sits one row higher.
MenuRow(row) {
  return MissionMode ? row - 1 : row
}

; Waits for a menu to open: the normal delay, or DebugMenuDelay in debug mode.
MenuWait(normalDelay) {
  if (DebugMode) {
    ToolTip, DEBUG: waiting for menu..., 10, 230, 4
    Sleep, %DebugMenuDelay%
  } else {
    Sleep, %normalDelay%
  }
}

IncInventoryLocation:
  InvLocation++

  ToolTip1 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10

  ToolTip, INVENTORY=%InvLocation%, 10, %yPos%, 1
  SetTimer, RemoveToolTip1, -3000
  return

DecInventoryLocation:
  InvLocation--
  if (InvLocation < 1)
    InvLocation := 1

  Tooltip1 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10

  Tooltip, INVENTORY=%InvLocation%, 10, %yPos%, 1
  SetTimer, RemoveToolTip1, -3000
  return

NoSaveModeOn:
  RunWait netsh advfirewall firewall add rule name="%NoSaveRuleName%" dir=out action=block remoteip="192.81.241.171" ,,hide

  ToolTip2 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10

  Tooltip, NO SAVING MODE ON, 10, %yPos%, 2
  return

NoSaveModeOff:
  RunWait netsh advfirewall firewall delete rule name="%NoSaveRuleName%" ,,hide

  n := getActiveToolTips()
  ToolTip2 := false
  yPos := n * 25 + 10

  ToolTip, NO SAVING MODE OFF, 10, %yPos%, 2
  SetTimer, RemoveToolTip2, -3000
  return

InternetKillSwitchOn:
  run, *runas %comspec% /c netsh interface set interface name="Wi-Fi" admin=disabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="Ethernet" admin=disabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="Ethernet 2" admin=disabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="vEthernet (Default Switch)" admin=disabled,,hide

  ToolTip3 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10

  Tooltip, INTERNET KILL SWITCH ON, 10, %yPos%, 3
  return

InternetKillSwitchOff:
  run, *runas %comspec% /c netsh interface set interface name="Wi-Fi" admin=enabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="Ethernet" admin=enabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="Ethernet 2" admin=enabled,,hide
  run, *runas %comspec% /c netsh interface set interface name="vEthernet (Default Switch)" admin=enabled,,hide

  n := getActiveToolTips()
  ToolTip3 := false
  yPos := n * 25 + 10

  ToolTip, INTERNET KILL SWITCH OFF, 10, %yPos%, 3
  SetTimer, RemoveToolTip3, -3000
  return

dialNumber(n) {
  Send {MButton}
  sleep, PhoneMenuDelay
  setkeydelay PhoneScrollDelay, KeyPressDuration
  Send {up}{right}{enter}{space}
  pointer := 1
  Loop, parse, n
  {
    deltax := _phonePointerCol(A_LoopField) - _phonePointerCol(pointer)
    deltay := _phonePointerRow(A_LoopField) - _phonePointerRow(pointer)

    if (deltax = 2)
      deltax := -1
    if (deltax = -2)
      deltax := 1
    if (deltay = -3)
      deltay := 1
    if (deltay = 3)
      deltay := -1

    if (deltax > 0)
      Send {right %deltax%}
    if (deltay > 0)
      Send {down %deltay%}
    if (deltax < 0) {
      deltax := Abs(deltax)
      Send {left %deltax%}
    }
    if (deltay < 0) {
      deltay := Abs(deltay)
      Send {up %deltay%}
    }

    pointer := A_LoopField
    Send {enter}
  }
  Send {space}
}

_phonePointerRow(n) {
  if (n = 0)
    return 4
  else
    return Ceil(n / 3)
}

_phonePointerCol(n) {
  if (n = 0)
    return 2
  else
    div := Mod(n, 3)
    return div = 0 ? 3 : div
}

getActiveToolTips() {
  ToolTipCounter := -1
  if (ToolTip1)
    ToolTipCounter++
  if (ToolTip2)
    ToolTipCounter++
  if (ToolTip3)
    ToolTipCounter++
  return ToolTipCounter
}

RemoveToolTip1:
  Tooltip,,,,1
  ToolTip1 := false
  return

RemoveToolTip2:
  Tooltip,,,,2
  return

RemoveToolTip3:
  Tooltip,,,,3
  return

RemoveToolTip7:
  Tooltip,,,,7
  return
