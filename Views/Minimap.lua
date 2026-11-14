-- Minimap: draggable button on the minimap edge.
-- Left-click: settings. Right-click: toggle floating display.

local _, ns = ...

local button = CreateFrame("Button", "ForeverSpeedMinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight
button:Hide()

do
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder
	overlay:SetPoint("TOPLEFT")
	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
	bg:SetPoint("TOPLEFT", 7, -5)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetTexture(ns.ICON)
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint("TOPLEFT", 7, -6)
end

local function Position()
	local a = math.rad(ns.db.minimap.angle or 225)
	local r = (Minimap:GetWidth() / 2) + 5
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function Apply()
	Position()
	button:SetShown(not ns.db.minimap.hide)
end

-- angle is written straight to the db while dragging (high frequency, nobody listens)
local function DragUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local s = Minimap:GetEffectiveScale()
	ns.db.minimap.angle = math.deg(math.atan2(py / s - my, px / s - mx)) % 360
	Position()
end

button:SetScript("OnDragStart", function(self)
	self:SetScript("OnUpdate", DragUpdate)
	GameTooltip:Hide()
end)
button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
button:SetScript("OnClick", function(_, mouse)
	if mouse == "RightButton" then ns.Toggle("showFrame")
	else ns.Fire("TOGGLE_SETTINGS") end
end)

local HINTS = {
	"|cffeda55fLeft-click|r: settings   |cffeda55fRight-click|r: toggle display",
	"|cffeda55fDrag|r: move button",
}
button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	ns.ShowTooltip(GameTooltip, HINTS)
	GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

ns.On("INIT", Apply)
ns.On("LOGIN", Apply) -- Minimap size is final now
ns.On("SETTING_CHANGED", function(path)
	if path == "minimap.hide" then Apply() end
end)
