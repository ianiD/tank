require "enet"
local callbacks = require "callbacks"

math.randomseed(os.time())
tanks = {}
projectiles, projectileSpeed, pCount = {}, 1000, 0
chatToBeSent = {}
killsToBeSent = {}
DToBeSent = {}
CToBeSent = {}
local ups = 60
local last, host
local tbu = 1 / ups

function bytesum(a)
	local s = 0
	for i = 1, #a do
	    s = s + a:byte(i)
	end
	return s
end

function love.load()
	host = enet.host_create("*:9149")
	last = love.timer.getTime()
end

function love.update(dt)
	local event = host:service()	--get events waiting to be handled
	while event do 					--if there are events, handle them
		if event.type == "receive" then 		callbacks.receive(event)
		elseif event.type == "connect" then		callbacks.connect(event)
		elseif event.type == "disconnect" then	callbacks.disconnect(event)
		end
		event = host:service()		--are there more events? Handle them too
	end
	for _, p in pairs(projectiles) do
		p.time = p.time + dt
		if p.time > 5 then
			projectiles[_] = nil
		end
	end
	for _, t in pairs(tanks) do
		for _, p in pairs(projectiles) do
			if (t.x - (p.xStart + p.xvel * p.time))*(t.x - (p.xStart + p.xvel * p.time)) + (t.y - (p.yStart + p.yvel * p.time))*(t.y - (p.yStart + p.yvel * p.time)) < 400 then
				if p.user ~= t.nick then
					projectiles[_] = nil
					table.insert(killsToBeSent, {t.nick, p.user, _})
					t.deaths = t.deaths + 1
					tanks[p.user].kills = tanks[p.user].kills + 1
					math.randomseed(bytesum(t.nick))
					t.x = math.random() * 600 + 100
					t.y = math.random() * 400 + 100
				end
			end
		end
	end
	if love.timer.getTime() - last > tbu then	--send data to clients every tbu seconds
		sendData()
		last = love.timer.getTime()
	end
	for _, t in pairs(tanks) do if t.shouldDie then tanks[_] = nil end end
	collectgarbage()
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("Tanks:", 10, 10)
	local i = 0
	for _, t in pairs(tanks) do
		i = i + 1
		love.graphics.setColor(t.color)
		love.graphics.rectangle("fill", 10, i*50, 200, 45)
		love.graphics.setColor({0, 0, 0})
		love.graphics.print(t.nick, 20, i*50+10)
	end
end

function sendData()

	--send new connections
	--must be first because the client initialises tanks on this event and if the "t" event fired before it would raise an error
	for i = 1, #CToBeSent do
		host:broadcast("C "..CToBeSent[i].." "..tanks[CToBeSent[i]].x.." "..tanks[CToBeSent[i]].y.." "..tanks[CToBeSent[i]].rot.." N N N N N")
	end
	CToBeSent = {}

	--send tank data
	for _, t in pairs(tanks) do
		host:broadcast("t "..t.nick.." "..t.x.." "..t.y.." "..t.rot.." ".."0".." "..t.kills.." "..t.deaths.." N N")
	end

	--send projectile data
	for _, p in pairs(projectiles) do
		host:broadcast("p "..p.user.." ".._.." "..p.time.." "..p.xvel.." "..p.yvel.." "..p.xStart.." "..p.yStart.." N N")
	end

	--send kill data
	for i = 1, #killsToBeSent do
		host:broadcast("k "..killsToBeSent[i][1].." "..killsToBeSent[i][2].." "..killsToBeSent[i][3].." N N N N N N")
	end
	killsToBeSent = {}

	--send chat data
	for i = 1, #chatToBeSent do
		host:broadcast("c "..chatToBeSent[i][1].." "..chatToBeSent[i][2]:gsub("%s", "_").." N N N N N N N")
	end
	chatToBeSent = {}

	--send disconnected
	for i = 1, #DToBeSent do
		host:broadcast("D "..DToBeSent[i].." N N N N N N N N")
	end
	DToBeSent = {}

	host:flush()

end
