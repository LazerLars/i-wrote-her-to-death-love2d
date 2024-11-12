--ENEMY SETTINGS
enemyList = {}
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
                enemySpawnTimer = enemySpawnTimer - 0.2
                print('Decline spawn time with 0.5, new spawn time: ' .. enemySpawnTimer)
            end
        end
      
        -- Move enemies towards the player
        for index, enemyObj in ipairs(enemyList) do
          --MoveTowards(enemyObj, player.x, player.y, dt)
            if enemyObj.knockback == false then
                MoveTowardsObject(enemyObj, player)
            else 
                -- enemyObj.speed = enemyObj.speed + 2
                
                MoveTowardsObject(enemyObj, enemyObj.knockBackTarget )
                if math.abs(enemyObj.x - enemyObj.knockBackTarget.x) < 4 and math.abs(enemyObj.y - enemyObj.knockBackTarget.y) then
                    enemyObj.knockback = false
                    enemyObj.canHurt = true
                    enemyObj.speed = enemyObj.orignalSpeed
                    -- enemyObj.speed = enemyObj.orignalSpeed
                end
            end
            
        end
    end

function SpawnEnemy(word)
    local enemy = {
        width = 8,
        height = 8,
        x = randomInt(1,320),
        y = randomInt(1,240),
        health = 1,
        word = word,
        speed = randomInt(10,15),
        knockBackTarget = {
            x=1, -- placeholder for knockback target
            y=1}, -- placeholder for knockback target
        knockback = false,
        orignalSpeed = 1, -- used to reset speed after a knockback to orignal
        canHurt = true -- used so the player only take damage from a enemy once
    }
    enemy.orignalSpeed = enemy.speed -- used to reset speed after a knockback to orignal
    table.insert(enemyList, enemy)
    --return enemy
end


function DrawEnemies()
    for index, enemyObj in ipairs(enemyList) do
        love.graphics.setColor(255/255, 119/255, 168/255)

        --get width of word to center it later above the player
        local enemySize = 8
        local wordWidth = font:getWidth(enemyObj.word)  -- Assuming you have a 'font' variable set to your desired font

        -- love.graphics.rectangle('fill', enemyObj.x - enemySize / 2, enemyObj.y + 4, enemySize, enemySize)
        love.graphics.rectangle('fill', enemyObj.x, enemyObj.y, enemyObj.width, enemyObj.height)
        
        love.graphics.setColor(241/255, 173/255, 255/255)

        -- Center the word horizontally above the square
        love.graphics.print(enemyObj.word, enemyObj.x - wordWidth / 2, enemyObj.y - enemySize - 2)  -- Adjust the vertical offset as needed
    end
end

function ResetEnemyList()
    enemyList = {}
end

function GetEnemyList()
    return enemyList
end

function RemoveEnemy(index)
    table.remove(enemyList, index)
end

    return {
        ManageEnemies = ManageEnemies,
        SpawnEnemy = SpawnEnemy,
        DrawEnemies = DrawEnemies,
        ResetEnemyList = ResetEnemyList,
        GetEnemyList = GetEnemyList
    }