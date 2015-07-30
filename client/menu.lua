local utf8 = require "utf8"

local menu = {}

function menu.load()
	menu.font = love.graphics.newFont(30)
end

function menu.enter(data)
	data = data or {}
	menu.address = "localhost"
	menu.nick = "Player"
	menu.selected = "nick"
	menu.fromLast = data[1] or ""
	love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
end

function menu.update(dt)
	love.window.setTitle("Tank game | "..love.timer.getFPS().."FPS   "..menu.nick.."@"..menu.address)
	if love.keyboard.isDown("return") then
		return "play", {menu.address, menu.nick}
	end
end

function menu.draw()
	love.graphics.setColor(100, 100, 100)
	love.graphics.rectangle("fill", 10, 40, 400, 40)
	love.graphics.rectangle("fill", 10, 110, 400, 40)

	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(menu.font)
	love.graphics.print("Enter server address:", 10, 10)
	love.graphics.print(menu.address..((love.timer.getTime()*2%2<1 and menu.selected=="address") and "|" or ""), 10, 40)
	love.graphics.print("Enter nickname:", 10, 80)
	love.graphics.print(menu.nick..((love.timer.getTime()*2%2<1 and menu.selected=="nick") and "|" or ""), 10, 110)
	love.graphics.print("Press enter to join", 10, 150)

	love.graphics.print(menu.fromLast, 50, 200)
end

function menu.textinput(t)
	if menu.selected then
		t = t or ""
	    menu[menu.selected] = menu[menu.selected] .. t
	end
end

function menu.keypressed(key)
	if menu.selected then
	    if key == "backspace" then
	        local byteoffset = utf8.offset(menu[menu.selected], -1)
	        if byteoffset then
	            menu[menu.selected] = string.sub(menu[menu.selected], 1, byteoffset - 1)
	        end
	    end
	end
end

function menu.mousepressed(x, y, b)
	if x<410 then
		if y>40 and y<80 then menu.selected = "address"
		elseif y>110 and y<150 then menu.selected = "nick"
		else menu.selected="" end
	else menu.selected="" end
end

return menu
