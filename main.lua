love.graphics.setDefaultFilter("nearest", "nearest")
SCREEN_WIDTH, SCREEN_HEIGHT = 256, 224

Game = Game or {}
Game.input = {}
Game.camera = {0, 0}
Game.world = require("src.world")
lo = {
	mario = require("src.objects.mario"),
	goomba = require("src.objects.goomba"),
    koopa = require("src.objects.koopa"),
}

tilequads = {}
sprites = require("assets.sprites")

nesShader = love.graphics.newShader([[
extern number n;
extern vec4 oldColors[100];
extern vec4 newColors[100];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
	
    if(pixel.a < 0.5) return vec4(0.0, 0.0, 0.0, 0.0);
    for (int i = 0; i < int(n); i++) {
        // compare grayscale with tolerance
        float diff = distance(pixel.rgb, oldColors[i].rgb);
        if(diff < 0.01) {
            return vec4(newColors[i].rgb, 1.0) * color;
        }
    }
    
    return pixel * color;
}
]])

local oldColors = {
    {1,1,1,0},
	{2/3,2/3,2/3,1},
    {1/3,1/3,1/3,1},
    {0,0,0,1}
}
function sendPalette(pal)
	nesShader:send("n", #oldColors)
	nesShader:send("oldColors", unpack(oldColors))
	nesShader:send("newColors", unpack(pal))
end
function bn(b)
	return (b == true) and 1 or 0
end
function math.sign(s)
	return (s > 0 and 1) or (s < 0 and -1) or 0
end
function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end
function table.find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end
function col_rectinrect(x1,y1,w1,h1,x2,y2,w2,h2)
    return x1 + w1 >= x2 and x1 <= x2 + w2 and y1 + h1 >= y2 and y1 <= y2 + h2
end
function col_pointinrect(px,py, rx,ry,rw,rh)
    return px >= rx and px < rx+rw and py >= ry and py < ry+rh
end
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
function resetlevel()
    Game.world:init(32, 15)
	Game.world.world = {
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,},
		{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,},
		{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,}
	}
	Game.world.player = lo.mario:New({x = 0,y = 0})
	Game.world.objects = {
		lo.goomba:New({x = 128,y = 164}),
		lo.goomba:New({x = 128+32,y = 164}),
        lo.koopa:New({x = 128+128,y = 164}),
	}
end
function drawTile(t, x, y, flipx, flipy)
	love.graphics.draw(t > 255 and img_sprmap or img_tilemap, tilequads[t], x+(flipx and 8 or 0), y+(flipy and 8 or 0), 0, flipx and -1 or 1, flipy and -1 or 1)
end
function drawSprite(sprt, x, y, flipx, flipy)
    local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
    for _, v in pairs(sprt) do
        minx = math.min(minx, v[2])
        maxx = math.max(maxx, v[2])
        miny = math.min(miny, v[3])
        maxy = math.max(maxy, v[3])
    end
    local sprWidth = maxx - minx
    local sprHeight = maxy - miny

    for _, v in pairs(sprt) do
        local tile, ox, oy, tflipx, tflipy = v[1], v[2], v[3], v[4], v[5]

        if flipx then
            ox = sprWidth - (ox - minx) + minx
            tflipx = not tflipx
        end

        if flipy then
            oy = sprHeight - (oy - miny) + miny
            tflipy = not tflipy
        end

        drawTile(tile, x + ox, y + oy, tflipx, tflipy)
    end
end

local alphabet = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", " "}
function renderText(x, y, text)
    for i=1,string.len(text) do
        local l = string.sub(text, i, i)
        local ti = table.find(alphabet, l)
		if ti then
			drawTile(ti-1, x+(i*8), y, false, false)
		end
    end
end

