--SEE README

local state
local states = {}

local function ef() end

local function newState(name)
	states[name] = require(name)
	pcall(states[name].load)
end

local function setState(name, data)
	if state and states[state] then
		local s, e = pcall(states[state].exit or ef)
		if not s then --gotta copy handleError code because it's not yet a thing
			print(e)
			print(debug.traceback())
			setState("error", {e})
		end
	end
	state = name
	s, e = pcall(states[state].enter or ef, data)
	if not s then	--gotta copy handleError code because it's not yet a thing
		print(e)
		print(debug.traceback())
		setState("error", {e})
	end
end

local function handleError(errMsg)
	print(errMsg)
	print(debug.traceback())
	setState("error", {errMsg})
end

function love.load()
	newState("logo")
	newState("menu")
	newState("play")
	newState("error")

	setState("logo")
end

function love.update(dt)
	local a, b, c = pcall(states[state].update or ef, dt)
	if not a then	--error
		handleError(b)
	else
		if b then	--b was also called nextState
			setState(b, c)	--c was also called data
		end
	end
end

function love.draw()
	local status, err = pcall(states[state].draw or ef)
	if not status then handleError(err) end
end

--[[

Callback functions:
function love.magic(s, t, u, f, F)
	local s, e = pcall(states[state].magic or ef, s, t, u, f, F)	--pcall that function or empty_function(if the initial function is nil)
	if not s then	--if there was an error
		handleError(e)	--handle it
	end
end

--]]

function love.keypressed(k, r)local s,e=pcall(states[state].keypressed or ef,k,r);if not s then handleError(e) end end
function love.keyreleased(k)local s,e=pcall(states[state].keyreleased or ef,k);if not s then handleError(e) end end

function love.textinput(text)local s,e=pcall(states[state].textinput or ef,text);if not s then handleError(e) end end

function love.mousemoved(x, y, dx, dy)local s,e=pcall(states[state].mousemoved or ef,x,y,dx,dy);if not s then handleError(e) end end
function love.mousepressed(x, y, b)local s,e=pcall(states[state].mousepressed or ef,x,y,b);if not s then handleError(e) end end
function love.mousereleased(x, y, b)local s,e=pcall(states[state].mousereleased or ef,x,y,b);if not s then handleError(e) end end

function love.quit()local s,e=pcall(states[state].quit or ef);if not s then handleError(e) end return e or false end
