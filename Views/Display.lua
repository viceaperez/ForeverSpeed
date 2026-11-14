-- Display: the floating You / Target / Diff box.

local _, ns = ...
local F = ns.Format

local frame = CreateFrame("Frame", "ForeverSpeedFrame", UIParent, "BackdropTemplate")
frame:SetSize(160, 58)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
if frame.SetBackdrop then
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.6)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
end

local function MakeRow(i, label)
	local l = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 15)
	l:SetText(label)
	local v = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	v:SetPoint("TOPRIGHT", -8, -6 - (i - 1) * 15)
	v:SetJustifyH("RIGHT")
	return v
end
local rowMe = MakeRow(1, "You")
local rowTg = MakeRow(2, "Target")
local rowDelta = MakeRow(3, "Diff")

frame:SetScript("OnDragStart", function(self)
	if not ns.db.locked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local p, _, rp, x, y = self:GetPoint()
	ns.Set("point", { p, "UIParent", rp, x, y })
end)

local function ApplyPosition()
	local p = ns.db.point
	frame:ClearAllPoints()
	frame:SetPoint(p[1], UIParent, p[3], p[4], p[5])
end

local appliers = {
	point = ApplyPosition,
	scale = function() frame:SetScale(ns.db.scale) end,
	showFrame = function() frame:SetShown(ns.db.showFrame) end,
}

ns.On("INIT", function()
	for _, apply in pairs(appliers) do apply() end
end)

ns.On("SETTING_CHANGED", function(path)
	if appliers[path] then appliers[path]() end
end)

ns.On("RESET_POSITION", function()
	ns.Set("point", { unpack(ns.defaults.point) })
end)

ns.On("TICK", function(s)
	if not frame:IsShown() then return end
	local units = ns.db.units
	rowMe:SetText(F.Speed(s.me, units))
	if s.hasTarget then
		rowTg:SetText(F.Speed(s.tg, units))
		rowDelta:SetText((F.Delta(s.me, s.tg, units, true)))
	else
		rowTg:SetText("|cff808080no target|r")
		rowDelta:SetText("")
	end
end)
