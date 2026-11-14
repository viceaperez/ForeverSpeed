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

## Code layout
Modules share the addon namespace and never call each other's UI directly. They talk through a small event bus (`ns.On` / `ns.Fire`) and read or write settings with `ns.Get` / `ns.Set`. `ns.Set` fires `SETTING_CHANGED`.

| File | Responsibility |
|---|---|
| `Core.lua` | Constants, defaults, saved variables, event bus, settings access, 0.1 s ticker |
| `Format.lua` | Pure text formatting: unit styles, the difference verdict and its color |
| `Speed.lua` | Speed sources in priority order: game API first, then a position-based fallback |
| `Tooltip.lua` | Shared speed tooltip |
| `Views/Display.lua` | Floating You / Target / Diff box |
| `Views/Broker.lua` | LibDataBroker data source (Titan Panel) |
| `Views/Minimap.lua` | Minimap button |
| `Settings/Widgets.lua` | Generic controls: check, cycle, slider, button, text |
| `Settings/Options.lua` | The settings window's contents, as data |
| `Settings/Window.lua` | Builds the window from Options, plus the Options → AddOns entry |
| `Commands.lua` | `/fspeed` command table |

**Extending**
- New setting: add a default in `Core.lua`, add one line in `Options.lua`, and react to `SETTING_CHANGED` in the view that uses it.
- New unit style: add one entry to `Format.units` and `Format.unitOrder`.
- New speed source: `ns.Speed:AddSource({ Read = function(self, unit, mode) ... end })`.
- New command: add one entry to the `commands` table.

## Tests
`cd tests && npm install && npm test` lints every file and runs the addon headless against stubbed game functions.
