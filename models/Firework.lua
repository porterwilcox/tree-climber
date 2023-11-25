local physics = require("physics")
physics.start()

local tableHelpers = require( "helpers.tableHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local Firework = {}
Firework.__index = Firework

local id = 1

local fireworksImages = {
    {
        {
            type = "image",
            filename = "assets/images/fireworks/firework-blue-start.png"
        },
        {
            type = "image",
            filename = "assets/images/fireworks/firework-blue-middle.png"
        },
        {
            type = "image",
            filename = "assets/images/fireworks/firework-blue-end.png"
        }
    },
    {
        {
            type = "image",
            filename = "assets/images/fireworks/firework-red-start.png"
        },
        {
            type = "image",
            filename = "assets/images/fireworks/firework-red-middle.png"
        },
        {
            type = "image",
            filename = "assets/images/fireworks/firework-red-end.png"
        }
    }
}
local fireworkBlueStart = {
    type = "image",
    filename = "assets/images/fireworks/firework-blue-start.png"
}
local fireworkBlueMiddle = {
    type = "image",
    filename = "assets/images/fireworks/firework-blue-middle.png"
}
local fireworkBlueEnd = {
    type = "image",
    filename = "assets/images/fireworks/firework-blue-end.png"
}

local fireworkRedStart = {
    type = "image",
    filename = "assets/images/fireworks/firework-red-start.png"
}
local fireworkRedMiddle = {
    type = "image",
    filename = "assets/images/fireworks/firework-red-middle.png"
}
local fireworkRedEnd = {
    type = "image",
    filename = "assets/images/fireworks/firework-red-end.png"
}

local highestFirework = nil

function Firework:new( x, y )
    local firework = display.newCircle( gs:getState("gameGroup"), x, y, 15 )
    firework.alpha = 0.7
    physics.addBody(firework, "static", {radius = 120, isSensor = true})
    
    firework.id = id
    firework.name = "firework"
    id = id + 1
    local self = setmetatable({ _obj = firework }, Firework)
    self:Animate()
    return self
end

function Firework:Move(unitsToMove, ms)
    local firework = self._obj

    transition.to(firework, {time = ms, y = firework.y + unitsToMove, transition = easing.outSine })
end

function Firework:Animate()
    local firework = self._obj

    -- Function to create strobing effect
    local function strobeEffect(target, duration)
        local function strobe()
            if target and target.alpha then
                -- Toggle alpha between 0.5 and 1 for strobing effect
                target.alpha = target.alpha == 1 and 0.75 or 1
            end
        end
        -- Repeat the strobe effect for the duration of the animation
        return timer.performWithDelay(math.random(80, 150), strobe, duration / 50)
    end

    local color = math.random(1, 2)

    -- Start animation with strobing
    firework.fill = fireworksImages[color][1]
    local strobeTimer1 = strobeEffect(firework, 1500)
    transition.to(firework, {
        time = 1000,
        xScale = 1,
        yScale = 1,
        onComplete = function()
            if strobeTimer1 then timer.cancel(strobeTimer1) end
            -- Middle animation with strobing
            firework.fill = fireworksImages[color][2]
            firework.rotation = 0
            local strobeTimer2 = strobeEffect(firework, 2500)
            transition.to(firework, {
                time = 3500,
                xScale = 3.0,
                yScale = 3.0,
                rotation = math.random(-180, 180),
                onComplete = function()
                    if strobeTimer2 then timer.cancel(strobeTimer2) end
                    -- End animation
                    firework.fill = fireworksImages[color][3]
                    firework.alpha = .7
                    firework.xScale = 1.5
                    firework.yScale = 1.5
                    transition.to(firework, {
                        time = 1500,
                        xScale = 0.1,
                        yScale = 0.1,
                        alpha = 0,  -- fade out
                        rotation = math.random(-180, 180),
                        onComplete = function()
                            local character = gs:getState("character")
                            if (character._obj.swingable == firework) then
                                character:release()
                            end
                            self:Delete()
                        end
                    })
                end
            })
        end
    })
end

function Firework:Delete()
    local obj = self._obj
    if obj.deleted then return end

    local character = gs:getState("character")._obj
    if character ~= nil and character.swingable ~= nil and character.swingable.id == obj.id then 
        return
    end

    tableHelpers.remove( gs:getState("fireworks"), function(r) return r._obj.id == obj.id end )
    obj:removeSelf() 
    obj.deleted = true
end

function initFirework()
    local x = math.random(50, 310)
    local y = highestFirework ~= nil and not highestFirework.deleted and highestFirework.y - math.random(175, 300) or display.contentCenterY
    local firework = Firework:new( x, y )
    table.insert(gs:getState("fireworks"), firework)
    highestFirework = firework._obj
end

function Firework.startFireworkTimerGenerator()
    local fireworkTimer = gs:getState("fireworkGeneratorTimerId")
    if fireworkTimer ~= nil then return end

    initFirework()
    local fireworkGeneratorTimerId = timer.performWithDelay( 1000, function()
        timer.performWithDelay( math.random(1, 1000), function() initFirework() end, 1 )
    end, 0)
    gs:setState("fireworkGeneratorTimerId", fireworkGeneratorTimerId)
end

function Firework.clearFireworkTimerGenerator()
    highestFirework = nil
    local fireworkTimer = gs:getState("fireworkGeneratorTimerId")
	if fireworkTimer ~= nil then 
		timer.cancel(fireworkTimer) 
		gs:setState("fireworkGeneratorTimerId", nil)
	end
end

return Firework