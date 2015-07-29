local errorState = {}

function errorState.load()
    errorState.img = love.graphics.newImage("res/error.png")
    errorState.w = love.window:getWidth()
    errorState.font = love.graphics.newFont(12)
end

function errorState.enter(data)
    print("errorState: "..data[1])
    errorState.msg = data[1]
    love.graphics.setFont(errorState.font)
    errorState.shouldQuit = false
end

function errorState.update(dt)
    if errorState.shouldQuit then return "logo" end
end

function errorState.keypressed()
    errorState.shouldQuit = true
end

function errorState.draw()

    --shamelessly taken code from the default love.errhand
    local trace = debug.traceback()

    local err = {}

	table.insert(err, "Error\n")
	table.insert(err, errorState.msg.."\n\n")

	for l in string.gmatch(trace, "(.-)\n") do
		if not string.match(l, "boot.lua") then
			l = string.gsub(l, "stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

    love.graphics.setColor(0, 20, 40)
    love.graphics.rectangle("fill", 0, 0, 1000, 1000)
        love.graphics.setColor(255, 255, 255)
    love.graphics.draw(errorState.img, errorState.w-266, 10)
    love.graphics.printf(p, 70, 70, errorState.w-266)
end

return errorState
