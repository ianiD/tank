local logo = {}

function logo.load()
	logo.image = love.graphics.newImage("res/logo.png")
end

function logo.enter()
	love.window.setTitle("Tank game")
	logo.time = 0
end

function logo.update(dt)
	logo.time = logo.time + dt
	if logo.time >= 5 or love.keyboard.isDown("escape") then
		return "menu"
	end
end

function logo.draw()
	local w, h = logo.image:getDimensions()
	local W, H = love.graphics.getDimensions()
	love.graphics.draw(logo.image, (W-w)/2, (H-h)/2);
end

return logo
