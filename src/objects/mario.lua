local m = {}

local collisionpos = {
	{8, 18}, --head
	{3, 32}, --lfoot
	{12, 32}, --rfoot
	--low (small, big)
	{2, 24}, --lside
	{13, 24}, --rside
	--high (big)
	{2, 8}, --lside
	{13, 8}, --rside
}
local defphysics = {
	jumpstates = {
		[3] = {0.15625, 0.5625},
		[2] = {0.1171875, 0.375},
		[1] = {0.125, 0.4375},
	},
	speedstates = {
		[true] = {0.0556640625, 2.5625},
		[false] = {0.02539, 1.5625},
	}
}
local camspeed = 0
local camoffset = -42

function m:New(o)
    o = o or {
        x = 0,
        y = 0,
    }
	o["w"] = 16
	o["h"] = 32
	o["xs"] = 0
	o["ys"] = 0
	o["onground"] = false
	o["physics"] = {
		defphysics.speedstates[false],
		defphysics.jumpstates[1],
	}
	o["jumpstate"] = 1
	o["midairaccel"] = 0.0556640625
	o["runtimer"] = 0 --becomes 10 since mario keeps running for 10 frames

	o["jumpgravity"] = true --can we change the gravity by holding jump when going up?
	
	o["deceling"] = false
	o["powerstate"] = 0 --0: small, 1: big, 2: fire and 3+ are extras i can add or others can add

    setmetatable(o, self)
    self.__index = self
	
	self.hitbox = {4, 4+16, 11, 13}

    return o
end

function m:kill()
	resetlevel()
end

function m:remove()
    for i,v in pairs(self) do
        v = nil
    end
    self = nil
end

--COLLISION STARTS HERE
function m:footcol()
	local lc = Game.world:getTile(self.x+collisionpos[2][1], self.y+collisionpos[2][2])
	local rc = Game.world:getTile(self.x+collisionpos[3][1], self.y+collisionpos[3][2])
	
	if lc == nil or rc == nil then
		self:sidecol()
		return
	end
	
	if lc == 0 and rc == 0 then
		self.onground = false
	else
		self.onground = true
	end
	
	if lc == 3 then
		Game.world:setTile(self.x+collisionpos[2][1], self.y+collisionpos[2][2], 0)
		self:sidecol()
		return
	end
	if rc == 3 then
		Game.world:setTile(self.x+collisionpos[3][1], self.y+collisionpos[3][2], 0)
		self:sidecol()
		return
	end
	
	if not (self.ys > 0) then
		self:sidecol()
		return
	end
	
	--we do this TWICE for BOTH tile AAGHHGH
	local function checktile(t)
		if t < 1 then
			return
		end
		if math.floor(self.y)%16<5 then
			self.y = math.floor(self.y/16)*16
			self.ys = 0
		end
	end
	checktile(lc)
	checktile(rc)
	self:sidecol()
end
function m:sidecol()
	local function gettile(x, y)
		local c = Game.world:getTile(x, y)
		if c == nil then return nil, nil end
		return c, c > 0
	end
	
	do
		local t, c = gettile(self.x+collisionpos[5][1], self.y+collisionpos[5][2])
		if c then
			if t == 3 then
				Game.world:setTile(self.x+collisionpos[5][1], self.y+collisionpos[5][2], 0)
			else
				self.x = self.x - 1
				self.xs = 0
			end
		end
	end
	do
		local t, c = gettile(self.x+collisionpos[4][1], self.y+collisionpos[4][2])
		if c then
			if t == 3 then
				Game.world:setTile(self.x+collisionpos[4][1], self.y+collisionpos[4][2], 0)
			else
				self.x = self.x + 1
				self.xs = 0
			end
		end
	end
end
function m:headcol()
	local tc = Game.world:getTile(self.x+collisionpos[1][1], self.y+collisionpos[1][2])
	
	if tc == nil then
		self:footcol()
		return
	end
	
	if tc == 3 then
		Game.world:setTile(self.x+collisionpos[1][1], self.y+collisionpos[1][2], 0)
		self:footcol()
		return
	end
	
	if not (self.ys < 0) then
		self:footcol()
		return
	end
	
	--we do this TWICE for BOTH tile AAGHHGH
	local function checktile(t)
		if t < 1 then
			return
		end
		--self.y = math.floor((self.y+16)/16)*16
		self.ys = 1
	end
	checktile(tc)
	self:footcol()
