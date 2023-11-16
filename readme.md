windows

REMEMBER TO SET conf.lua: 
function love.conf(t)
	t.console = false
end

if you set t.console = true then a external terminal window will open

in the main.lua:
if arg[2] == "debug" then
    require("lldebugger").start()
end