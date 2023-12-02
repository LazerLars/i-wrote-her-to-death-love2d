--ENEMY SETTINGS
local enemyList = {}
local enemySpawnTimer = 5
local prevSpawnTime = 0
local spawnTimeDecliner = 5
local prevDecilineTime = 0
--------------------------

--Adding enemies, used in the upadte function
function ManageEnemies(player,dt)
    local currentTime = love.timer.getTime()
        local updatedSpawnTime = false
      
        -- Spawn enemy every nth second
        if currentTime - prevSpawnTime >= enemySpawnTimer then
            print(enemySpawnTimer .. " has passed. Spawn enemy")
            prevSpawnTime = currentTime
            SpawnEnemy(GetWordFromTable(GetEnemyCounter()))
            IncrementEnemyCounter()
            updatedSpawnTime = true
        end
      
        -- Decrement spawn time if necessary
        if enemySpawnTimer > 0.5 and not updatedSpawnTime then
            if currentTime - prevDecilineTime >= spawnTimeDecliner then
                prevDecilineTime = currentTime
                enemySpawnTimer = enemySpawnTimer - 0.5
                print('Decline spawn time with 0.5, new spawn time: ' .. enemySpawnTimer)
            end
        end
      
        -- Move enemies towards the player
        for index, enemyObj in ipairs(enemyList) do
          --MoveTowards(enemyObj, player.x, player.y, dt)
          MoveTowardsObject(enemyObj, player)
        end
    end

function SpawnEnemy(word)
    local enemy = {
        x = math.random(1,320),
        y = math.random(1,240),
        health = 1,
        word = word,
        speed = math.random(10,30)
    }
    table.insert(enemyList, enemy)
    --return enemy
end


function DrawEnemies()
    for index, value in ipairs(enemyList) do
        love.graphics.setColor(255/255, 119/255, 168/255)

        --get width of word to center it later above the player
        local enemySize = 8
        local wordWidth = font:getWidth(value.word)  -- Assuming you have a 'font' variable set to your desired font

        -- Center the square horizontally and draw it
        love.graphics.rectangle('fill', value.x - enemySize / 2, value.y + 4, enemySize, enemySize)

        love.graphics.setColor(241/255, 173/255, 255/255)

        -- Center the word horizontally above the square
        love.graphics.print(value.word, value.x - wordWidth / 2, value.y - enemySize - 2)  -- Adjust the vertical offset as needed
    end
end

function ResetEnemyList()
    enemyList = {}
end

function GetEnemyList()
    return enemyList
end

    return {
        ManageEnemies = ManageEnemies,
        SpawnEnemy = SpawnEnemy,
        DrawEnemies = DrawEnemies,
        ResetEnemyList = ResetEnemyList,
        GetEnemyList = GetEnemyList
    }