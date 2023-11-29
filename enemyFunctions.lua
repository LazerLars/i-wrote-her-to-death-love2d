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
            SpawnEnemy()
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

function SpawnEnemy()
    local enemy = {
        x = math.random(1,320),
        y = math.random(1,240),
        health = 1,
        word = 'boom' .. math.random(1,200),
        speed = math.random(10,30)
    }
    table.insert(enemyList, enemy)
    --return enemy
end

function DrawEnemies()
    for index, value in ipairs(enemyList) do
        love.graphics.setColor(255/255, 119/255, 168/255)
        love.graphics.rectangle('fill', value.x, value.y, 6,6)
        love.graphics.setColor(241/255, 173/255, 255/255)
        love.graphics.print(value.word, value.x - 10, value.y -10)
    end
end

    return {
        ManageEnemies = ManageEnemies,
        SpawnEnemy = SpawnEnemy,
        DrawEnemies = DrawEnemies
    }