local function loadCHR(path)
    local file = assert(love.filesystem.read(path))
    local rom = file

    local prgSize = rom:byte(5) * 16384
    local chrSize = rom:byte(6) * 8192
    if chrSize == 0 then error("ROM has no CHR data") end

    local chrData = {}
    for i = 1, chrSize do
        chrData[i] = rom:byte(16 + prgSize + i)
    end

    local bit = require("bit")
    local tilesPerRow = 16
    local rowsPerSheet = 16
    local sheetW, sheetH = tilesPerRow * 8, rowsPerSheet * 8

    local tilemapData = love.image.newImageData(sheetW, sheetH)
    local sprmapData  = love.image.newImageData(sheetW, sheetH)

    for t = 0, (chrSize / 16) - 1 do
        local targetSheet
        local idx
        if t < 256 then
            targetSheet = tilemapData
            idx = t
        else
            targetSheet = sprmapData
            idx = t - 256
        end

        local tx = (idx % tilesPerRow) * 8
        local ty = math.floor(idx / tilesPerRow) * 8

        for y = 0, 7 do
            local plane0 = chrData[t*16 + y + 1]
            local plane1 = chrData[t*16 + y + 9]

            for x = 0, 7 do
                local bit0 = bit.band(bit.rshift(plane0, 7 - x), 1)
                local bit1 = bit.band(bit.rshift(plane1, 7 - x), 1)
                local colorIndex = bit.bor(bit.lshift(bit1, 1), bit0)

                local c = colorIndex / 3
				local c2 = 1-c
                targetSheet:setPixel(tx + x, ty + y, c2, c2, c2, c == 0 and 0 or 1)
            end
        end
    end

    return love.graphics.newImage(tilemapData), love.graphics.newImage(sprmapData)
end



function love.load()
	min_dt = 1/60
	next_time = love.timer.getTime()

    love.filesystem.setIdentity("smaspc")
    cwd = love.filesystem.getSaveDirectory()

    exists = love.filesystem.getInfo("Super Mario Bros. (World).nes")
    if exists then
        img_sprmap, img_tilemap = loadCHR("Super Mario Bros. (World).nes")
    else
        return
    end
	
	love.graphics.setBackgroundColor(118/255,134/255,1,1)

    for q=1,256 do
        local i = q-1
        local x = (i%16)*8
        local y = math.floor(i/16)*8
        tilequads[i] = love.graphics.newQuad(x, y, 8, 8, img_tilemap)
    end
    for q=1,256 do
        local i = q-1
        local x = (i%16)*8
        local y = math.floor(i/16)*8
        tilequads[i+256] = love.graphics.newQuad(x, y, 8, 8, img_sprmap)
    end

	--img_tilemap:setFilter("nearest", "nearest")
	--img_sprmap:setFilter("nearest", "nearest")

	resetlevel()
end

function love.update(dt)
	next_time = next_time + min_dt
	Game.input[1] = love.keyboard.isDown("right")
	Game.input[2] = love.keyboard.isDown("left")
	Game.input[3] = love.keyboard.isDown("up")
	Game.input[4] = love.keyboard.isDown("down")
	if love.keyboard.isDown("y") then
		Game.input[5] = Game.input[5]+1
	else
		Game.input[5] = 0
	end
	if love.keyboard.isDown("x") then
		Game.input[6] = Game.input[6]+1
	else
		Game.input[6] = 0
	end
	Game.world:update(dt)
	
	--clamp camera
	Game.camera[1] = math.clamp(Game.camera[1], 0, (Game.world.width*16)-256)
	Game.camera[2] = math.clamp(Game.camera[2], 0, (Game.world.height*16)-240)
end

function love.draw()
	Game.world:draw(16, math.floor(Game.camera[1]), math.floor(Game.camera[2]))
	renderText(8, 8, "THIS IS A TEST")
	--love.graphics.draw(img_sprmap, 256, 0)
	--love.graphics.draw(img_tilemap, 0, 0)
	
	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
		next_time = cur_time
		return
	end
	love.timer.sleep(next_time - cur_time)
end