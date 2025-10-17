local m = {}

local collisionpos = {
	{8, 3}, --head
	{3, 16}, --lfoot
	{12, 16}, --rfoot
	{2, 8}, --lside
	{13, 8}, --rside
}

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function m:New(o)
    o = o or {
        x = 0,
        y = 0,
    }
	o["w"] = 16
	o["h"] = 16
	o["xs"] = -1
	o["ys"] = 0
	o["hascollision"] = true
	o["state"] = "alive"
	o["frame"] = 0

    setmetatable(o, self)
    self.__index = self
	
	self.hitbox = {4, 7, 11, 7}

    return o
end

function m:kill(cause)
	if cause == "pit" then
		self:remove()
	end
	if cause == "stomp" then
		self.state = "stomp"
		self.frame = 0
	end
	if cause == "shot" then
		self.state = "dead"
		self.frame = 0
		self.xs = 1
		self.ys = -2
	end
end

function m:remove()
    self._remove = true
end

--COLLISION STARTS HERE
function m:footcol()
	local lc = Game.world:getTile(self.x+collisionpos[2][1], self.y+collisionpos[2][2])
	local rc = Game.world:getTile(self.x+collisionpos[3][1], self.y+collisionpos[3][2])
	
	if lc == nil or rc == nil then
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
		self.y = math.floor(self.y/16)*16
		self.ys = 0
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
	
	if self.xs > 0 then
		local t, c = gettile(self.x+collisionpos[5][1], self.y+collisionpos[5][2])
		if c then
			self.x = self.x - 1
			self.xs = -self.xs
		end
	end
	if self.xs < 0 then
		local t, c = gettile(self.x+collisionpos[4][1], self.y+collisionpos[4][2])
		if c then
			self.x = self.x + 1
			self.xs = -self.xs
		end
	end
end
function m:headcol()
	local tc = Game.world:getTile(self.x+collisionpos[1][1], self.y+collisionpos[1][2])
	
	if tc == nil then
		return
	end
	
	if not (self.ys < 0) then
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
end
function m:collision()
	--onscreen check
	self:headcol()
	self:footcol()
	self:sidecol()
end

--COLLISION ENDS HERE

function m:update(dt)
	if self.state == "alive" then
		local gravity = 0.3
		self.ys = self.ys + gravity
    	self.x = self.x + self.xs
    	self.y = self.y + self.ys
		self.frame = self.frame + 1
		if self.frame > 24 then
			self.frame = 1
		end
		self:collision()

		local docol = {self.xs < 0 and 4 or 12, 8}
		local shouldreverse = Game.world:getOverlappingPoint({self, docol[1]+self.x, docol[2]+self.y})
		if shouldreverse then
			self.xs = -self.xs
		end

		local getkill = Game.world:collidingWithPlayersRect(self)
		if getkill then
			if getkill.onground == false and getkill.ys > 0 then
				getkill.stompDo = true
				self:kill("stomp")
			else
				getkill:kill("normal")
			end
		end
	end
	if self.state == "dead" then
		local gravity = 0.15
		self.ys = self.ys + gravity
    	self.x = self.x + self.xs
    	self.y = self.y + self.ys
		self.hascollision = false
	end
	if self.state == "stomp" then
		self.frame = self.frame + 1
		if self.frame > 24 then
			self:remove()
			return
		end
		--self.hascollision = false
	end
	if self.y > (Game.world.height*16)+(self.h*4) then
		self:remove()
		return
	end
end

local newColors = {
    {0,0,0,0},
    {32/255,32/255,32/255,1},
    {1,217/255,178/255,1},
    {186/255,97/255,17/255,1}
}

function m:draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setShader(nesShader)
	sendPalette(newColors)
	if self.state == "dead" then
		drawSprite(sprites.goomba[1], self.x, self.y+1, false, true)
	end
	if self.state == "stomp" then
		drawSprite(sprites.goomba[2], self.x, self.y+1, false, false)
	end
	if self.state == "alive" then
		drawSprite(sprites.goomba[1], self.x, self.y+1, self.frame > 12 and true or false, false)
	end
	love.graphics.setShader()
end

return m