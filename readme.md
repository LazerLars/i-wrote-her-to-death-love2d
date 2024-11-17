sounds from Freesound.org
Vintage Keyboard 3 by jim-ph -- https://freesound.org/s/194797/ -- License: Creative Commons 0
Shotgun Shot sfx by lumikon -- https://freesound.org/s/564480/ -- License: Creative Commons 0
female-hurt-2.wav by birdOfTheNorth -- https://freesound.org/s/577969/ -- License: Creative Commons 0
Hurt  1 - (Male) by Christopherderp -- https://freesound.org/s/342229/ -- License: Creative Commons 0
shotgun_shell_drop.wav by ThompsonMan -- https://freesound.org/s/107342/ -- License: Attribution 4.0
shotgun_reload.mp3 by zekybomb -- https://freesound.org/s/677662/ -- License: Creative Commons 0
Gun Click by knova -- https://freesound.org/s/170272/ -- License: Attribution 4.0

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