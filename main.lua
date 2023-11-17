if arg[2] == "debug" then
    require("lldebugger").start()
end
local maid64 = require "maid64"

local utf8 = require("utf8")
local playerFunctions = require("playerFunctions")
--settings
local screenWidth = 320
local screenHight = 240

local textInput = ""
local text = ""
local oldText = ""
require "playerFunctions"
local player = {
    health = 1,
    x = 50,
    y = 50,
    speed = 50,
    moveToX = 50,
    moveToY = 50,
    move = false;
}

function love.load()
    --optional settings for window
    love.window.setMode(800, 600, {resizable=true, vsync=false, minwidth=200, minheight=200})
    
    --initilizing maid64 for use and set to 64x64 mode 
    --can take 2 parameters x and y if needed for example maid64.setup(64,32)
    maid64.setup(screenWidth, screenHight)

    font = love.graphics.newFont('pico-8-mono.ttf', 8)
    --font:setFilter('nearest', 'nearest')

    love.graphics.setFont(font)
    
    -- create test sprite
    maid = maid64.newImage("maid64.png")

    -- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
    love.keyboard.setKeyRepeat(true)
   
end
function love.update(dt)
    --check the player stays withinscreen
    playerFunctions.PlayerDontExitScreen(player)
    --check if we should move the player
    playerFunctions.MovePlayer(player,dt)
end
function love.draw()
    
    maid64.start()--starts the maid64 process

    --draw images here
    love.graphics.rectangle('fill', player.x, player.y, 4,4)
    --can also draw shapes and get mouse position
    love.graphics.circle("fill", maid64.mouse.getX(),  maid64.mouse.getY(), 2)
    love.graphics.print(maid64.mouse.getX() .. ',' .. maid64.mouse.getY(), 260,8)
    love.graphics.print('> ' .. textInput, 0, 226)
    love.graphics.setFont(font, 4)
    love.graphics.print('' .. oldText, 0, 226-14-14)
    love.graphics.print('' .. text, 0, 226-14)



    maid64.finish()--finishes the maid64 process
end

function love.resize(w, h)
    -- this is used to resize the screen correctly
    maid64.resize(w, h)
end

function love.textinput(t)
    textInput = textInput .. t
end

function love.keypressed(key)
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(textInput, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            textInput = string.sub(textInput, 1, byteoffset - 1)
        end
    end
    if key == "return" then
        oldText = text
        CheckPlayerCommands()
        text = textInput
        textInput = ""
    end
end

function CheckPlayerCommands()
    if string.find(textInput, "move") then
        local x, y = ExtractCoordinates(textInput)
        if type(x) == "number" and type(y) == "number" then
            player.moveToX = x
            player.moveToY = y
        end
    end
    if string.find(textInput, 'stop') then
        player.moveToX = player.x
        player.moveToY = player.y
    end
    if string.find(textInput, 'move left') then
        player.moveToX = 0
    end
    if string.find(textInput, 'move right') then
        player.moveToX = screenWidth
    end
    if string.find(textInput, 'move up') then
        player.moveToY = 0
    end
    if string.find(textInput, 'move down') then
        player.moveToY = screenHight
    end
    if string.find(textInput, 'move upleft') then
        player.moveToY = 0
        player.moveToX = 0
    end
    if string.find(textInput, 'move downleft') then
        player.moveToY = screenHight
        player.moveToX = 0
    end
    if string.find(textInput, 'move upright') then
        player.moveToY = 0
        player.moveToX = screenWidth
    end
    if string.find(textInput, 'move downright') then
        player.moveToY = screenHight
        player.moveToX = screenWidth
    end
end

function MoveTowards(object, targetX, targetY, dt)
    local angle = math.atan2(targetY - object.y, targetX - object.x)
    
    -- Calculate the distance to the target
    local distance = object.speed * dt
    
    -- Calculate the new position
    local newX = object.x + distance * math.cos(angle)
    local newY = object.y + distance * math.sin(angle)
    
    -- Update the object's position
    object.x = newX
    object.y = newY
end

-- Function to extract x and y values from a coordinate string
function ExtractCoordinates(coordinateString)
    local x, y = coordinateString:match("move (%d+),(%d+)")
    return tonumber(x), tonumber(y)
end

