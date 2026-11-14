-- Format: pure text formatting. No frames, no settings writes.
-- Add a new unit style by adding one entry to F.units and its key to F.unitOrder.

local _, ns = ...
local F = {}
ns.Format = F

F.DASH = "|cff808080--|r"

-- round half away from zero; the 1e-9 absorbs float noise (7 - 9.8 = -2.8000000000000007)
local function Round(x)
	local r = math.floor(math.abs(x) + 0.5 + 1e-9)
	return x < 0 and -r or r
end
local function Pct(v) return Round(v / ns.BASE_RUN * 100) end

F.units = {
	pct = {
		name = "% of run speed",
		value = function(v) return ("%d%%"):format(Pct(v)) end,
		delta = function(d) return ("%+d%%"):format(Pct(d)) end,
	},
	yds = {
		name = "yards / second",
		value = function(v) return ("%.1f yd/s"):format(v) end,
		delta = function(d) return ("%+.1f yd/s"):format(d) end,
	},
	both = {
		name = "% and yd/s",
		value = function(v) return ("%d%% (%.1f)"):format(Pct(v), v) end,
		delta = function(d) return ("%+d%% (%+.1f)"):format(Pct(d), d) end,
	},
}
F.unitOrder = { "pct", "yds", "both" }

F.modes = { current = "Current speed", max = "Max run speed" }
F.modeOrder = { "current", "max" }

local function Units(key) return F.units[key] or F.units.pct end

function F.Speed(v, units)
	if v == nil then return F.DASH end
	return Units(units).value(v)
end

local EVEN   = { color = "ffffff", word = "even" }
local FASTER = { color = "20ff20", word = "you're faster" }
local SLOWER = { color = "ff3030", word = "they're faster" }

-- returns text (colored unless color == false) and a verdict word
function F.Delta(me, tg, units, color)
	if me == nil or tg == nil then return F.DASH, "" end
	local d = me - tg
	local verdict = (math.abs(d) < 0.05 and EVEN) or (d > 0 and FASTER) or SLOWER
	local num = Units(units).delta(d)
	if color == false then return num, verdict.word end
	return "|cff" .. verdict.color .. num .. "|r", verdict.word
end

-- repair saved values that are no longer valid
ns.On("INIT", function()
	if not F.units[ns.db.units] then ns.db.units = "pct" end
	if not F.units[ns.db.titan.units] then ns.db.titan.units = "pct" end
	if not F.modes[ns.db.mode] then ns.db.mode = "current" end
end)
