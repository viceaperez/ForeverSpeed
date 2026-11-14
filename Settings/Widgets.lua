-- Widgets: generic settings controls, bound to a settings path through ns.Get / ns.Set.
-- Each factory: W[type](parent, opt, y) -> height used, refresh function (or nil).
-- Add a new control type by adding one factory here; the window code doesn't change.

local _, ns = ...
local W = {}
ns.Widgets = W

local LEFT, RIGHT = 22, -18

function W.header(parent, opt, y)
	local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	h:SetPoint("TOPLEFT", 16, y - 6)
	h:SetText(opt.text)
	return 26
end

-- opt: key, label, invert (checked = setting is false)
function W.check(parent, opt, y)
	local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	c:SetPoint("TOPLEFT", 18, y)
	c.Text:SetText(opt.label)
	c.Text:SetFontObject("GameFontHighlightSmall")
	c:SetHitRectInsets(0, -c.Text:GetStringWidth() - 4, 0, 0)
	c:SetScript("OnClick", function(self)
		local checked = self:GetChecked() and true or false
		if opt.invert then checked = not checked end
		ns.Set(opt.key, checked)
	end)
	return 24, function()
		local v = ns.Get(opt.key) and true or false
		if opt.invert then v = not v end
		c:SetChecked(v)
	end
end

-- opt: key, label, values (array), text(value) -> button caption
function W.cycle(parent, opt, y)
	local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	l:SetPoint("TOPLEFT", LEFT, y - 6)
	l:SetText(opt.label)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(130, 22)
	b:SetPoint("TOPRIGHT", RIGHT, y)
	b:SetScript("OnClick", function() ns.Cycle(opt.key, opt.values) end)
	return 26, function() b:SetText(opt.text(ns.Get(opt.key))) end
end

-- opt: key, label, min, max, step, format ("%.2fx")
local sliderCount = 0
function W.slider(parent, opt, y)
	sliderCount = sliderCount + 1
	local name = "ForeverSpeedSlider" .. sliderCount -- older templates need a global name
	local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	l:SetPoint("TOPLEFT", LEFT, y - 4)
	local s = CreateFrame("Slider", name, parent, "UISliderTemplateWithLabels")
	s:SetSize(130, 17)
	s:SetPoint("TOPRIGHT", RIGHT, y - 2)
	s:SetMinMaxValues(opt.min, opt.max)
	s:SetValueStep(opt.step)
	if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
	local low, high, text = s.Low or _G[name .. "Low"], s.High or _G[name .. "High"], s.Text or _G[name .. "Text"]
	if low then low:SetText(tostring(opt.min)) end
	if high then high:SetText(tostring(opt.max)) end
	if text then text:SetText("") end

	local function Label(v)
		l:SetText(("%s: |cffffd100" .. opt.format .. "|r"):format(opt.label, v))
	end
	s:SetScript("OnValueChanged", function(_, v)
		v = math.floor(v / opt.step + 0.5) * opt.step
		v = math.floor(v * 100 + 0.5) / 100 -- drop float noise
		Label(v)
		if ns.db then ns.Set(opt.key, v) end
	end)
	return 36, function()
		local v = ns.Get(opt.key)
		s:SetValue(v)
		Label(v)
	end
end

-- opt: text, event (fired on click)
function W.button(parent, opt, y)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(160, 22)
	b:SetPoint("TOPLEFT", LEFT - 4, y)
	b:SetText(opt.text)
	b:SetScript("OnClick", function() ns.Fire(opt.event) end)
	return 28
end

-- opt: label, get() -> text, event (refresh when it fires)
function W.text(parent, opt, y)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	fs:SetPoint("TOPLEFT", LEFT, y - 6)
	fs:SetPoint("RIGHT", RIGHT, 0)
	fs:SetJustifyH("LEFT")
	local function Refresh() fs:SetText(opt.label .. opt.get()) end
	if opt.event then
		ns.On(opt.event, function() if parent:IsShown() then Refresh() end end)
	end
	return 32, Refresh
end
