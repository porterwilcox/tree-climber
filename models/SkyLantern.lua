local physics = require("physics")
physics.start()

local tableHelpers = require( "helpers.tableHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local SkyLantern = {}
SkyLantern.__index = SkyLantern

local id = 1

local skyLanternRed = {
    type = "image",
    filename = "assets/images/sky-lantern-red.png"
}
local skyLanternYellow = {
    type = "image",
    filename = "assets/images/sky-lantern-yellow.png"
}
local skyLanternBlue = {
    type = "image",
    filename = "assets/images/sky-lantern-blue.png"
}

function SkyLantern:new( x, y )
    local skyLantern = display.newCircle( gs:getState("gameGroup"), x, y, math.random(10, 20) )
    skyLantern.alpha = 0.7
    physics.addBody(skyLantern, "static", {radius = 120, isSensor = true})
    
    skyLantern.id = id
    skyLantern.name = "skyLantern"

    skyLantern.origin = { x = x, y = y }
    skyLantern.destination = { }
    skyLantern.transitionDuration = nil
    skyLantern.transitionStart = nil
    skyLantern.transition = nil
    skyLantern.falling = false

    local color = math.random(1, 10)
    if color <= 6 then 
        skyLantern.fill = skyLanternRed
    elseif color <= 9 then
        skyLantern.fill = skyLanternYellow
    else
        skyLantern.fill = skyLanternBlue
    end

    id = id + 1
    local self = setmetatable({ _obj = skyLantern }, SkyLantern)
    return self
end

function SkyLantern:Move(unitsToMove, ms, fractionalMovement)
    local obj = self._obj
    if obj == nil or obj.deleted then return end

    if obj.transition == nil then return end

    transition.cancel(obj.transition)

    if fractionalMovement then
        if obj.falling then
            unitsToMove = unitsToMove * .5  -- Fall faster if already falling
        else
            unitsToMove = unitsToMove * .25  -- Slow down if not falling
        end
    end

    transition.to(obj, {time = ms, y = obj.y + unitsToMove, transition = easing.outSine })
    
    if obj.falling then
        timer.performWithDelay( ms, function() 
            if obj.deleted then return end
            local distanceToFall = display.contentHeight + 100 - obj.y
            local fallTime = distanceToFall * 10
            obj.transition = transition.to(obj, { time = fallTime, y = display.contentHeight + 100, onComplete = function()
                local character = gs:getState("character")
                if (character._obj.swingable == swingable) then
                    character:release()
                end
                self:Delete()
            end })
        end, 1)
    else
        timer.performWithDelay(ms, function() 
            if obj.falling then return end
            local time = obj.transitionDuration - (system.getTimer() - obj.transitionStart) + ms
            obj.transitionStart = system.getTimer()
            obj.transition = transition.to(obj, {time = time, x = obj.destination.x, y = obj.destination.y})
        end, 1) -- Reset the upward transition
    end
end

function SkyLantern:Delete()
    local obj = self._obj
    if obj.deleted then return end

    local character = gs:getState("character")._obj
    if character ~= nil and character.swingable ~= nil and character.swingable.id == obj.id then 
        return
    end

    tableHelpers.remove( gs:getState("skyLanterns"), function(r) return r._obj.id == obj.id end )
    timer.cancel(obj.deletionTimerId)
    obj:removeSelf() 
    obj.deleted = true
end

function SkyLantern:isOffScreen()
    local obj = self._obj
    local edgePadding = 50

    -- Check off top
    if (obj.y + obj.height * 0.5) < 0 - edgePadding then
        return true
    end

    -- Check off bottom
    if (obj.y - obj.height * 0.5) > display.contentHeight + edgePadding then
        return true
    end

    return false
end

function SkyLantern.initSkyLanterns()
    local skyLanterns = gs:getState("skyLanterns")
    local skyLanternsNotFallingCount = #tableHelpers.filter(skyLanterns, function(skyLantern) return not skyLantern._obj.falling end)
    if skyLanternsNotFallingCount > 4 then return end

    local randomNumStart = math.random(0, 1)
    local numSkyLanterns = math.random(1, 2)
    for i = 1, numSkyLanterns do
        local x
        if (randomNumStart % 2) == 0 then x = -10 else x = display.contentWidth + 10 end
        randomNumStart = randomNumStart + 1
        local y = math.random(0, display.contentHeight * .5)
        local skyLantern = SkyLantern:new(x, y)
        gs:addTableMember("skyLanterns", skyLantern)

        local obj = skyLantern._obj
        
        -- fly in lines angled up, between N and NW, and NE
        local angle
        if (x < display.contentCenterX) then
            obj.rotation = 10;
            obj.direction = "right"
            angle = math.random(-30, -10)
        else
            obj.rotation = -10;
            obj.direction = "left"
            angle = math.random(-170, -150)
        end
        local radians = math.rad(angle)
        obj.destination.x = math.cos(radians) * display.contentWidth
        obj.destination.y = math.sin(radians) * display.contentWidth
        obj.transitionDuration = (13000 * 20) / (obj.width / 2)
        obj.transitionStart = system.getTimer()
        obj.transition = transition.to(obj, {time = obj.transitionDuration, x = obj.destination.x, y = obj.destination.y})

        --remove when skyLantern is off screen
        obj.deletionTimerId = timer.performWithDelay(5000, function() 
            local character = gs:getState("character")._obj
            if skyLantern:isOffScreen() then
                skyLantern:Delete()
            end
        end, 0)
    end
end

function SkyLantern.startSkyLanternTimerGenerator()
    local skyLanternTimer = gs:getState("skyLanternGeneratorTimerId")
    if skyLanternTimer ~= nil then return end

    SkyLantern.initSkyLanterns()
    local skyLanternGeneratorTimerId = timer.performWithDelay( 2000, function()
        SkyLantern.initSkyLanterns()
    end, 0)
    gs:setState("skyLanternGeneratorTimerId", skyLanternGeneratorTimerId)
end

function SkyLantern.clearSkyLanternTimerGenerator()
    local skyLanternTimer = gs:getState("skyLanternGeneratorTimerId")
	if skyLanternTimer ~= nil then 
		timer.cancel(skyLanternTimer) 
		gs:setState("skyLanternGeneratorTimerId", nil)
	end
end

return SkyLantern