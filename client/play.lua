require "enet"
local utf8 = require "utf8"

local play = {}
play.myTank = {}
play.tanks = {}
play.chat = {}
play.projectiles = {}
play.left, play.right = 0, 0
play.lastFired = 0
play.fireRate = 1
local ups = 60
local tbu = 1 / ups
local last

function play.load()
	play.tankBody = love.graphics.newImage("res/body.png")
	play.track = {love.graphics.newImage("res/track1.png"), love.graphics.newImage("res/track2.png"), love.graphics.newImage("res/track3.png")}
	play.width = love.graphics.getWidth()
	play.height = love.graphics.getHeight()

	love.keyboard.setKeyRepeat(true)
	love.graphics.setDefaultFilter("nearest", "nearest", 1)

	love.touch = love.touch or {}
	love.touch.getTouch = love.touch.getTouch or function() end
	love.touch.getTouchCount = love.touch.getTouchCount or function() return 0 end
end

local function bytesum(a)
	local s = 0
	for i = 1, #a do
	    s = s + a:byte(i)
	end
	return s
end

local function generateTank(nick)
	math.randomseed(bytesum(nick))
	local t = {}
	t.nick = nick
	t.x = math.random() * 200 + 100; t.y = math.random() * 200 + 100; t.rot = math.random() * math.pi * 2
	t.lTrack = 0; t.rTrack = 0
	t.color = {math.random()%2*255, math.random()%2*255, math.random()%2*255}
	local cmax = math.max(t.color[1], t.color[2], t.color[3])
	t.color[1] = t.color[1] * 255 / cmax
	t.color[2] = t.color[2] * 255 / cmax
	t.color[3] = t.color[3] * 255 / cmax

	t.kills=0; t.deaths = 0
	return t
end

function play.enter(data)
	play.chat = {}
	table.insert(play.chat, "Chat v1")
	table.insert(play.chat, "")
	play.myTank = generateTank(data[2])
	--play.tanks[data[2]] = generateTank(data[2])
	play.net = {}
	play.net.address = data[1]..":9149"
	play.net.host = enet.host_create()
	play.net.server = play.net.host:connect(data[1]..":9149")
	play.net.server:timeout(31, 5000, 5000)
	last = love.timer.getTime()

	love.graphics.setFont(love.graphics.newFont(12))

	love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)

	play.chat.message = ""
	play.chat.active = false

	play.shouldMenu = false
end

