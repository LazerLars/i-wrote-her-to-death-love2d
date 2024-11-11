sounds from Freesound.org
Vintage Keyboard 3 by jim-ph -- https://freesound.org/s/194797/ -- License: Creative Commons 0
Shotgun Shot sfx by lumikon -- https://freesound.org/s/564480/ -- License: Creative Commons 0

windows:::

REMEMBER TO SET conf.lua: 
function love.conf(t)
	t.console = false
end

if you set t.console = true then a external terminal window will open

in the main.lua:
if arg[2] == "debug" then
    require("lldebugger").start()
end

Option + 8 / 9 = []
option + shift + 8 / 9 = {}