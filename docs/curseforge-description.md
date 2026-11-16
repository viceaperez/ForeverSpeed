# ForeverSpeed

**Summary (short description, max ~150 chars):**
Speedometer for WoW: Forever. Shows your speed, your target's speed and who's faster, in a movable box, on the minimap and in Titan Panel.

---

## ForeverSpeed

A light speedometer built for **WoW: Forever**. It answers one question at a glance: **can I catch them, or can they catch me?**

### What it shows
- **You**: your current movement speed.
- **Target**: your target's current movement speed, for players and NPCs.
- **Diff**: your speed minus theirs, **green** when you're faster and **red** when they are.

Two modes:
- **Current speed**: how fast everyone is moving right now.
- **Max run speed**: each unit's top run speed, even while standing still. Use it to check a chase before it starts: will Travel Form catch that Sprint?

Units: **% of run speed**, **yards/second**, or **both**.

### Where it shows
- **Floating box**: drag it anywhere, lock it, and scale it from 0.5x to 3x.
- **Minimap button**: left-click opens settings, right-click shows or hides the box. Drag it around the minimap.
- **Titan Panel** (or any LibDataBroker display): choose exactly what the bar shows, i.e. your speed, target speed and/or difference, with or without labels and colors, in its own units. A live preview in settings shows the result.

### Settings
Open with `/fspeed`, the minimap button, **Alt-click** on the Titan plugin, or **Options → AddOns → ForeverSpeed**.

### Commands
`/fspeed` opens settings. Also: `show | hide | toggle | lock | unlock | minimap | units | mode | scale <0.5-3> | reset`

### Notes
- Built for the Forever client (interface 16001). Titan Panel is optional.
- Target speed is read straight from the game and stays visible in combat.
- If a future patch hides speed values from addons, ForeverSpeed shows `--` instead of throwing errors. Your own speed then falls back to being measured from your position, which works in the open world only.
- Very light: updates 10 times per second and only redraws what's visible.

Feedback and bug reports are welcome in the comments.

---

**Suggested CurseForge fields**
- Category: *Map & Minimap* or *Miscellaneous*. Add *Data Broker* and *Titan Panel* tags if offered.
- Game version: *WoW Forever* (1.16.x).
- License: MIT.
- Screenshots to take in-game: (1) the floating box during a chase with a red/green Diff, (2) the settings window, (3) the Titan bar with labels on.
