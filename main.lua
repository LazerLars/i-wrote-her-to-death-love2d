if arg[2] == "debug" then
    require("lldebugger").start()
end
local maid64 = require "maid64"

local utf8 = require("utf8")
local playerFunctions = require("playerFunctions")
local enemyFunctions = require("enemyFunctions")

--settings
local screenWidth = 320
local screenHight = 240

local textInput = ""
local text = ""
local oldText = ""
local CheckForEnemyWordBool = false

local player = {
    width = 8,
    height = 8,
    health = 5,
    x = screenWidth /2,
    y = screenHight/2,
    speed = 50,
    moveToX = screenWidth /2,
    moveToY = screenHight/2,
    move = false,
    female = true
}

local game = {
    pause = false
}

local tablesByFirstLetter = {}
local wordsTable = {}
local filename = "texts/10kMostCommonEngWords.txt"
local enemyCounter = 0

local bulletList = {}
local bulletAdded = false

-- Table to hold explosion particles
local particles = {}

-- Settings for explosion particles
local explosionSettings = {
    particleSize = 2,           -- Size of each "fragment"
    particleLifetime = 1,       -- Lifetime of each particle (in seconds)
    speed = 50,                 -- Initial speed of particles
}

-- Table to hold ejected shells
local shells = {}

-- Settings for shells
local shellSettings = {
    width = 2,                      -- Width of the shell
    height = 4,                     -- Height of the shell
    lifetime = 1,                   -- Shell fade-out time in seconds
    speed = 100,                    -- Initial speed of shell
    gravity = 50,                   -- Gravity to pull shell downwards
    rotationSpeed = math.pi / 4     -- Rotation speed of the shell
}

function love.load()
    print("lets go")
    ReadTxtFileToATable(filename)
    print(wordsTable[9959])
    wordsTable = Shuffle(wordsTable)
    wordsTable = AdvancedShuffle(wordsTable)
    
    print(wordsTable[9959])

    --optional settings for window
    love.window.setMode(screenWidth * 3, screenHight * 3, {resizable=true, vsync=false, minwidth=200, minheight=200})
    
    --initilizing maid64 for use and set to 64x64 mode 
    --can take 2 parameters x and y if needed for example maid64.setup(64,32)
    maid64.setup(screenWidth, screenHight)
    love.graphics.setDefaultFilter("nearest", "nearest")
    

    --font = love.graphics.newFont('fonts/pico-8-mono.otf', 8)
    --font = love.graphics.newFont('fonts/pico-8-mono.ttf', 8)
    font = love.graphics.newFont('fonts/PressStart2P-Regular.ttf', 8)
    --not needed when appling love.graphics.setDefaultFilter("nearest", "nearest")
    --font:setFilter('nearest', 'nearest')

    love.graphics.setFont(font)
    
    -- create test sprite
    maid = maid64.newImage("maid64.png")

    -- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
    love.keyboard.setKeyRepeat(true)

    --spawn first enemy
    IncrementEnemyCounter()
    enemyFunctions.SpawnEnemy(wordsTable[enemyCounter])
    IncrementEnemyCounter()
   
end

function love.update(dt)

    if game.pause then
        local pause = 1 -- do nothing
    else
        CheckForEnemyCounterReset()
        --check the player stays withinscreen
        playerFunctions.PlayerDontExitScreen(player)
        --check if we should move the player
        playerFunctions.MovePlayer(player,dt)
        
        enemyFunctions.ManageEnemies(player,dt)

        CheckInputForEnemyWord(enemyFunctions.GetEnemyList(), text)
    
        CheckForCollision()
        
        MoveBullets()

        shells_update(dt)

        explosion_update(dt)
        -- Reset the bulletAdded flag at the beginning of each frame
        bulletAdded = false
end
    end
    
