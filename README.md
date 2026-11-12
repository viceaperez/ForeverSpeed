# ForeverSpeed

Speedometer addon for **WoW: Forever**. It shows your speed, your target's speed and the difference between them.

- **Floating frame** with You / Target / Diff. Diff is green when you're faster and red when the target is faster.
- **Titan Panel / LibDataBroker plugin**. Left-click shows or hides the frame, Shift-click switches between % and yd/s, and Ctrl-click switches between current and max speed.
- **Two modes**:
  - *current*: actual speed right now.
  - *max*: each unit's top run speed.
- **Secret values**: Forever's client can hide some values from addons. When that happens, target speed shows `--`. Your own speed then falls back to being measured from your position, which works in the open world only.

## Commands
`/fspeed show | hide | toggle | lock | unlock | units | mode | scale <0.5-3> | reset`

## Install
Copy the `ForeverSpeed` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
