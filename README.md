# ForeverSpeed

Speedometer addon for **WoW: Forever**. It shows your speed, your target's speed and the difference between them.

- **Floating frame** with You / Target / Diff. Diff is green when you're faster and red when the target is faster.
- **Titan Panel / LibDataBroker plugin**. Left-click shows or hides the frame, Shift-click switches between % and yd/s, and Ctrl-click switches between current and max speed.
- **Minimap button** (drag to move). Left-click opens settings, right-click toggles the floating display.
- **Settings window** (`/fspeed`, the minimap button, Alt-click on Titan, or Options → AddOns):
  - Show or hide the floating display and the minimap button, lock the display, units (% / yd/s / both), mode, scale.
  - Titan bar: choose which values to show (your speed, target speed, difference), labels on or off, green/red colors on or off, and Titan-only units. A live preview shows the result.
- **Two modes**:
  - *current*: actual speed right now.
  - *max*: each unit's top run speed.
- **Secret values**: Forever's client can hide some values from addons. When that happens, target speed shows `--`. Your own speed then falls back to being measured from your position, which works in the open world only.

## Commands
`/fspeed` opens settings. Also: `show | hide | toggle | lock | unlock | minimap | units | mode | scale <0.5-3> | reset`

## Install
Copy the `ForeverSpeed` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