function play.update(dt)
	if play.shouldMenu then return "menu" end
	if play.net.server:state() == "disconnected" then return "menu", {"Lost connection to server"} end

	love.window.setTitle("Tank game | "..love.timer.getFPS().."FPS   "..play.myTank.nick.."@"..play.net.address.." ("..play.net.server:state()..")")
	local event = play.net.host:service()	--get network events waiting
	while event do
		if event.type == "receive" then
			local a, b, c, d, e, f, g, h, i, j = event.data:match("(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
			if 		a == "t" then 	--tank info
				play.tanks[b] = play.tanks[b] or {}
				if c ~= "N" then play.tanks[b].x = tonumber(c) end
				if d ~= "N" then play.tanks[b].y = tonumber(d) end
				if e ~= "N" then play.tanks[b].rot = tonumber(e) end
				if f ~= "N" then play.tanks[b].dp = tonumber(f) end
				if g ~= "N" then play.tanks[b].kills = tonumber(g) end
				if h ~= "N" then play.tanks[b].deaths = tonumber(h) end
			elseif 	a == "p" then	--projectile info
				print(a, b, c, d, e, f, g, h, i, j)
				play.projectiles[c] = play.projectiles[c] or {}
				if b ~= "N" then play.projectiles[c].user = b end
				if d ~= "N" then play.projectiles[c].time = d end
				if e ~= "N" then play.projectiles[c].xvel = e end
				if f ~= "N" then play.projectiles[c].yvel = f end
				if g ~= "N" then play.projectiles[c].xStart = g end
				if h ~= "N" then play.projectiles[c].yStart = h end
			elseif 	a == "c" then	--chat
				play.chat[#play.chat+1]="<"..b.."> "..c:gsub("_", " ")
			elseif 	a == "k" then	--kill
				play.chat[#play.chat+1]=c.." killed "..b
				play.projectiles[d] = nil
				if b == play.myTank.nick then

				end
			elseif 	a == "D" then	--disconnect
				play.tanks[b] = nil
				for _, p in pairs(play.projectiles) do
					if p.user == b then p = nil end
				end
				collectgarbage()
			elseif	a == "C" then	--connect
				play.tanks[b] = {nick = b, x = tonumber(c), y = tonumber(d), rot = tonumber(e), dp = 0, kills = 0, deaths = 0}

				math.randomseed(bytesum(b))
				math.random(); math.random(); math.random()
				play.tanks[b].color = {math.random()*255, math.random()*255, math.random()*255}
				local cmax = math.max(play.tanks[b].color[1], play.tanks[b].color[2], play.tanks[b].color[3])
				play.tanks[b].color[1] = play.tanks[b].color[1] * 255 / cmax
				play.tanks[b].color[2] = play.tanks[b].color[2] * 255 / cmax
				play.tanks[b].color[3] = play.tanks[b].color[3] * 255 / cmax
			end
		elseif event.type == "connect" then
			play.net.server:send("C "..play.myTank.nick .." ".. play.myTank.x .." ".. play.myTank.y .." ".. play.myTank.rot .." N N N N N")
		end
		event = play.net.host:service()	--any more events?
	end

	local left, right = play.handleInput()
	play.handleMovement(play.myTank, left, right, dt)
	for _, t in pairs(play.tanks) do
		play.handleMovement(t, 0, 0, dt)
		for _, p in pairs(play.projectiles) do
			if (t.x - (p.xStart + p.xvel * p.time))*(t.x - (p.xStart + p.xvel * p.time)) + (t.y - (p.yStart + p.yvel * p.time))*(t.y - (p.yStart + p.yvel * p.time)) < 450 then
				if p.user ~= t.nick then
					play.projectiles[_] = nil
					if t.nick == play.myTank.nick then
						math.randomseed(bytesum(t.nick))
						play.myTank.x = math.random() * 600 + 100
						play.myTank.y = math.random() * 400 + 100
					end
				end
			end
		end
	end

	play.handleProjectiles()

	if love.timer.getTime() - last > tbu and play.myTank.x then	--send data to clients every tbu seconds
		play.net.server:send("t "..play.myTank.nick .." ".. play.myTank.x .." ".. play.myTank.y .." ".. play.myTank.rot .." "..play.myTank.dp.." N N N N")
		last = love.timer.getTime()
	end
end

function play.draw()
	drawTanks()
	drawProjectiles()
	drawGUI()
end

function drawTanks()
	for _, t in pairs(play.tanks) do
		if t.nick and t.nick == play.myTank.nick then t = play.myTank end
		love.graphics.setColor(t.color)
		love.graphics.draw(play.track[1], t.x, t.y, t.rot + math.pi / 2, 2, -2,  7, 8)
		love.graphics.draw(play.track[1], t.x, t.y, t.rot + math.pi / 2, 2, -2, -3, 8)
		love.graphics.draw(play.tankBody, t.x, t.y, t.rot + math.pi / 2, 2, 2, 8, 8)

		love.graphics.setColor(255, 255, 255)
		love.graphics.printf(t.nick, t.x, t.y-50, 0, "center")
	end
end

function drawProjectiles()
	for _, p in pairs(play.projectiles) do
		if play.tanks[p.user] then
			love.graphics.setColor(play.tanks[p.user].color)
			love.graphics.circle("fill", p.xStart + p.time * p.xvel, p.yStart + p.time * p.yvel, 3, 10)
		else
			play.projectiles[_] = nil
		end
	end
	love.graphics.setColor(255, 255, 255)
end

function drawGUI()
	if love.keyboard.isDown("tab") then
		local i = 1
		love.graphics.setColor(255, 255, 255, 100)
		love.graphics.rectangle("fill", 200, 30, 400, 28)
		love.graphics.setColor(0, 0, 0, 200)
		love.graphics.print("Nickname", 210, 35)
		love.graphics.print("Kills", 410, 35)
		love.graphics.print("Deaths", 510, 35)
		for _, t in pairs(play.tanks) do
			i = i + 1
			if t.nick then
				love.graphics.setColor({t.color[1], t.color[2], t.color[3], 100})
				love.graphics.rectangle("fill", 200, i*30, 400, 28)
				love.graphics.setColor(0, 0, 0, 200)
				love.graphics.print(tostring(t.nick), 210, i*30 + 5)
				love.graphics.print(tostring(t.kills), 410, i*30 + 5)
				love.graphics.print(tostring(t.deaths), 510, i*30 + 5)
			end
		end
	end

	for i = #play.chat-10, #play.chat do
		love.graphics.print(play.chat[i] or "", 10, 100 + 14 * (i - #play.chat + 10))
	end
	love.graphics.print(play.chat.message..((play.chat.active and os.time() % 2 == 0) and "|" or ""), 10, 260)

	local function q(rot)
		local a = rot%(2*math.pi)
		if a < math.pi then
			return a
		else
			return a - 2*math.pi
		end
	end
	local E, W, N, S = q(play.myTank.rot), q(play.myTank.rot-math.pi), q(play.myTank.rot+math.pi/2), q(play.myTank.rot-math.pi/2)
	love.graphics.print("E", E * -280 + 400, 30)
	love.graphics.print("W", W * -280 + 400, 30)
	love.graphics.print("N", N * -280 + 400, 30)
	love.graphics.print("S", S * -280 + 400, 30)

	for _, t in pairs(play.tanks) do
		if t.nick ~= play.myTank.nick then
			local angle = math.atan2(t.y-play.myTank.y, t.x-play.myTank.x)
			love.graphics.setColor(t.color)
			love.graphics.circle("fill", q(angle - play.myTank.rot) * 280 + 400, 15, 10, 6)
		end
	end

	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("line", 0, 5, 396, 20)
	love.graphics.rectangle("line", 404, 5, 396, 20)
end

function play.keypressed(k, r)
	if k == "return" then
		if play.chat.active and play.chat.message ~= "" then
			play.net.server:send("c "..play.myTank.nick.." "..play.chat.message:gsub("%s", "_").." N N N N N N N")
			play.chat.message = ""
		end
		play.chat.active = not play.chat.active
	end
	if k == "escape" then
		if play.chat.active then play.chat.active = false
		else play.shouldMenu = true end
	end
	if k == "backspace" and play.chat.active then
        local byteoffset = utf8.offset(play.chat.message, -1)
        if byteoffset then
            play.chat.message = string.sub(play.chat.message, 1, byteoffset - 1)
        end
	end
end

function play.textinput(t)
	if play.chat.active then
		t = t or ""
	    play.chat.message = play.chat.message .. t
	end
end

function play.handleInput()
	local left, right = 0, 0
	if love.keyboard.isDown('up') then
		left = left + 0.5
		right = right + 0.5
	end
	if love.keyboard.isDown('left') then
		left = left + 0.5
	end
	if love.keyboard.isDown('right') then
		right = right + 0.5
	end

	for i = 1, love.touch.getTouchCount() do
		local index, x, y, pressure = love.touch.getTouch(i)
		left = left + (0.5 - x)
		right = right + (x - 0.5)
	end
	return left, right
end

function play.handleMovement(t, left, right, dt)
	local rotSpd = 5
	local movSpd = 100
	local trackSpd = 15

	if t.nick == play.myTank.nick then
		local dr = right * dt * rotSpd - left  * dt * rotSpd
		t.dp = left  * movSpd + right * movSpd

		t.rot = t.rot + dr
	end

	t.x = t.x + math.cos(t.rot) * t.dp * dt
	t.y = t.y + math.sin(t.rot) * t.dp * dt
end

function play.handleProjectiles()
	if love.keyboard.isDown(" ") and (love.timer.getTime() - play.lastFired) > play.fireRate then
		play.lastFired = love.timer.getTime()
		play.net.server:send("p "..play.myTank.nick.." N N N N N N N N")
	end
end

function play.quit()
	play.net.server:send("D "..play.myTank.nick.." N N N N N N N N")
	play.net.host:flush()
	love.event.wait(1000)
	play.net.server:disconnect()
	play.net.host:flush()
end

function play.exit()
	play.net.server:send("D "..play.myTank.nick.." N N N N N N N N")
	play.net.host:flush()
	love.event.wait(1000)
	play.net.server:disconnect()
	play.net.host:flush()
end

return play
