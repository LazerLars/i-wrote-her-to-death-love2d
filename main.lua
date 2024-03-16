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
    health = 1,
    x = screenWidth /2,
    y = screenHight/2,
    speed = 50,
    moveToX = screenWidth /2,
    moveToY = screenHight/2,
    move = false;
}

local tablesByFirstLetter = {}
local wordsTable = {}
local filename = "texts/10kMostCommonEngWords.txt"
local enemyCounter = 0

local bulletList = {}
local bulletAdded = false 

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
    
    CheckForEnemyCounterReset()
    --check the player stays withinscreen
    playerFunctions.PlayerDontExitScreen(player)
    --check if we should move the player
    playerFunctions.MovePlayer(player,dt)
    
    enemyFunctions.ManageEnemies(player,dt)

    CheckInputForEnemyWord(enemyFunctions.GetEnemyList(), text)
    --CheckForEnemyWordBool = false
    -- MoveTowards(enemy, player.x, player.y, dt)
    
   CheckForCollision()
    
    MoveBullets()
    -- Reset the bulletAdded flag at the beginning of each frame
    bulletAdded = false
end
function love.draw()
    
    maid64.start()--starts the maid64 process
    
    --draw images here
    love.graphics.setColor(255/255, 163/255, 0/255)
    love.graphics.rectangle('fill', player.x, player.y, 4,4)
    --can also draw shapes and get mouse position
    love.graphics.circle("fill", maid64.mouse.getX(),  maid64.mouse.getY(), 2)
    love.graphics.print(maid64.mouse.getX() .. ',' .. maid64.mouse.getY(), 260,8)
    love.graphics.print('> ' .. textInput, 0, 226)
    love.graphics.setFont(font, 4)
    love.graphics.print('' .. oldText, 0, 226-14-14)
    love.graphics.print('' .. text, 0, 226-14)

    --draw enemies
    enemyFunctions.DrawEnemies()
    DrawBullets()
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
            AddBullet(enemy)
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
   local file, err = io.open(filename, "r")

   -- Check for errors
   if not file then
       error("Error opening file: " .. err)
   end

   -- Read lines and insert them into the table
   for line in file:lines() do
       table.insert(wordsTable, line)
   end

   -- Close the file
   file:close()

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

function AddBullet(enemy)
    local bullet = {
        x = player.x,
        y = player.y,
        speed = 350,
        target = enemy
    }
    table.insert(bulletList, bullet)
    print('adding bullet for enemy word: ' .. enemy.word)
end

function DrawBullets()
    for index, bullet in ipairs(bulletList) do
        SetPico8ColorNumb(4)
        love.graphics.rectangle('fill', bullet.x, bullet.y, 4,4)
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
        for bulletIndex, bullet in ipairs(bulletList) do
            -- Calculate the tolerance for collision
            local tolerance = 4 -- Half the width of the bullet
            -- Check if enemy and bullet positions are colliding with tolerance
            if math.abs(enemy.x - bullet.x) < tolerance and math.abs(enemy.y - bullet.y) < tolerance then
                -- Collision detected, remove enemy and bullet
                table.remove(enemyList, enemyIndex)
                table.remove(bulletList, bulletIndex)
                -- Exit the loop to avoid processing further bullets (optional depending on your game logic)
                break
            end
        end
    end
end
