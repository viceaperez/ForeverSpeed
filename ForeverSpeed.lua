-- ForeverSpeed: speedometer for WoW: Forever
-- Shows your speed, your target's speed and the difference (you - target).
-- Floating movable display + minimap button + settings window
-- + LibDataBroker data source (Titan Panel picks it up automatically).

local ADDON = ...
local BASE_RUN = 7          -- yd/s = 100% (normal run speed)
local TICK = 0.1            -- update interval (s)
local ICON = "Interface\\Icons\\Ability_Rogue_Sprint"

local defaults = {
	units = "pct",          -- floating display: "pct" | "yds" | "both"
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
		labels = false,     -- "You 100%  Tgt 140%  Diff -40%"
		color = true,       -- green/red difference
		units = "pct",      -- "pct" | "yds" | "both"
	},
}

local db

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

local function Print(msg) print("|cffeda55fForeverSpeed|r: " .. msg) end

---------------------------------------------------------------------------
-- Secret-value safety (Forever runs the modern client; values may be secret)
---------------------------------------------------------------------------
local function IsSecret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Usable(v)
	return type(v) == "number" and not IsSecret(v)
end

---------------------------------------------------------------------------
-- Player speed fallback: measure from world position when GetUnitSpeed is secret
---------------------------------------------------------------------------
local lastX, lastY, lastT, lastInst, posSpeed

local function SamplePosition()
	if not UnitPosition then return end
	local y, x, _, inst = UnitPosition("player")
	if not (Usable(x) and Usable(y)) then lastX = nil; posSpeed = nil; return end
	local now = GetTime()
	if lastX and lastInst == inst then
		local dt = now - lastT
		if dt > 0 then
			local d = math.sqrt((x - lastX) ^ 2 + (y - lastY) ^ 2)
			local s = d / dt
			if s > 100 then s = posSpeed or 0 end        -- teleport / zoning spike
			posSpeed = posSpeed and (posSpeed * 0.6 + s * 0.4) or s
		end
	end
	lastX, lastY, lastT, lastInst = x, y, now, inst
end

---------------------------------------------------------------------------
-- Reading speeds (yd/s), nil = unavailable
---------------------------------------------------------------------------
local function ReadSpeed(unit)
	if not GetUnitSpeed or not UnitExists(unit) then return nil end
	local cur, run = GetUnitSpeed(unit)
	local v = (db.mode == "max") and run or cur
	if Usable(v) then return v end
	if unit == "player" and db.mode == "current" then return posSpeed end
	return nil
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------
local DASH = "|cff808080--|r"
local UNIT_NAMES = { pct = "% of run speed", yds = "yards / second", both = "% and yd/s" }
local NEXT_UNITS = { pct = "yds", yds = "both", both = "pct" }

local function Round(x) return math.floor(x + (x >= 0 and 0.5 or -0.5)) end

local function Fmt(v, units)
	if v == nil then return DASH end
	if units == "yds" then return ("%.1f yd/s"):format(v) end
	if units == "both" then return ("%d%% (%.1f)"):format(Round(v / BASE_RUN * 100), v) end
	return ("%d%%"):format(Round(v / BASE_RUN * 100))
end

-- returns colored/uncolored text and a word ("you're faster" ...)
local function FmtDelta(me, tg, units, color)
	if me == nil or tg == nil then return DASH, "" end
	local d = me - tg
	local num
	if units == "yds" then
		num = ("%+.1f yd/s"):format(d)
	elseif units == "both" then
		num = ("%+d%% (%+.1f)"):format(Round(d / BASE_RUN * 100), d)
	else
		num = ("%+d%%"):format(Round(d / BASE_RUN * 100))
	end
	local c, word
	if math.abs(d) < 0.05 then c, word = "ffffff", "even"
	elseif d > 0 then c, word = "20ff20", "you're faster"
	else c, word = "ff3030", "they're faster" end
	if color == false then return num, word end
	return "|cff" .. c .. num .. "|r", word
end

---------------------------------------------------------------------------
-- Floating display
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "ForeverSpeedFrame", UIParent, "BackdropTemplate")
frame:SetSize(160, 58)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
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
	if not db.locked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local p, _, rp, x, y = self:GetPoint()
	db.point = { p, "UIParent", rp, x, y }
end)

local function ApplyFrameSettings()
	frame:ClearAllPoints()
	local p = db.point
	frame:SetPoint(p[1], UIParent, p[3], p[4], p[5])
	frame:SetScale(db.scale)
	frame:SetShown(db.showFrame)
