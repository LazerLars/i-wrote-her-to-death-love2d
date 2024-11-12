-- Load the tween library
local Tween = require("tween")

-- Define the two target points
local targetA = { x = 100, y = 100 }        -- Start position
local targetB = { x = 600, y = 400 }        -- End position

-- Set up the square's initial properties
local square = { x = targetA.x, y = targetA.y, size = 50 }
local duration = 1                          -- Duration of each tween (in seconds)
local direction = 1                         -- Movement direction (1 = toward targetB, -1 = toward targetA)
local elapsedTime = 0                       -- Track elapsed time

-- Full list of easing functions to cycle through
local easingFunctions = {
    "linear",
    "inQuad", "outQuad", "inOutQuad", "outInQuad",
    "inCubic", "outCubic", "inOutCubic", "outInCubic",
    "inQuart", "outQuart", "inOutQuart", "outInQuart",
    "inQuint", "outQuint", "inOutQuint", "outInQuint",
    "inSine", "outSine", "inOutSine", "outInSine",
    "inExpo", "outExpo", "inOutExpo", "outInExpo",
    "inCirc", "outCirc", "inOutCirc", "outInCirc",
    "inElastic", "outElastic", "inOutElastic", "outInElastic",
    "inBack", "outBack", "inOutBack", "outInBack",
    "inBounce", "outBounce", "inOutBounce", "outInBounce"
}
local easingIndex = 1                      -- Index of the current easing function
local tween                                -- Tween object for managing animation

-- Function to initialize or reset the tween
local function resetTween()
    -- Determine the target based on the current direction
    local target = direction == 1 and targetB or targetA -- if dir == 1 then targetB else targetA
    
    -- Create a new tween to move the square between targetA and targetB
    tween = Tween.new(duration, square, { x = target.x, y = target.y }, Tween.easing[easingFunctions[easingIndex]])
end
resetTween()  -- Initialize the first tween

function love.update(dt)
    elapsedTime = elapsedTime + dt       -- Update elapsed time
    
    -- Update the tween with delta time and check if it has completed
    local complete = tween:update(dt)
    
    -- Reverse direction and reset the tween if it has reached the target
    if complete then
        direction = -direction           -- Switch direction
        resetTween()                     -- Reset tween for new direction
    end
end

function love.draw()
    -- Draw the square at its current position
    love.graphics.rectangle("fill", square.x, square.y, square.size, square.size)
    
    -- Display the name of the current easing function at the top-left corner
    love.graphics.print("Current easing: " .. easingFunctions[easingIndex], 10, 10)
end

function love.keypressed(key)
    -- Cycle to the next easing function with the right arrow key
    if key == "right" then
        easingIndex = easingIndex % #easingFunctions + 1   -- Increment index, looping back to 1 if necessary
        resetTween()                                       -- Reset the tween to use the new easing function

    -- Cycle to the previous easing function with the left arrow key
    elseif key == "left" then
        easingIndex = (easingIndex - 2) % #easingFunctions + 1  -- Decrement index, looping to last if necessary
        resetTween()                                            -- Reset tween with new easing function
    end

    if key == "up" then
        targetB.x = targetB.x + 25
        targetB.y = targetB.y + 25
    end
    if key == "down" then
        targetB.x = targetB.x - 25
        targetB.y = targetB.y - 25
    end
end
