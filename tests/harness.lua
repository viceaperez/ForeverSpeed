-- Headless test: stubs the WoW API, loads the addon in toc order, checks behaviour.
-- Run from tests/: npm install && npm test
-- headless WoW API stubs
math.atan2 = math.atan2 or math.atan
unpack = table.unpack
_G.tinsert = table.insert
function strsplit(sep, s) local t = {} for p in (s..sep):gmatch("(.-)%"..sep) do t[#t+1]=p end return table.unpack(t) end
local frames = {}
local Obj = {}
Obj.__index = function(t, k)
  local v = rawget(Obj, k); if v then return v end
  if k == "TitleText" or k == "Low" or k == "High" or k == "SetBackdrop" then return nil end
  return function() end -- any unknown method: no-op
end
function Obj:SetScript(n, f) self.scripts[n] = f end
function Obj:GetScript(n) return self.scripts[n] end
function Obj:RegisterEvent(e) self.events[e] = true end
function Obj:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Obj:Hide() self.shown = false end
function Obj:SetShown(v) if v then self:Show() else self:Hide() end end
function Obj:IsShown() return self.shown end
function Obj:SetText(t) self.text = t end
function Obj:GetText() return self.text end
function Obj:GetStringWidth() return 50 end
function Obj:SetChecked(v) self.checked = v end
function Obj:GetChecked() return self.checked end
function Obj:SetValue(v) self.value = v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end end
function Obj:GetPoint() return "CENTER", nil, "CENTER", 10, 20 end
function Obj:GetWidth() return 140 end
function Obj:GetCenter() return 100, 100 end
function Obj:GetEffectiveScale() return 1 end
function Obj:SetScale(s) self.scale = s end
function Obj:SetPoint(...) self.point = {...} end
function Obj:CreateFontString() return New() end
function Obj:CreateTexture() return New() end
function Obj:StartMoving() end
function Obj:StopMovingOrSizing() end
function New(name) local o = setmetatable({scripts={}, events={}, shown=true, name=name}, Obj); o.Text = setmetatable({scripts={},events={}}, Obj); frames[#frames+1]=o; if name then _G[name]=o end return o end
function CreateFrame(_, name) return New(name) end
UIParent = New("UIParent"); Minimap = New("Minimap"); GameTooltip = New("GameTooltip")
UISpecialFrames = {}
SlashCmdList = {}
Settings = { RegisterCanvasLayoutCategory = function() return {} end, RegisterAddOnCategory = function() end }
local now = 0; function GetTime() return now end
function GetCursorPosition() return 0, 0 end
SPEED = { player = {7, 7}, target = {9.8, 9.8} }
TARGET = true
function UnitExists(u) return u == "player" or (u == "target" and TARGET) end
function UnitName() return "Rogue" end
function GetUnitSpeed(u) local s = SPEED[u]; return s[1], s[2] end
function UnitPosition() return nil end
function IsAltKeyDown() return false end IsShiftKeyDown = IsAltKeyDown; IsControlKeyDown = IsAltKeyDown
-- fake LDB
local ldbObj
LibStub = function(name) return { NewDataObject = function(_, n, o) ldbObj = o; return o end } end

-- load addon
local root = arg_root
local ns = {}
for _, f in ipairs(FILES) do
  assert(load(f.src, f.name))("ForeverSpeed", ns)
end
local function fire(ev, ...) for _, fr in ipairs(frames) do if fr.events[ev] then fr.scripts.OnEvent(fr, ev, ...) end end end
local function tick() now = now + 0.2; for _, fr in ipairs(frames) do if fr.scripts.OnUpdate then fr.scripts.OnUpdate(fr, 0.2) end end end
local function check(name, got, want) print((got == want and "PASS " or "FAIL ") .. name .. "  got=" .. tostring(got) .. (got == want and "" or ("  want=" .. tostring(want)))) end

ForeverSpeedDB = { units = "pct", point = { "TOP", "UIParent", "TOP", 5, 5 } } -- old 1.1 saved vars
fire("ADDON_LOADED", "ForeverSpeed"); fire("PLAYER_LOGIN"); tick()
check("db point kept", ForeverSpeedDB.point[1], "TOP")
check("titan defaults merged", ForeverSpeedDB.titan.showDiff, true)
check("broker text", ldbObj.text, "100% | 140% | |cffff3030-40%|r")
check("display shown", ForeverSpeedFrame:IsShown(), true)
check("minimap shown", ForeverSpeedMinimapButton:IsShown(), true)

SlashCmdList.FOREVERSPEED("units"); tick()
check("/fspeed units", ForeverSpeedDB.units, "yds")
SlashCmdList.FOREVERSPEED("mode"); check("/fspeed mode", ForeverSpeedDB.mode, "max")
SlashCmdList.FOREVERSPEED("mode")
SlashCmdList.FOREVERSPEED("minimap"); check("/fspeed minimap hides", ForeverSpeedMinimapButton:IsShown(), false)
SlashCmdList.FOREVERSPEED("hide"); check("/fspeed hide", ForeverSpeedFrame:IsShown(), false)
SlashCmdList.FOREVERSPEED("scale 9"); check("scale clamped", ForeverSpeedFrame.scale, 3)
SlashCmdList.FOREVERSPEED("reset"); check("reset scale", ForeverSpeedFrame.scale, 1)
check("reset point", ForeverSpeedFrame.point[1], "CENTER")

-- settings window
ForeverSpeedSettings:Hide()
SlashCmdList.FOREVERSPEED(""); check("/fspeed opens settings", ForeverSpeedSettings:IsShown(), true)
check("slider shows scale", ForeverSpeedSlider1.value, 1)
ForeverSpeedSlider1:SetValue(1.53); check("slider sets scale (stepped)", ForeverSpeedDB.scale, 1.55)
check("slider rescales display", ForeverSpeedFrame.scale, 1.55)

ns.Set("titan.labels", true); ns.Set("titan.showMe", false); tick()
check("titan filter+labels", ldbObj.text, "Tgt 140%  Diff |cffff3030-40%|r")
ns.Set("titan.color", false); ns.Set("titan.units", "both"); tick()
check("titan both/no color", ldbObj.text, "Tgt 140% (9.8)  Diff -40% (-2.8)")
TARGET = false; tick(); check("no target text", ldbObj.text, "|cff808080no target|r")

-- secret target speed
TARGET = true; issecretvalue = function(v) return v == 9.8 end; tick()
check("secret target -> dash", ldbObj.text, "Tgt |cff808080--|r  Diff |cff808080--|r")
SlashCmdList.FOREVERSPEED("bogus")
