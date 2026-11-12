-- ForeverSpeed: speedometer for WoW: Forever
-- Shows your speed, your target's speed and the difference (you - target).
-- Floating movable frame + LibDataBroker data source (Titan Panel picks it up automatically).

local ADDON = ...
local BASE_RUN = 7          -- yd/s = 100% (normal run speed)
local TICK = 0.1            -- update interval (s)

local defaults = {
	units = "pct",          -- "pct" | "yds"
	mode = "current",       -- "current" (actual speed now) | "max" (run-speed potential)
	showFrame = true,
	locked = false,
	scale = 1,
	point = { "CENTER", "UIParent", "CENTER", 0, -180 },
}

local db

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
local function Fmt(v)
	if v == nil then return "|cff808080--|r" end
	if db.units == "yds" then return ("%.1f yd/s"):format(v) end
	return ("%d%%"):format(math.floor(v / BASE_RUN * 100 + 0.5))
end

local function FmtDelta(me, tg)
	if me == nil or tg == nil then return "|cff808080--|r", "" end
	local d = me - tg
	local num
	if db.units == "yds" then
		num = ("%+.1f yd/s"):format(d)
	else
		num = ("%+d%%"):format(math.floor(d / BASE_RUN * 100 + (d >= 0 and 0.5 or -0.5)))
	end
	if math.abs(d) < 0.05 then
		return "|cffffffff" .. num .. "|r", "even"
	elseif d > 0 then
		return "|cff20ff20" .. num .. "|r", "you're faster"
	else
		return "|cffff3030" .. num .. "|r", "they're faster"
	end
end

---------------------------------------------------------------------------
-- Floating frame
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "ForeverSpeedFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 58)
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
-- LibDataBroker / Titan Panel
---------------------------------------------------------------------------
local ldb
local LDB = LibStub and LibStub("LibDataBroker-1.1", true)

local state = { me = nil, tg = nil }

local function ShowTooltip(tt)
	tt:AddLine("ForeverSpeed")
	tt:AddDoubleLine("You", Fmt(state.me), 1, 1, 1)
	if UnitExists("target") then
		tt:AddDoubleLine("Target (" .. (UnitName("target") or "?") .. ")", Fmt(state.tg), 1, 1, 1)
		local d, word = FmtDelta(state.me, state.tg)
		tt:AddDoubleLine("Diff (you - target)", d .. (word ~= "" and (" " .. word) or ""), 1, 1, 1)
	else
		tt:AddLine("No target", 0.6, 0.6, 0.6)
	end
	tt:AddLine(" ")
	tt:AddDoubleLine("Mode", db.mode == "max" and "max run speed" or "current speed", 0.7, 0.7, 0.7, 1, 1, 1)
	tt:AddLine("|cffeda55fLeft-click|r: toggle floating frame", 0.8, 0.8, 0.8)
	tt:AddLine("|cffeda55fShift-click|r: % / yd/s   |cffeda55fCtrl-click|r: current / max", 0.8, 0.8, 0.8)
end

local function CycleUnits() db.units = (db.units == "pct") and "yds" or "pct" end
local function CycleMode() db.mode = (db.mode == "current") and "max" or "current" end

local function CreateBroker()
	if not LDB or ldb then return end
	ldb = LDB:NewDataObject("ForeverSpeed", {
		type = "data source",
		label = "Speed",
		text = "--",
		icon = "Interface\\Icons\\Ability_Rogue_Sprint",
		category = "Information",
		OnTooltipShow = ShowTooltip,
		OnClick = function(_, button)
			if button ~= "LeftButton" then return end
			if IsShiftKeyDown() then CycleUnits()
			elseif IsControlKeyDown() then CycleMode()
			else db.showFrame = not db.showFrame; frame:SetShown(db.showFrame) end
		end,
	})
end

---------------------------------------------------------------------------
-- Update loop
---------------------------------------------------------------------------
local elapsedAcc = 0
local function Update()
	SamplePosition()
	state.me = ReadSpeed("player")
	state.tg = UnitExists("target") and ReadSpeed("target") or nil

	local hasTarget = UnitExists("target")
	local dText, word = FmtDelta(state.me, state.tg)

	if frame:IsShown() then
		rowMe:SetText(Fmt(state.me))
		rowTg:SetText(hasTarget and Fmt(state.tg) or "|cff808080no target|r")
		rowDelta:SetText(hasTarget and dText or "")
	end

	if ldb then
		local t = Fmt(state.me)
		if hasTarget then t = t .. " | " .. Fmt(state.tg) .. " | " .. dText end
		if ldb.text ~= t then ldb.text = t end
	end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
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
		for k, v in pairs(defaults) do
			if db[k] == nil then db[k] = v end
		end
		ApplyFrameSettings()
		CreateBroker()
	elseif event == "PLAYER_LOGIN" then
		-- in case LDB was registered by a later-loading addon
		LDB = LDB or (LibStub and LibStub("LibDataBroker-1.1", true))
		CreateBroker()
	end
end)

local function Print(msg) print("|cffeda55fForeverSpeed|r: " .. msg) end

SLASH_FOREVERSPEED1 = "/fspeed"
SLASH_FOREVERSPEED2 = "/foreverspeed"
SlashCmdList.FOREVERSPEED = function(msg)
	local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.-)$")
	if cmd == "show" or cmd == "hide" or cmd == "toggle" then
		if cmd == "toggle" then db.showFrame = not db.showFrame else db.showFrame = (cmd == "show") end
		frame:SetShown(db.showFrame)
	elseif cmd == "lock" or cmd == "unlock" then
		db.locked = (cmd == "lock")
		Print(db.locked and "frame locked" or "frame unlocked (drag to move)")
	elseif cmd == "units" then
		CycleUnits(); Print("units: " .. (db.units == "pct" and "% of run speed" or "yards/second"))
	elseif cmd == "mode" then
		CycleMode(); Print("mode: " .. (db.mode == "max" and "max run speed (potential)" or "current speed"))
	elseif cmd == "scale" and tonumber(arg) then
		db.scale = math.max(0.5, math.min(3, tonumber(arg))); frame:SetScale(db.scale)
	elseif cmd == "reset" then
		db.point = { unpack(defaults.point) }; db.scale = 1; ApplyFrameSettings()
	else
		Print("/fspeed show | hide | toggle | lock | unlock | units | mode | scale <0.5-3> | reset")
	end
end
