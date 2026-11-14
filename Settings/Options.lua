-- Options: what the settings window shows, as data.
-- Adding a setting = add a default in Core.lua + one line here (+ react to it in its view).

local _, ns = ...
local F = ns.Format

local function UnitName(v) return F.units[v].name end
local function ModeName(v) return F.modes[v] end

ns.Options = {
	{ type = "header", text = "General" },
	{ type = "check", key = "showFrame", label = "Show floating speed display" },
	{ type = "check", key = "locked", label = "Lock floating display" },
	{ type = "check", key = "minimap.hide", label = "Show minimap button", invert = true },
	{ type = "cycle", key = "units", label = "Display units", values = F.unitOrder, text = UnitName },
	{ type = "cycle", key = "mode", label = "Speed mode", values = F.modeOrder, text = ModeName },
	{ type = "slider", key = "scale", label = "Display scale",
		min = ns.SCALE.min, max = ns.SCALE.max, step = ns.SCALE.step, format = "%.2fx" },
	{ type = "button", text = "Reset display position", event = "RESET_POSITION" },

	{ type = "header", text = "Titan Panel bar" },
	{ type = "check", key = "titan.showMe", label = "Show your speed" },
	{ type = "check", key = "titan.showTarget", label = "Show target speed" },
	{ type = "check", key = "titan.showDiff", label = "Show difference" },
	{ type = "check", key = "titan.labels", label = "Show labels (You / Tgt / Diff)" },
	{ type = "check", key = "titan.color", label = "Color the difference green / red" },
	{ type = "cycle", key = "titan.units", label = "Titan units", values = F.unitOrder, text = UnitName },
	{ type = "text", label = "Preview: ", event = "BROKER_TEXT", get = function() return ns.Broker.text end },
}
