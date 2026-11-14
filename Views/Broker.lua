-- Broker: LibDataBroker data source. Titan Panel (or any LDB display) shows it.
-- Builds its text from the titan.* settings and publishes it as BROKER_TEXT.

local _, ns = ...
local F = ns.Format

local Broker = { text = "--" }
ns.Broker = Broker

local parts = {} -- reused every tick

local function BuildText(s)
	local t = ns.db.titan
	local n = 0
	if t.showMe then
		n = n + 1; parts[n] = (t.labels and "You " or "") .. F.Speed(s.me, t.units)
	end
	if s.hasTarget and t.showTarget then
		n = n + 1; parts[n] = (t.labels and "Tgt " or "") .. F.Speed(s.tg, t.units)
	end
	if s.hasTarget and t.showDiff then
		n = n + 1; parts[n] = (t.labels and "Diff " or "") .. (F.Delta(s.me, s.tg, t.units, t.color))
	end
	if n == 0 then
		return s.hasTarget and F.DASH or "|cff808080no target|r"
	end
	return table.concat(parts, t.labels and "  " or " | ", 1, n)
end

local HINTS = {
	"|cffeda55fLeft-click|r: toggle display   |cffeda55fAlt-click|r: settings",
	"|cffeda55fShift-click|r: units   |cffeda55fCtrl-click|r: current / max",
}

local function CreateDataObject()
	if Broker.obj then return end
	local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
	if not LDB then return end
	Broker.obj = LDB:NewDataObject("ForeverSpeed", {
		type = "data source",
		label = "Speed",
		text = Broker.text,
		icon = ns.ICON,
		category = "Information",
		OnTooltipShow = function(tt) ns.ShowTooltip(tt, HINTS) end,
		OnClick = function(_, button)
			if button ~= "LeftButton" then return end
			if IsAltKeyDown() then ns.Fire("TOGGLE_SETTINGS")
			elseif IsShiftKeyDown() then ns.Cycle("units", F.unitOrder)
			elseif IsControlKeyDown() then ns.Cycle("mode", F.modeOrder)
			else ns.Toggle("showFrame") end
		end,
	})
end

function Broker:IsAvailable()
	return self.obj ~= nil
end

ns.On("INIT", CreateDataObject)
ns.On("LOGIN", CreateDataObject) -- LDB may be registered by a later-loading addon

ns.On("TICK", function(s)
	local text = BuildText(s)
	if text == Broker.text then return end
	Broker.text = text
	if Broker.obj then Broker.obj.text = text end
	ns.Fire("BROKER_TEXT", text)
end)
