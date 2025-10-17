local world = {}

world.world = {}
world.player = nil
world.width = 0
world.height = 0

world.objects = {}

function world:init(width, height)
    self.width = width
    self.height = height
    self.world = {}
    for y = 1, height do
        self.world[y] = {}
        for x = 1, width do
            self.world[y][x] = 0
        end
    end
    self.objects = {}
end

function world:getOverlappingPoint(from)
    local obj, px, py = unpack(from)
    local iscolliding = nil
    for _, v in pairs(self.objects) do
        if (v ~= obj) and (v.hascollision) then
            --print("hi im at "..tostring(v.x))
			local h2 = v.hitbox
            if col_pointinrect(px, py, v.x+h2[1], v.y+h2[2], h2[3], h2[4]) then
                iscolliding = v
            end 
        end
    end
    return iscolliding
end
function world:getOverlappingObject(from)
    local o = from
    local iscolliding = nil
    for _, v in pairs(self.objects) do
        if (v ~= o) and (v.hascollision) then
            --print("hi im at "..tostring(v.x))
			local h1 = o.hitbox
			local h2 = v.hitbox
            if col_rectinrect(o.x+h1[1], o.y+h1[2], h1[3], h1[4], v.x+h2[1], v.y+h2[2], h2[3], h2[4]) then
                iscolliding = v
            end 
        end
    end
    return iscolliding
end

function world:collidingWithPlayersRect(from)
    local o = from
    local mar = Game.world.player
	local h1 = o.hitbox
	local h2 = mar.hitbox
    local iscolliding = col_rectinrect(o.x+h1[1], o.y+h1[2], h1[3], h1[4], mar.x+h2[1], mar.y+h2[2], h2[3], h2[4]) and mar or nil
    return iscolliding
end

function world:collidingWithPlayers(from)
    local obj, px, py = unpack(from)
    local mar = Game.world.player
	local h2 = mar.hitbox
    local iscolliding = col_pointinrect(px, py, mar.x+h2[1], mar.y+h2[2], h2[3], h2[4]) and mar or nil
    return iscolliding
end

function world:getTile(x, y)
	x = math.floor(x/16)+1
	y = math.floor(y/16)+1
    if x < 1 or y < 1 or x > self.width or y > self.height then
        return nil
    end
    return self.world[y][x]
end

function world:setTile(x, y, id)
	x = math.floor(x/16)+1
	y = math.floor(y/16)+1
    if x >= 1 and y >= 1 and x <= self.width and y <= self.height then
        self.world[y][x] = id
    end
end

function world:addObject(obj)
    table.insert(self.objects, obj)
end

function world:update(dt)
    self.player:update(dt)
	for i, v in pairs(self.objects) do
        if v._remove then
            table.remove(self.objects, i)
        else
            v:update(dt)
        end
	end
end

function world:draw(tileSize, camX, camY)
    tileSize = tileSize or 16
    camX = camX or 0
    camY = camY or 0

    love.graphics.push()
    love.graphics.scale(2, 2)

    love.graphics.translate(-camX, -camY)

    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.world[y][x]
            if tile ~= 0 then
                love.graphics.setColor(1, 1, 1)
                --love.graphics.rectangle("fill", (x-1)*tileSize, (y-1)*tileSize, tileSize, tileSize)
				drawTile(180, (x-1)*tileSize, (y-1)*tileSize)
				drawTile(181, ((x-1)*tileSize)+8, (y-1)*tileSize)
				drawTile(182, (x-1)*tileSize, ((y-1)*tileSize)+8)
				drawTile(183, ((x-1)*tileSize)+8, ((y-1)*tileSize)+8)
            end
        end
    end

    self.player:draw()
    for _, obj in ipairs(self.objects) do
        obj:draw()
    end

    love.graphics.pop()
end


return world