local callbacks = {}
callbacks.nickOf = {}

function callbacks.receive(event)
	local a, b, c, d, e, g, h, i, j = event.data:match("(.+) (.+) (.+) (.+) (.+) (.+) (.+) (.+) (.+) (.+)")
	if a == "t" then	--tank info
		if c ~= "N" then tanks[b].x = tonumber(c) end
		if d ~= "N" then tanks[b].y = tonumber(d) end
		if e ~= "N" then tanks[b].rot = tonumber(e) end
		if f ~= "N" then tanks[b].deltap = tonumber(f) end
	elseif a == "p" then--projectile info
		local newP = {}
		newP.user = b
		newP.time = 0
		newP.xvel = math.cos(tanks[b].rot) * projectileSpeed
		newP.yvel = math.sin(tanks[b].rot) * projectileSpeed
		newP.xStart = tanks[b].x
		newP.yStart = tanks[b].y
		pCount = pCount + 1
		projectiles[pCount] = newP
	elseif a == "c" then--chat
		chatToBeSent[#chatToBeSent+1]={b, c:gsub("%s", "_")}
	elseif a == "D" then--disconnect
		tanks[b].shouldDie = true
		DToBeSent[#DToBeSent+1]= b
		chatToBeSent[#chatToBeSent+1] = {"Server", b.." Disconnected"}
	elseif a == "C" then--connect
		tanks[b] = {nick = b, x = c, y = d, rot = e, kills = 0, deaths = 0, deltap = 0, shouldDie = false}

		math.randomseed(bytesum(b))
		math.random(); math.random(); math.random()
		tanks[b].color = {math.random()*255, math.random()*255, math.random()*255}
		local cmax = math.max(tanks[b].color[1], tanks[b].color[2], tanks[b].color[3])
		tanks[b].color[1] = tanks[b].color[1] * 255 / cmax
		tanks[b].color[2] = tanks[b].color[2] * 255 / cmax
		tanks[b].color[3] = tanks[b].color[3] * 255 / cmax

		callbacks.nickOf[tonumber(event.peer:index())] = b
		table.insert(chatToBeSent, {"Server", b.." Connected"})
		table.insert(CToBeSent, b)

		for _, t in pairs(tanks) do
			event.peer:send("C ".._.." "..t.x.." "..t.y.." "..t.rot.." N N N N N")
		end
	end
end

function callbacks.connect(event)
end

function callbacks.disconnect(event)
	if tanks[callbacks.nickOf[tonumber(event.peer:index())]] then
		table.insert(DToBeSent, callbacks.nickOf[tonumber(event.peer:index())])
		table.insert(chatToBeSent, callbacks.nickOf[tonumber(event.peer:index())].." Disconnected")
	end
end

return callbacks
