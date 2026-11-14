-- Commands: /fspeed. One table entry per command; add a command by adding an entry.

local _, ns = ...
local F = ns.Format

local function OpenSettings() ns.Fire("TOGGLE_SETTINGS") end

local commands = {
	[""] = OpenSettings,
	config = OpenSettings,
	settings = OpenSettings,
	options = OpenSettings,
	show = function() ns.Set("showFrame", true) end,
	hide = function() ns.Set("showFrame", false) end,
	toggle = function() ns.Toggle("showFrame") end,
	lock = function()
		ns.Set("locked", true); ns.Print("display locked")
	end,
	unlock = function()
		ns.Set("locked", false); ns.Print("display unlocked (drag to move)")
	end,
	minimap = function()
		ns.Toggle("minimap.hide")
		ns.Print(ns.db.minimap.hide and "minimap button hidden" or "minimap button shown")
	end,
	units = function()
		ns.Cycle("units", F.unitOrder); ns.Print("units: " .. F.units[ns.db.units].name)
	end,
	mode = function()
		ns.Cycle("mode", F.modeOrder); ns.Print("mode: " .. F.modes[ns.db.mode])
	end,
	scale = function(arg)
		local v = tonumber(arg)
		if not v then return false end
		ns.Set("scale", math.max(ns.SCALE.min, math.min(ns.SCALE.max, v)))
	end,
	reset = function()
		ns.Fire("RESET_POSITION"); ns.Set("scale", 1)
	end,
}

local USAGE = "/fspeed (settings) | show | hide | toggle | lock | unlock | minimap | units | mode | scale <0.5-3> | reset"

SLASH_FOREVERSPEED1 = "/fspeed"
SLASH_FOREVERSPEED2 = "/foreverspeed"
SlashCmdList.FOREVERSPEED = function(msg)
	local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.-)$")
	local handler = commands[cmd]
	if not handler or handler(arg) == false then ns.Print(USAGE) end
end