function love.draw()
    
    maid64.start()--starts the maid64 process
    
    --draw images here
    love.graphics.setColor(255/255, 163/255, 0/255)
    love.graphics.rectangle('fill', player.x, player.y, player.width, player.height)
    --can also draw shapes and get mouse position
    love.graphics.circle("fill", maid64.mouse.getX(),  maid64.mouse.getY(), 2)
    -- love.graphics.print(maid64.mouse.getX() .. ',' .. maid64.mouse.getY(), 260,8)
    -- love.graphics.print("Life: " .. player.health, 1,8) -- replace with hearts
    love.graphics.setColor(255/255, 0/255, 77/255)
    -- Define the heart size (width and height)
    local heart_width = 4
    local heart_height = 4

    -- Define the spacing between hearts
    local heart_spacing = 4

    for i = 1, player.health, 1 do
        -- Calculate the x-coordinate for the current heart
        local x = (i - 1) * (heart_width + heart_spacing) + 1

        -- Draw the heart rectangle (adjust for your heart shape)
        love.graphics.rectangle('fill', x, 4, heart_width, heart_height)
    end
    love.graphics.setColor(255/255, 163/255, 0/255)
    
    -- love.graphics.print("Life: " .. player.health, 260,8)
    love.graphics.print('> ' .. textInput, 0, 226)
    love.graphics.setFont(font, 4)
    love.graphics.print('' .. oldText, 0, 226-14-14)
    love.graphics.print('' .. text, 0, 226-14)

    --draw enemies
    enemyFunctions.DrawEnemies()
    explosion_draw()
    DrawBullets()
    shells_draw()
    maid64.finish()--finishes the maid64 process
end

function love.resize(w, h)
    -- this is used to resize the screen correctly
    maid64.resize(w, h)
end

function love.textinput(t)
    textInput = textInput .. t
    play_click_sound()
end