end
function m:collision()
	--onscreen check
	self.onground = false
	if not (self.y > -self.h and self.y < 240+self.h) then
		return --this is like branching to a rts.
	end
	if not (self.y < 207) then
		return
	end
	self:headcol()
end

--COLLISION ENDS HERE

function m:jump()
	if math.abs(self.xs) < 2.3125 then
		self.ys = -4
		if math.abs(self.xs) < 1 then
			self.jumpstate = 1
		else
			self.jumpstate = 2
		end
	else
		self.ys = -5
		self.jumpstate = 3
	end
	if math.abs(self.xs) < 1.5625 then
		self.midairaccel = 0.037109375
	else
		self.midairaccel = 0.0556640625
	end
end

function m:walk()
	local keywalk = bn(Game.input[1])-bn(Game.input[2])
	if keywalk ~= 0 then
		self.deceling = false
		if keywalk*self.xs < self.physics[1][2] then
			if keywalk*self.xs < 0 then
				self.xs = self.xs + (keywalk*0.1015625)
			else
				self.xs = self.xs + (keywalk*self.physics[1][1])
			end
		else
			self.xs = keywalk*self.physics[1][2]
		end
	else
		local og = self.xs - 0
		self.deceling = true
		self.xs = self.xs - math.sign(self.xs) * 0.05078125
		if math.sign(self.xs) ~= math.sign(og) then
			self.deceling = false
			self.xs = 0
		end
	end
end

function m:airwalk()
	local keywalk = bn(Game.input[1])-bn(Game.input[2])
	if keywalk ~= 0 then
		if keywalk*self.xs < 1.5625 then
			if keywalk*self.xs < 0 then
				self.xs = self.xs + (keywalk*0.1015625)
			else
				self.xs = self.xs + (keywalk*self.midairaccel)
			end
		end
	end
end

function m:camera(oldxs)
    local cam = Game.camera

    if self.x > cam[1] + 122 then
        cam[1] = self.x - 122
    elseif self.x < cam[1] + 24 then
        cam[1] = self.x - 24
    end
	
	if self.x > cam[1] + (122+camoffset) then
        cam[1] = self.x - (122+camoffset)
		camoffset = camoffset + math.clamp(self.xs, 0.5, 4)
	end
	if self.x < cam[1] + 80 then
		camoffset = -42
	end
end

function m:update(dt)
	local oldxs = self.xs-0.00000001
	self.physics = {
		defphysics.speedstates[self.runtimer>0],
		defphysics.jumpstates[self.jumpstate],
	}
	if self.stompDo then
		self.ys = -4
		self.jumpgravity = false
		self.stompDo = false
	end
	local gravity = self.physics[2][2]
	if self.jumpgravity == true and (Game.input[5] > 0 and self.ys < 0) then
		gravity = self.physics[2][1]
	end
	if Game.input[6] > 0 then
		self.runtimer = 10
	else
		self.runtimer = math.clamp(self.runtimer - 1, 0, 10)
	end
	self.ys = self.ys + gravity
	if self.onground then self:walk(); self.jumpgravity = true; else self:airwalk() end
	if Game.input[5] == 1 and self.onground then
		self:jump()
	end
    self.x = self.x + self.xs
	if self.x < -2 then
		self.xs = 0
		self.x = -2
	end
    self.y = self.y + math.clamp(self.ys, -9999, 4.5)
	self:collision()
	
	self:camera(oldxs)
end

function m:draw()
	love.graphics.setColor(1,1,0)
	local h = self.hitbox
    love.graphics.rectangle("fill", math.floor(self.x+h[1]), math.floor(self.y+h[2]), h[3], h[4])
	love.graphics.setColor(0,1,0)
	for i, v in pairs(collisionpos) do
		if (i == 4 or i == 6) or (i == 5 or i == 7) then
			if (i == 4 or i == 6) then
				if self.xs < 0 then love.graphics.rectangle("fill", self.x+v[1], self.y+v[2], 1, 1) end
			end
			if (i == 5 or i == 7) then
				if self.xs > 0 then love.graphics.rectangle("fill", self.x+v[1], self.y+v[2], 1, 1) end
			end
		else
			love.graphics.rectangle("fill", self.x+v[1], self.y+v[2], 1, 1)
		end
	end
	love.graphics.setColor(1,1,1)
end

return m