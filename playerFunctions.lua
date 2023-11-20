-- playerFunctions.lua

local tolerance = 0.01
local screenWidth = 320
local screenHeight = 240

function PlayerDontExitScreen(player)
    if player.x > screenWidth then
        player.x = screenWidth - 2
        player.moveToX = player.x
    elseif player.x < 0 then
        player.x = 2
        player.moveToX = player.x
    end
    if player.y > screenHeight then
        player.y = screenHeight - 2
        player.moveToY = player.y
    elseif player.y < 0 then
        player.y = 2
        player.moveToY = player.y
    end
end

function MovePlayer(player, dt)
    if player.moveToX and player.moveToY then
        if math.abs(player.moveToX - player.x) > tolerance or math.abs(player.moveToY - player.y) > tolerance then
            MoveTowards(player, player.moveToX, player.moveToY, dt)
            --print('we are moving')
            --print('x: from ' .. math.floor(player.x) .. ' to ' .. math.floor(player.moveToX))
            --print('y: from ' .. math.floor(player.y) .. ' to ' .. math.floor(player.moveToY))
        end
    else
        print('Error: moveToX or moveToY is nil')
    end
end


return {
    PlayerDontExitScreen = PlayerDontExitScreen,
    MovePlayer = MovePlayer
}
