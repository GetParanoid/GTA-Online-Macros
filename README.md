# GTA V Macros

AutoHotkey **v1** script ([gtav_macros.ahk](gtav_macros.ahk)) with hotkeys for GTA Online (Enhanced edition). It automates Interaction Menu and phone navigation, plus a few network toggles.

## Requirements

- [AutoHotkey v1.1](https://www.autohotkey.com/) (tested with v1.1.37.02). It will **not** run under AutoHotkey v2.
- GTA V Enhanced (`GTA5_Enhanced.exe`). Hotkeys only work while the game window is in front.
- The script restarts itself as Administrator, which the firewall and network toggles need.

## Updating

Run `update.ps1` from the script folder, either by right-clicking it and choosing **Run with PowerShell**, or with:

```powershell
powershell -ExecutionPolicy Bypass -File .\update.ps1
```

It downloads the latest files from GitHub, replaces only the ones that changed (saving a `.bak` of each), and reloads the macros if they're running. Options: `-Start` launches the script even if it wasn't running, `-NoReload` only updates the files, and `-Branch <name>` downloads a different branch. It refuses to run inside a git clone (use `git pull` there) unless you pass `-Force`.

## Running

Double-click `gtav_macros.ahk`, or right-click it and choose **Run with AutoHotkey v1**. To reload after editing, run it again: the new copy switches to Administrator, then closes the old one, so only one copy is ever running.

## Hotkeys

`RCtrl` means the **right** Ctrl key only.

| Key | Action |
|---|---|
| **F8** | Suspend / resume all macros |
| **F6** | Toggle mission mode: shows `MISSION MODE` on screen and shifts Interaction Menu rows up by 1, because the CEO/MC menu is missing in missions and heists. BST is disabled while it's on. |
| **F7** | Toggle debug mode (see below) |
| **F1** | Use Body Armor (Interaction Menu → Inventory) |
| **F2** | Eat a Snack (Interaction Menu → Inventory) |
| **[** | Drop Bull Shark Testosterone (needs CEO / MC President) |
| **F9** | Open the Style / Outfit menu |
| **F11** | Call Lester |
| **F12** | Call Simeon |
| **'** | Inventory row +1 (shows the value in a tooltip) |
| **;** | Inventory row −1 |
| **F5** | Toggle Keep-Awake (presses Numpad + every 60 s to avoid the AFK kick) |
| **Mouse back button** (XButton1) | Press Enter |
| **RCtrl+F9** | No-save mode ON (firewall blocks Rockstar's save server `192.81.241.171`) |
| **RCtrl+F12** | No-save mode OFF (removes that firewall rule) |
| **RCtrl+F5** | Internet kill switch ON (disables Wi-Fi, Ethernet, Ethernet 2, vEthernet adapters) |
| **RCtrl+F6** | Internet kill switch OFF (re-enables them) |

To change a key, edit its variable in the `; --- Hotkeys ---` block at the top of the script. Use AutoHotkey key names: `^` Ctrl, `+` Shift, `!` Alt, `>` right-side modifier.

## In-game assumptions

The macros press menu keys blindly. They only work if the game matches these assumptions:

- **Interaction Menu key is `M`** (`Interaction` variable).
- **Up arrow opens the phone.** The Contacts app is reached with Right, Up, Enter from the phone's home screen.
- **`InvLocation`** (default `4`) is how many rows down Inventory sits in the Interaction Menu. It changes with your situation, e.g. as CEO/MC vs. not, or inside heists and other jobs. Use `'` / `;` to adjust it on the fly. It resets to 4 when the script reloads.
- **BST only works as CEO / MC President in freemode.** It is generally not available inside heist missions.
- **Contact positions are counted from the top of the Contacts list** (Simeon = 1 Up, Lester = 15 Up). If your contact list changes, update the numbers.

## Adding a phone contact

```ahk
; 1. Key variable (top of file)
CallMadrazo := "f10"

; 2. Register it (with the other Hotkey lines)
Hotkey, %CallMadrazo%, CallMadrazo

; 3. Label: number = Up presses from the top of Contacts
CallMadrazo:
  CallContact(7)
  return
```

`OpenContacts()` opens the phone to the Contacts list, and `CallContact(n)` opens Contacts, presses Up `n` times and then Enter.

## Debug mode (F7)

Use this when a macro lands on the wrong menu item. While debug mode is on:

- Each macro presses **one key at a time**, holding it 80 ms and pausing 600 ms between presses.
- After opening a menu, it waits **1 s**.
- A tooltip shows the current key, e.g. `DEBUG: down (3 of 4)`, plus the full sequence.

Watch for the first step where the game doesn't follow the tooltip. Tune the speeds with `DebugStepDelay`, `DebugPressDuration` and `DebugMenuDelay`.

If a macro works in debug mode but not at full speed, the problem is timing (see Known issues), not menu positions.

## Timing settings

| Variable | Default | Meaning |
|---|---|---|
| `IntMenuDelay` | `0.1` | ms to wait after opening the Interaction Menu |
| `PhoneMenuDelay` | `550` | ms to wait after opening the phone |
| `PhoneScrollDelay` | `55` | ms between key presses on the phone |
| `KeySendDelay` / `KeyPressDuration` | `50` / `15` | Intended delay between and duration of key presses (currently not applied; see below) |

## Known issues

- **`setkeydelay, KeySendDelay, KeyPressDuration` never runs.** It sits after the startup `return`, so Interaction Menu macros use AutoHotkey's default (very fast) key timing.
- **`IntMenuDelay` is 0.1 ms**, effectively no wait. If macros miss intermittently, try around `150`.
- **Keep-Awake keeps sending Numpad + even if you alt-tab out**, into whatever window is in front.
- **No-save mode and the kill switch are left on if you close the script** while they're active. Turn them off first, or fix them manually: delete the firewall rule named `GTAV Macros - No-Save Mode (block 192.81.241.171)`, and re-enable the adapters in Network Connections.
