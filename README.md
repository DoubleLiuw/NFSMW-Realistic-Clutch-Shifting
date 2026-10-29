# NFS Most Wanted (2005) - Realistic Clutch & H-Shifter for Logitech G29

An AutoHotkey script that turns the G29 H-shifter and clutch pedal into keyboard input for Need for Speed: Most Wanted (2005), with realistic clutch behaviour.

## Requirements

You need **both** of these, or it won't work:

1. **MW2005-HShifter** (game mod): https://github.com/Eradinelle/MW2005-HShifter
   Lets you pick a gear directly with the number keys.
   - Download `MW2005-HShifter.asi` from its Releases page.
   - Put it in the game folder or the game's `scripts` folder.
   - Only works with **NFS Most Wanted 1.3 Black Edition**.
2. **AutoHotkey v2**: https://www.autohotkey.com
   Runs `G29Shifter.ahk`.

In-game controls must be set to:
- Gear down: `Z`
- Brake / Reverse: `Down` arrow

## Setup

1. Install the two requirements above.
2. In Logitech G HUB, keep the pedals **not combined**.
3. Double-click `G29Shifter.ahk` to start it. A green **H** icon appears in the tray.
4. First launch only: follow the tooltip in the top-left corner. Press the clutch fully, then release it. This calibrates the clutch.
5. Start the game.

If the game runs as admin, run the script as admin too.

## Gear keys

| Shifter | Keys pressed |
|---|---|
| Gears 1-5 | `1` `2` `3` `4` `5` |
| Gear 6 / R | `1`, then `Down` |
| No gear (middle) | `1`, then `Z` (Neutral) |

## Clutch logic

- **Clutch pressed past 60%:** presses `1`, then `Z` (Neutral).
- **Shifter moved while the clutch is pressed:** presses that gear's key right away.
- **Clutch lifted below 40% without shifting:** presses the key for the gear the stick is in.
- **Shifter moved without the clutch:** nothing happens.
- **Gas while the clutch is pressed:** still drives the car, because the game reads the pedal directly.

Keys are only sent while the game (`speed.exe`) is the active window.

## Hotkeys

| Keys | Action |
|---|---|
| Ctrl+Alt+K | Realistic clutch on/off (off = shifter works without clutch) |
| Ctrl+Alt+C | Recalibrate clutch |
| Ctrl+Alt+D | Show/hide debug overlay |
| Ctrl+Alt+T | Test mode (send keys to any window, e.g. Notepad) |
| Ctrl+Alt+Q | Quit |

## Settings

These are at the top of `G29Shifter.ahk`:

| Setting | Default | What it does |
|---|---|---|
| `CLUTCH_IN` | 60 | Clutch % that counts as pressed |
| `CLUTCH_OUT` | 40 | Clutch % below which the clutch counts as released |
| `KEY_HOLD` | 50 | How long each key is held, in ms. Raise this if the game misses shifts. |
| `N_FIRST_MS` | 17 | How long the car stays in 1st on the way to Neutral, in ms |

After changing a setting, right-click the tray icon and choose **Reload Script**.
