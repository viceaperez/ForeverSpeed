-- Core: constants, saved settings, event bus, ticker.
-- Modules never call each other's UI directly; they talk through ns.On / ns.Fire
-- and read/write settings through ns.Get / ns.Set (which fires SETTING_CHANGED).
--
-- Bus events:
--   INIT                  saved variables ready (ns.db)
--   LOGIN                 PLAYER_LOGIN (UI fully built, Minimap sized)
--   TICK (state)          new speed sample, every ns.TICK seconds
--   SETTING_CHANGED (path, value)
--   TOGGLE_SETTINGS       open/close the settings window
--   RESET_POSITION        put the floating display back to its default spot
--   BROKER_TEXT (text)    Titan/LDB text changed

local ADDON, ns = ...

ns.ADDON = ADDON
ns.BASE_RUN = 7         -- yd/s = 100% (normal run speed)
ns.TICK = 0.1           -- update interval (s)
ns.ICON = "Interface\\Icons\\Ability_Rogue_Sprint"
ns.SCALE = { min = 0.5, max = 3, step = 0.05 }

ns.defaults = {
	units = "pct",          -- floating display: see Format.units
	mode = "current",       -- "current" (actual speed now) | "max" (run-speed potential)
	showFrame = true,       -- floating display
	locked = false,
	scale = 1,
	point = { "CENTER", "UIParent", "CENTER", 0, -180 },
	minimap = { hide = false, angle = 225 },
	titan = {
		showMe = true,
		showTarget = true,
		showDiff = true,
		labels = false,
		color = true,
		units = "pct",
	},
}

function ns.Print(msg) print("|cffeda55fForeverSpeed|r: " .. msg) end

---------------------------------------------------------------------------
-- Event bus
---------------------------------------------------------------------------
local listeners = {}

function ns.On(event, fn)
	local list = listeners[event]
	if not list then list = {}; listeners[event] = list end
	list[#list + 1] = fn
end

function ns.Fire(event, ...)
	local list = listeners[event]
	if not list then return end
	for i = 1, #list do list[i](...) end
end

---------------------------------------------------------------------------
-- Settings access by dotted path ("titan.showMe")
---------------------------------------------------------------------------
local pathCache = {}

local function Resolve(path)
	local parts = pathCache[path]
	if not parts then parts = { strsplit(".", path) }; pathCache[path] = parts end
	local t = ns.db
	for i = 1, #parts - 1 do t = t[parts[i]] end
	return t, parts[#parts]
end

function ns.Get(path)
	local t, k = Resolve(path)
	return t[k]
end

function ns.Set(path, value)
	local t, k = Resolve(path)
	if t[k] == value then return end
	t[k] = value
	ns.Fire("SETTING_CHANGED", path, value)
end

function ns.Toggle(path) ns.Set(path, not ns.Get(path)) end

-- step to the next value in `values` (wraps around)
function ns.Cycle(path, values)
	local cur = ns.Get(path)
	for i, v in ipairs(values) do
		if v == cur then ns.Set(path, values[i % #values + 1]); return end
	end
	ns.Set(path, values[1])
end

local function MergeDefaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			if #v > 0 then -- array (point): copy only if empty
				if #dst[k] == 0 then for i, x in ipairs(v) do dst[k][i] = x end end
			else
				MergeDefaults(dst[k], v)
			end
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

---------------------------------------------------------------------------
-- Lifecycle + ticker
---------------------------------------------------------------------------
local driver = CreateFrame("Frame")
local elapsedAcc = 0

local function OnUpdate(_, elapsed)
	elapsedAcc = elapsedAcc + elapsed
	if elapsedAcc < ns.TICK then return end
	elapsedAcc = 0
	ns.Fire("TICK", ns.Speed:Sample())
end

driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name == ADDON then
		ForeverSpeedDB = ForeverSpeedDB or {}
		ns.db = ForeverSpeedDB
		MergeDefaults(ns.db, ns.defaults)
		ns.Fire("INIT")
	elseif event == "PLAYER_LOGIN" then
		ns.Fire("LOGIN")
		self:SetScript("OnUpdate", OnUpdate)
	end
end)