end

---------------------------------------------------------------------------
-- Shared state + tooltip
---------------------------------------------------------------------------
local state = { me = nil, tg = nil }
local ToggleSettings -- defined below

local function ShowTooltip(tt, isMinimap)
	tt:AddLine("ForeverSpeed")
	tt:AddDoubleLine("You", Fmt(state.me, db.units), 1, 1, 1)
	if UnitExists("target") then
		tt:AddDoubleLine("Target (" .. (UnitName("target") or "?") .. ")", Fmt(state.tg, db.units), 1, 1, 1)
		local d, word = FmtDelta(state.me, state.tg, db.units, true)
		tt:AddDoubleLine("Diff (you - target)", d .. (word ~= "" and (" " .. word) or ""), 1, 1, 1)
	else
		tt:AddLine("No target", 0.6, 0.6, 0.6)
	end
	tt:AddLine(" ")
	tt:AddDoubleLine("Mode", db.mode == "max" and "max run speed" or "current speed", 0.7, 0.7, 0.7, 1, 1, 1)
	if isMinimap then
		tt:AddLine("|cffeda55fLeft-click|r: settings   |cffeda55fRight-click|r: toggle display", 0.8, 0.8, 0.8)
		tt:AddLine("|cffeda55fDrag|r: move button", 0.8, 0.8, 0.8)
	else
		tt:AddLine("|cffeda55fLeft-click|r: toggle display   |cffeda55fAlt-click|r: settings", 0.8, 0.8, 0.8)
		tt:AddLine("|cffeda55fShift-click|r: units   |cffeda55fCtrl-click|r: current / max", 0.8, 0.8, 0.8)
	end
end

local RefreshSettings -- defined below
local function SetShowFrame(v)
	db.showFrame = v
	frame:SetShown(v)
	if RefreshSettings then RefreshSettings() end
end
local function CycleUnits() db.units = NEXT_UNITS[db.units] or "pct"; if RefreshSettings then RefreshSettings() end end
local function CycleMode() db.mode = (db.mode == "current") and "max" or "current"; if RefreshSettings then RefreshSettings() end end

---------------------------------------------------------------------------
-- LibDataBroker / Titan Panel
---------------------------------------------------------------------------
local ldb
local LDB = LibStub and LibStub("LibDataBroker-1.1", true)

local function CreateBroker()
	if not LDB or ldb then return end
	ldb = LDB:NewDataObject("ForeverSpeed", {
		type = "data source",
		label = "Speed",
		text = "--",
		icon = ICON,
		category = "Information",
		OnTooltipShow = function(tt) ShowTooltip(tt, false) end,
		OnClick = function(_, button)
			if button ~= "LeftButton" then return end
			if IsAltKeyDown() then ToggleSettings()
			elseif IsShiftKeyDown() then CycleUnits()
			elseif IsControlKeyDown() then CycleMode()
			else SetShowFrame(not db.showFrame) end
		end,
	})
end

