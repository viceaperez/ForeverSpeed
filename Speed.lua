-- Speed: reads speeds from an ordered list of sources.
-- A source is { Read = function(self, unit, mode) -> yd/s or nil, Sample = optional per-tick hook }.
-- The first source that returns a number wins, so a new fallback is one AddSource call.

local _, ns = ...
local Speed = { sources = {} }
ns.Speed = Speed

-- Forever runs the modern client: values can be "secret" (unreadable by addons)
local function Usable(v)
	return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end
ns.Usable = Usable

-- shared, reused every tick (no per-tick allocation)
Speed.state = { me = nil, tg = nil, hasTarget = false }

function Speed:AddSource(source)
	self.sources[#self.sources + 1] = source
end

function Speed:Read(unit, mode)
	for i = 1, #self.sources do
		local v = self.sources[i]:Read(unit, mode)
		if v ~= nil then return v end
	end
	return nil
end

function Speed:Sample()
	local sources = self.sources
	for i = 1, #sources do
		if sources[i].Sample then sources[i]:Sample() end
	end
	local mode = ns.db.mode
	local s = self.state
	s.hasTarget = UnitExists("target") and true or false
	s.me = self:Read("player", mode)
	s.tg = s.hasTarget and self:Read("target", mode) or nil
	return s
end

---------------------------------------------------------------------------
-- Source 1: the game's own speed API
---------------------------------------------------------------------------
Speed:AddSource({
	Read = function(_, unit, mode)
		if not GetUnitSpeed or not UnitExists(unit) then return nil end
		local cur, run = GetUnitSpeed(unit)
		local v = (mode == "max") and run or cur
		if Usable(v) then return v end
		return nil
	end,
})

---------------------------------------------------------------------------
-- Source 2 (fallback): player speed measured from world position.
-- Only for the player in "current" mode; UnitPosition is nil inside instances.
---------------------------------------------------------------------------
local Position = {}

function Position:Sample()
	if not UnitPosition then return end
	local y, x, _, inst = UnitPosition("player")
	if not (Usable(x) and Usable(y)) then self.lastX = nil; self.speed = nil; return end
	local now = GetTime()
	if self.lastX and self.lastInst == inst then
		local dt = now - self.lastT
		if dt > 0 then
			local s = math.sqrt((x - self.lastX) ^ 2 + (y - self.lastY) ^ 2) / dt
			if s > 100 then s = self.speed or 0 end   -- teleport / zoning spike
			self.speed = self.speed and (self.speed * 0.6 + s * 0.4) or s
		end
	end
	self.lastX, self.lastY, self.lastT, self.lastInst = x, y, now, inst
end

function Position:Read(unit, mode)
	if unit == "player" and mode == "current" then return self.speed end
	return nil
end

Speed:AddSource(Position)
