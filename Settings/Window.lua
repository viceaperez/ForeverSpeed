-- Window: builds the settings window from ns.Options using ns.Widgets,
-- and adds an entry under Options > AddOns that opens it.

local _, ns = ...

local sw = CreateFrame("Frame", "ForeverSpeedSettings", UIParent, "BasicFrameTemplateWithInset")
sw:SetWidth(300)
sw:SetPoint("CENTER")
sw:SetFrameStrata("DIALOG")
sw:SetClampedToScreen(true)
sw:SetMovable(true)
sw:EnableMouse(true)
sw:RegisterForDrag("LeftButton")
sw:SetScript("OnDragStart", sw.StartMoving)
sw:SetScript("OnDragStop", sw.StopMovingOrSizing)
sw:Hide()
tinsert(UISpecialFrames, "ForeverSpeedSettings") -- close with Escape

do
	local title = sw.TitleText or sw:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	if not sw.TitleText then title:SetPoint("TOP", 0, -5) end
	title:SetText("ForeverSpeed Settings")
end

local refreshers = {}

local function Refresh()
	if not ns.db or not sw:IsShown() then return end
	for i = 1, #refreshers do refreshers[i]() end
end

local function Build()
	local y = -32
	for _, opt in ipairs(ns.Options) do
		local factory = ns.Widgets[opt.type]
		assert(factory, "ForeverSpeed: unknown option type " .. tostring(opt.type))
		local height, refresh = factory(sw, opt, y)
		if refresh then refreshers[#refreshers + 1] = refresh end
		y = y - height
	end

	local note = sw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	note:SetPoint("BOTTOMLEFT", 16, 14)
	note:SetPoint("RIGHT", -16, 0)
	note:SetJustifyH("LEFT")
	note:SetText(ns.Broker:IsAvailable()
		and "Titan: enable \"ForeverSpeed\" from the Titan right-click menu."
		or "No LibDataBroker found: install Titan Panel to use the bar plugin.")

	sw:SetHeight(-y + 40)
end

local function RegisterBlizzardOptions()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
	local panel = CreateFrame("Frame")
	local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	t:SetPoint("TOPLEFT", 16, -16)
	t:SetText("ForeverSpeed")
	local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	b:SetSize(180, 24)
	b:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -12)
	b:SetText("Open settings window")
	b:SetScript("OnClick", function()
		if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
		sw:Show()
	end)
	Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, "ForeverSpeed"))
end

sw:SetScript("OnShow", Refresh)

ns.On("LOGIN", function()
	Build() -- after LOGIN so the Titan/LDB note is accurate
	RegisterBlizzardOptions()
end)
ns.On("SETTING_CHANGED", Refresh)
ns.On("TOGGLE_SETTINGS", function() sw:SetShown(not sw:IsShown()) end)
