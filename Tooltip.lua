-- Tooltip: the speed breakdown shared by the minimap button and the Titan/LDB plugin.
-- Each caller passes its own click hints.

local _, ns = ...
local F = ns.Format

function ns.ShowTooltip(tt, hints)
	local s, units = ns.Speed.state, ns.db.units
	tt:AddLine("ForeverSpeed")
	tt:AddDoubleLine("You", F.Speed(s.me, units), 1, 1, 1)
	if s.hasTarget then
		tt:AddDoubleLine("Target (" .. (UnitName("target") or "?") .. ")", F.Speed(s.tg, units), 1, 1, 1)
		local d, word = F.Delta(s.me, s.tg, units, true)
		tt:AddDoubleLine("Diff (you - target)", d .. (word ~= "" and (" " .. word) or ""), 1, 1, 1)
	else
		tt:AddLine("No target", 0.6, 0.6, 0.6)
	end
	tt:AddLine(" ")
	tt:AddDoubleLine("Mode", F.modes[ns.db.mode], 0.7, 0.7, 0.7, 1, 1, 1)
	for _, hint in ipairs(hints) do
		tt:AddLine(hint, 0.8, 0.8, 0.8)
	end
end