function love.keypressed(key)
    if key == "backspace" then
        play_click_sound()
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(textInput, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            textInput = string.sub(textInput, 1, byteoffset - 1)
        end
    end
    if key == "return" then
        if textInput ~= ":reload" then
            play_shotgun_sound()
        end
        oldText = text
        CheckPlayerCommands()
        text = textInput
        textInput = ""
        --CheckForEnemyWordBool = true
    end
    if key == "." then
        enemyFunctions.SpawnEnemy(wordsTable[enemyCounter])
        IncrementEnemyCounter()
    end
end

function CheckInputForEnemyWord(enemyList, textInput)
    for index, enemy in ipairs(enemyList) do
        if enemy.word == textInput and not bulletAdded then
            print(textInput .. " located on enemey")
            print(enemy.x .. "," .. enemy.y)
            AddBullet(enemy, textInput)
            local bullet  = {target = enemy}
            ejectShell(player, bullet)
            bulletAdded = true
            text = ""
        end
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
    if string.find(textInput, "clear all foes") then
        enemyFunctions.ResetEnemyList()
    end

    if string.find(textInput, "settings:male") then
        print("changing to male....")
        player.female = false
    end

    if string.find(textInput, "settings:female") then
        print("changing to female....")
        player.female = true
    end

    
    if string.find(textInput, ":reload") then
        print("changing to female....")
        play_shotgun_reload_sound()
    end

    
    if string.find(textInput, "settings:pause") then
        print("pause game....")
        if game.pause == true then
            game.pause = false
        else
            game.pause = true
        end
    end
end

--simple movetowards function
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
--smooth movetowards function
function MoveTowardsObject(object, target)
    -- Calculate the difference between object and target positions
    local dx = target.x - object.x
    local dy = target.y - object.y
  
    -- Normalize the difference vector to get the direction vector
    local distance = math.sqrt(dx * dx + dy * dy)
    local directionX = dx / distance
    local directionY = dy / distance
  
    -- Determine the speed based on the desired smoothness
    local speed = object.speed -- Adjust this value to control the movement speed
  
    -- Limit the speed to avoid overshooting
    local maxSpeed = speed * love.timer.getDelta()
    local speedX = math.min(maxSpeed, math.abs(directionX) * speed)
    local speedY = math.min(maxSpeed, math.abs(directionY) * speed)
  
    -- Update the object's position
    object.x = object.x + speedX * directionX
    object.y = object.y + speedY * directionY
  
    -- Check if the object has reached the target
    if math.abs(dx) < 0.1 and math.abs(dy) < 0.1 then
      return false
    end
  
    return true
  end

  function MoveTowardsObjectEasing(object, target, easingFunction)
    local dx = target.x - object.x
    local dy = target.y - object.y
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Normalize the direction vector
    local directionX = dx / distance
    local directionY = dy / distance

    -- Calculate the desired movement distance
    local desiredDistance = object.speed * love.timer.getDelta()

    -- Clamp the desired distance to avoid overshooting
    local actualDistance = math.min(distance, desiredDistance)

    -- Apply the easing function to calculate the actual movement distance
    local easedDistance = easingFunction(actualDistance / distance) * distance

    -- Update the object's position
    object.x = object.x + easedDistance * directionX
    object.y = object.y + easedDistance * directionY

    -- Check if the object has reached the target
    if math.abs(dx) < 0.1 and math.abs(dy) < 0.1 then
        return false
    end

    return true
end

-- Function to extract x and y values from a coordinate string
function ExtractCoordinates(coordinateString)
    local x, y = coordinateString:match("move (%d+),(%d+)")
    
    -- Check if the pattern matched successfully
    if x and y then
        return tonumber(x), tonumber(y)
    else
        -- If the pattern didn't match, handle the error
        print("Error: Invalid coordinate string format. Expected 'move x,y'")
        return nil, nil
    end
end


function love.mousepressed(x, y, button, istouch)
    if button == 1 then -- Versions prior to 0.10.0 use the MouseConstant 'l'
        player.moveToX = maid64.mouse.getX()
        player.moveToY = maid64.mouse.getY()
    end
end


function ReadTxtFileIntoATableEachLetterWillHaveItsOwnLetter(filename)
    -- Open the file in read mode
    local file, err = io.open(filename, "r")

    -- Check for errors
    if not file then
        error("Error opening file: " .. err)
    end

    -- Read lines and sort them into tables by first letter
    for line in file:lines() do
        -- Split the line into words
        local words = {}
        for word in line:gmatch("%S+") do
            table.insert(words, word)
        end

        -- Sort words into tables based on the first letter
        for _, word in ipairs(words) do
            local firstLetter = word:sub(1, 1):lower() -- Assuming case-insensitive sorting

            -- Create a table for the letter if it doesn't exist
            if not tablesByFirstLetter[firstLetter] then
                tablesByFirstLetter[firstLetter] = {}
            end

            -- Insert the word into the corresponding table
            table.insert(tablesByFirstLetter[firstLetter], word)
        end
        wordsTable = words
    end

    -- Close the file
    file:close()

    -- Print the tables (for verification)
end

function ReadTxtFileToATable(filename)
   -- Open the file in read mode
--    local file, err = io.open(filename, "r")
    local file, err = love.filesystem.read(filename)

   -- Check for errors
   if not file then
       error("Error opening file: " .. err)
   end

   -- Read lines and insert them into the table
   for line in file:gmatch("[^\r\n]+") do
       table.insert(wordsTable, line)
   end

   -- Print the lines to the console (for verification)
   for i, line in ipairs(wordsTable) do
       print("Line " .. i .. ": " .. line)
   end
end


function PrintAllWordsStartingWithLetter(startLetter)
    --print("Words starting with '" .. letter .. "': " .. table.concat(tablesByFirstLetter[letter], ", "))
    for index, value in ipairs(tablesByFirstLetter[startLetter]) do
        print(index .. " " .. value)
    end
end

--shuffle table
-- Fisher-Yates shuffle function
function Shuffle(tbl)
    local len = #tbl
    for i = len, 2, -1 do
        math.randomseed(os.time())  -- Seed the random number generator with the current time
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- Advanced Fisher-Yates shuffle function
function AdvancedShuffle(tbl)
    local len = #tbl
    local passes = 3  -- Adjust the number of passes as needed

    for pass = 1, passes do
        for i = len, 2, -1 do
            local j = math.random(i)
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
    end

    return tbl
end

--used to select word in the wordslist
function GetEnemyCounter()
    return enemyCounter
end

function IncrementEnemyCounter()
    enemyCounter = enemyCounter + 1
end

function GetWordFromTable(index)
    return wordsTable[index]
end

--if we are at the end of the words list we want to reset the list and shuffle it 
function CheckForEnemyCounterReset()
    if enemyCounter >= #wordsTable then
        print('reset enemyCounter...')
        enemyCounter = 1
        AdvancedShuffle(wordsTable)
        Shuffle(wordsTable)
        AdvancedShuffle(wordsTable)
        
    end
end

function SetPico8ColorNumb(color)
	local myColor = love.graphics.setColor(0/255, 0/255, 0/255)
	if color == 1 then
		myColor = love.graphics.setColor(255/255, 0/255, 77/255)
	elseif color == 2 then
		myColor = love.graphics.setColor(29/255, 43/255, 83/255	)
	elseif color == 3 then
		myColor = love.graphics.setColor(126/255, 37/255, 83/255)
	elseif color == 4 then
		myColor = love.graphics.setColor(0/255, 135/255, 81/255)
	elseif color == 5 then
		myColor = love.graphics.setColor(171/255, 82/255, 54/255)
	elseif color == 6 then
		myColor = love.graphics.setColor(95/255, 87/255, 79/255)
	elseif color == 7 then
		myColor = love.graphics.setColor(194/255, 195/255, 199/255)
	elseif color == 8 then
		myColor = love.graphics.setColor(255/255, 241/255, 232/255)
	elseif color == 9 then
		myColor = love.graphics.setColor(255/255, 0/255, 77/255)
	elseif color == 10 then
		myColor = love.graphics.setColor(255/255, 163/255, 0/255)
	elseif color == 11 then
		myColor = love.graphics.setColor(255/255, 236/255, 39/255)
	elseif color == 12 then
		myColor = love.graphics.setColor(0/255, 228/255, 54/255)
	elseif color == 13 then
		myColor = love.graphics.setColor(241/255, 173/255, 255/255)
	elseif color == 14 then
		myColor = love.graphics.setColor(131/255, 118/255, 156/255)
	elseif color == 15 then
		myColor = love.graphics.setColor(255/255, 119/255, 168/255)
	elseif color == 16 then
		myColor = love.graphics.setColor(255/255, 204/255, 170/255)
	end

	return myColor
end

function AddBullet(enemy, textInput)
    local bullet = {
        width = 4,
        height = 4,
        x = player.x,
        y = player.y,
        speed = 350,
        target = enemy,
        word = textInput
    }
    table.insert(bulletList, bullet)
    print('adding bullet for enemy word: ' .. enemy.word)
end

function DrawBullets()
    for index, bullet in ipairs(bulletList) do
        SetPico8ColorNumb(4)
        love.graphics.rectangle('fill', bullet.x, bullet.y, bullet.width, bullet.height)
        love.graphics.setColor(241/255, 173/255, 255/255)
    end
end

function MoveBullets()
    for index, bullet in ipairs(bulletList) do
        MoveTowardsObject(bullet, bullet.target)
    end
end

function CheckForCollision()
    for enemyIndex, enemy in ipairs(enemyList) do
        -- local playerTolerance = 4
        -- if math.abs(player.x  - enemy.x) < playerTolerance and math.abs(player.y - enemy.y) < playerTolerance then
        if isColliding(player, enemy) then
            print("player collision lose health")
            if enemy.canHurt then
                enemy.canHurt = false
                player.health = player.health - 1
                enemy.knockback = true
                local randomX = randomInt(1, 320)
                local randomY = randomInt(1, 240)
                enemy.knockBackTarget.x = enemy.knockBackTarget.x + randomX
                enemy.knockBackTarget.y = enemy.knockBackTarget.y + randomY
                enemy.speed = 50
                if player.female then
                    play_female_hurt_sound()
                else
                    play_male_hurt_sound()
                end
                break;
            end
            
        end
        for bulletIndex, bullet in ipairs(bulletList) do
           
            if isColliding(enemy, bullet) then
                -- print(enemy.word)
                -- print(bullet.word)
                if enemy.word == bullet.word then
                    -- Collision detected, remove enemy and bullet
                    table.remove(enemyList, enemyIndex)
                    table.remove(bulletList, bulletIndex)
                    createExplosion(enemy.x, enemy.y)
                    -- Exit the loop to avoid processing further bullets (optional depending on your game logic)
                    break
                end
            end
        end
    end
end

function play_click_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/keyboard_click_00.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_shotgun_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/shotgun_01.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_shotgun_with_reload_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/shotgun_00.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_shell_drop_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/shotgun_shell_drop.waw', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_shotgun_reload_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/shotgun_reload.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_female_hurt_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/female_hurt.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function play_male_hurt_sound()
    -- local sfx_click = love.audio.newSource('sfx/razor_black_widdow_green_click.mp3', 'stream')
    local sfx = love.audio.newSource('sfx/male_hurt.wav', 'static')
    love.audio.play(sfx)
    sfx:play()
end

function randomInt(num1, num2)
    local seed = 0
    for i = 1, 3 do
        seed = seed * 256 + love.timer.getTime() * 1000 % 256
    end
    math.randomseed(seed)
    
    local numb = math.random(num1,num2)

    numb = math.random(num1,num2)
    numb = math.random(num1,num2)
    numb = math.random(num1,num2)
    numb = math.random(num1,num2)
    numb = math.random(num1,num2)
    

    numb = math.ceil(numb)

    return numb
end

-- Function to check if two rectangles are colliding
function isColliding(a, b)
    return a.x < b.x + b.width and     -- Player's left side is left of the enemy's right side
           a.x + a.width > b.x and     -- Player's right side is right of the enemy's left side
           a.y < b.y + b.height and    -- Player's top side is above the enemy's bottom side
           a.y + a.height > b.y        -- Player's bottom side is below the enemy's top side
end

-- Function to create explosion particles at enemy's position
function createExplosion(x, y)
    for i = 1, 4 do                -- Loop to create a 4x4 grid of particles for an 8x8 square
        for j = 1, 4 do
            local angle = math.random() * 2 * math.pi -- Random direction
            local speed = explosionSettings.speed * (0.5 + math.random()) -- Vary speed slightly
            table.insert(particles, {
                x = x + (i - 2) * explosionSettings.particleSize, -- Offset to start in 4x4 grid
                y = y + (j - 2) * explosionSettings.particleSize,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                lifetime = explosionSettings.particleLifetime,
            })
        end
    end
end

function explosion_update(dt)
     -- Update each particle's position and lifetime
     for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.lifetime = particle.lifetime - dt
        if particle.lifetime <= 0 then
            table.remove(particles, i) -- Remove expired particles
        else
            -- Update particle position with velocity
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
        end
    end
end

function explosion_draw()
    -- Draw each particle as a small rectangle
    for _, particle in ipairs(particles) do
        love.graphics.setColor(255/255, 119/255, 168/255)
        
        local alpha = particle.lifetime / explosionSettings.particleLifetime -- Fade out based on lifetime
        -- love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", particle.x, particle.y, explosionSettings.particleSize, explosionSettings.particleSize)
        love.graphics.setColor(241/255, 173/255, 255/255)
    end
    -- love.graphics.setColor(1, 1, 1, 1) -- Reset color to default
end

-- Function to create a shell at the player's position, moving in the opposite direction of the bullet
function ejectShell(player, bullet)
    local angle = calculateAngle(player, bullet.target) + math.pi -- Opposite direction of bullet
    local speed = shellSettings.speed

    table.insert(shells, {
        x = player.x,                          -- Starting position of shell
        y = player.y,
        vx = math.cos(angle) * speed,          -- X velocity in opposite direction
        vy = math.sin(angle) * speed,          -- Y velocity in opposite direction
        rotation = 0,                          -- Initial rotation
        lifetime = shellSettings.lifetime,     -- Shell lifetime
    })
end

-- Function to calculate angle from player to enemy
 function calculateAngle(player, target)
    local dx = target.x - player.x
    local dy = target.y - player.y
    return math.atan2(dy, dx) -- Angle in radians
end

function shells_update(dt)
     -- Update each shell's position, rotation, and lifetime
    for i = #shells, 1, -1 do
        local shell = shells[i]
        shell.lifetime = shell.lifetime - dt
        if shell.lifetime <= 0 then
            table.remove(shells, i) -- Remove expired shells
        else
            -- Update position with gravity and velocity
            shell.vy = shell.vy + shellSettings.gravity * dt -- Apply gravity to Y velocity
            shell.x = shell.x + shell.vx * dt
            shell.y = shell.y + shell.vy * dt
            -- Rotate the shell
            shell.rotation = shell.rotation + shellSettings.rotationSpeed * dt
        end
    end
end

function shells_draw()

    -- Draw each shell as a rectangle, rotated for a spinning effect
    for _, shell in ipairs(shells) do
        local alpha = shell.lifetime / shellSettings.lifetime -- Fade out based on lifetime
        love.graphics.setColor(1, 1, 0.8, alpha) -- Yellowish shell color with fading

        love.graphics.push()
        love.graphics.translate(shell.x, shell.y)                      -- Move to shell position
        love.graphics.rotate(shell.rotation)                           -- Apply rotation
        love.graphics.rectangle("fill", -shellSettings.width / 2,      -- Centered rectangle
                                -shellSettings.height / 2, 
                                shellSettings.width, shellSettings.height)
        love.graphics.pop()
    end
    love.graphics.setColor(241/255, 173/255, 255/255)
end