local function BrokerText(hasTarget)
	local t = db.titan
	local parts = {}
	if t.showMe then
		parts[#parts + 1] = (t.labels and "You " or "") .. Fmt(state.me, t.units)
	end
	if hasTarget and t.showTarget then
		parts[#parts + 1] = (t.labels and "Tgt " or "") .. Fmt(state.tg, t.units)
	end
	if hasTarget and t.showDiff then
		parts[#parts + 1] = (t.labels and "Diff " or "") .. (FmtDelta(state.me, state.tg, t.units, t.color))
	end
	if #parts == 0 then
		return hasTarget and DASH or "|cff808080no target|r"
	end
	return table.concat(parts, t.labels and "  " or " | ")
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
local mm = CreateFrame("Button", "ForeverSpeedMinimapButton", Minimap)
mm:SetSize(31, 31)
mm:SetFrameStrata("MEDIUM")
mm:SetFrameLevel(8)
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:RegisterForDrag("LeftButton")
mm:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight
do
	local overlay = mm:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder
	overlay:SetPoint("TOPLEFT")
	local bg = mm:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
	bg:SetPoint("TOPLEFT", 7, -5)
	local icon = mm:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint("TOPLEFT", 7, -6)
end

local function PositionMinimapButton()
	local a = math.rad(db.minimap.angle or 225)
	local r = (Minimap:GetWidth() / 2) + 5
	mm:ClearAllPoints()
	mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function MinimapDragUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local s = Minimap:GetEffectiveScale()
	px, py = px / s, py / s
	db.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
	PositionMinimapButton()
end

mm:SetScript("OnDragStart", function(self)
	self:SetScript("OnUpdate", MinimapDragUpdate)
	GameTooltip:Hide()
end)
mm:SetScript("OnDragStop", function(self)
	self:SetScript("OnUpdate", nil)
end)
mm:SetScript("OnClick", function(_, button)
	if button == "RightButton" then SetShowFrame(not db.showFrame)
	else ToggleSettings() end
end)
mm:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	ShowTooltip(GameTooltip, true)
	GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function ApplyMinimap()
	PositionMinimapButton()
	mm:SetShown(not db.minimap.hide)
end

---------------------------------------------------------------------------
-- Settings window
---------------------------------------------------------------------------
local sw = CreateFrame("Frame", "ForeverSpeedSettings", UIParent, "BasicFrameTemplateWithInset")
sw:SetSize(300, 495)
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
local y = -32

local function Header(text)
	y = y - 6
	local h = sw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	h:SetPoint("TOPLEFT", 16, y)
	h:SetText(text)
	y = y - 20
end

local function Check(label, get, set)
	local c = CreateFrame("CheckButton", nil, sw, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	c:SetPoint("TOPLEFT", 18, y)
	c.Text:SetText(label)
	c.Text:SetFontObject("GameFontHighlightSmall")
	c:SetHitRectInsets(0, -c.Text:GetStringWidth() - 4, 0, 0)
	c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	refreshers[#refreshers + 1] = function() c:SetChecked(get()) end
	y = y - 24
	return c
end

local function Cycler(label, getText, onClick)
	local l = sw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	l:SetPoint("TOPLEFT", 22, y - 6)
	l:SetText(label)
	local b = CreateFrame("Button", nil, sw, "UIPanelButtonTemplate")
	b:SetSize(130, 22)
	b:SetPoint("TOPRIGHT", -18, y)
	b:SetScript("OnClick", function() onClick(); RefreshSettings() end)
	refreshers[#refreshers + 1] = function() b:SetText(getText()) end
	y = y - 26
	return b
end

-- General
Header("General")
Check("Show floating speed display", function() return db.showFrame end, function(v) SetShowFrame(v) end)
Check("Lock floating display", function() return db.locked end, function(v) db.locked = v end)
Check("Show minimap button", function() return not db.minimap.hide end,
	function(v) db.minimap.hide = not v; ApplyMinimap() end)
Cycler("Display units", function() return UNIT_NAMES[db.units] end, function() db.units = NEXT_UNITS[db.units] or "pct" end)
Cycler("Speed mode", function() return db.mode == "max" and "Max run speed" or "Current speed" end,
	function() db.mode = (db.mode == "current") and "max" or "current" end)
Cycler("Display scale", function() return ("%.1fx"):format(db.scale) end, function()
	db.scale = db.scale + 0.1
	if db.scale > 2.05 then db.scale = 0.6 end
	db.scale = math.floor(db.scale * 10 + 0.5) / 10
	frame:SetScale(db.scale)
end)

-- Titan / LDB
Header("Titan Panel bar")
Check("Show your speed", function() return db.titan.showMe end, function(v) db.titan.showMe = v end)
Check("Show target speed", function() return db.titan.showTarget end, function(v) db.titan.showTarget = v end)
Check("Show difference", function() return db.titan.showDiff end, function(v) db.titan.showDiff = v end)
Check("Show labels (You / Tgt / Diff)", function() return db.titan.labels end, function(v) db.titan.labels = v end)
Check("Color the difference green / red", function() return db.titan.color end, function(v) db.titan.color = v end)
Cycler("Titan units", function() return UNIT_NAMES[db.titan.units] end,
	function() db.titan.units = NEXT_UNITS[db.titan.units] or "pct" end)

local preview = sw:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
preview:SetPoint("TOPLEFT", 22, y - 6)
preview:SetPoint("RIGHT", -18, 0)
preview:SetJustifyH("LEFT")

local note = sw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
note:SetPoint("BOTTOMLEFT", 16, 14)
note:SetPoint("RIGHT", -16, 0)
note:SetJustifyH("LEFT")
note:SetText(LDB and "Titan: enable \"ForeverSpeed\" from the Titan right-click menu."
	or "No LibDataBroker found: install Titan Panel to use the bar plugin.")

-- reset position button
do
	local b = CreateFrame("Button", nil, sw, "UIPanelButtonTemplate")
	b:SetSize(130, 22)
	b:SetPoint("BOTTOMRIGHT", -18, 34)
	b:SetText("Reset display position")
	b:SetScript("OnClick", function()
		db.point = { unpack(defaults.point) }
		ApplyFrameSettings()
	end)
end

RefreshSettings = function()
	if not db or not sw:IsShown() then return end
	for _, f in ipairs(refreshers) do f() end
end
sw:SetScript("OnShow", RefreshSettings)

ToggleSettings = function()
	sw:SetShown(not sw:IsShown())
end

-- Entry in Blizzard Options > AddOns that opens the window
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
	local category = Settings.RegisterCanvasLayoutCategory(panel, "ForeverSpeed")
	Settings.RegisterAddOnCategory(category)
end

---------------------------------------------------------------------------
-- Update loop
---------------------------------------------------------------------------
local elapsedAcc = 0
local function Update()
	SamplePosition()
	state.me = ReadSpeed("player")
	local hasTarget = UnitExists("target")
	state.tg = hasTarget and ReadSpeed("target") or nil

	if frame:IsShown() then
		rowMe:SetText(Fmt(state.me, db.units))
		rowTg:SetText(hasTarget and Fmt(state.tg, db.units) or "|cff808080no target|r")
		rowDelta:SetText(hasTarget and (FmtDelta(state.me, state.tg, db.units, true)) or "")
	end

	local bt = BrokerText(hasTarget)
	if ldb and ldb.text ~= bt then ldb.text = bt end
	if sw:IsShown() then preview:SetText("Preview: " .. bt) end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
	if not db then return end
	elapsedAcc = elapsedAcc + elapsed
	if elapsedAcc >= TICK then
		elapsedAcc = 0
		Update()
	end
end)

---------------------------------------------------------------------------
-- Init + slash commands
---------------------------------------------------------------------------
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == ADDON then
		ForeverSpeedDB = ForeverSpeedDB or {}
		db = ForeverSpeedDB
		MergeDefaults(db, defaults)
		if db.units ~= "pct" and db.units ~= "yds" and db.units ~= "both" then db.units = "pct" end
		ApplyFrameSettings()
		ApplyMinimap()
		CreateBroker()
		RegisterBlizzardOptions()
	elseif event == "PLAYER_LOGIN" then
		-- in case LDB was registered by a later-loading addon
		LDB = LDB or (LibStub and LibStub("LibDataBroker-1.1", true))
		CreateBroker()
		ApplyMinimap() -- Minimap size is final now
	end
end)

SLASH_FOREVERSPEED1 = "/fspeed"
SLASH_FOREVERSPEED2 = "/foreverspeed"
SlashCmdList.FOREVERSPEED = function(msg)
	local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.-)$")
	if cmd == "" or cmd == "config" or cmd == "settings" or cmd == "options" then
		ToggleSettings()
	elseif cmd == "show" or cmd == "hide" or cmd == "toggle" then
		if cmd == "toggle" then SetShowFrame(not db.showFrame) else SetShowFrame(cmd == "show") end
	elseif cmd == "lock" or cmd == "unlock" then
		db.locked = (cmd == "lock"); RefreshSettings()
		Print(db.locked and "display locked" or "display unlocked (drag to move)")
	elseif cmd == "minimap" then
		db.minimap.hide = not db.minimap.hide; ApplyMinimap(); RefreshSettings()
		Print(db.minimap.hide and "minimap button hidden" or "minimap button shown")
	elseif cmd == "units" then
		CycleUnits(); Print("units: " .. UNIT_NAMES[db.units])
	elseif cmd == "mode" then
		CycleMode(); Print("mode: " .. (db.mode == "max" and "max run speed (potential)" or "current speed"))
	elseif cmd == "scale" and tonumber(arg) then
		db.scale = math.max(0.5, math.min(3, tonumber(arg))); frame:SetScale(db.scale); RefreshSettings()
	elseif cmd == "reset" then
		db.point = { unpack(defaults.point) }; db.scale = 1; ApplyFrameSettings(); RefreshSettings()
	else
		Print("/fspeed (settings) | show | hide | toggle | lock | unlock | minimap | units | mode | scale <0.5-3> | reset")
	end
end
