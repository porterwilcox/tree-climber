local physics = require("physics")
physics.start()

local tableHelpers = require( "helpers.tableHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local SkyLantern = {}
SkyLantern.__index = SkyLantern

local id = 1

local skyLanternFlyingLeftPaint = {
    type = "image",
    filename = "assets/images/sky-lantern-flying-left.png"
}
local skyLanternFlyingRightPaint = {
    type = "image",
    filename = "assets/images/sky-lantern-flying-right.png"
}

function SkyLantern:new( x, y )
    local skyLantern = display.newCircle( gs:getState("gameGroup"), x, y, math.random(10, 20) )
    skyLantern.alpha = 0.8
    physics.addBody(skyLantern, "static", {radius = 120, isSensor = true})
    
    skyLantern.id = id
    skyLantern.name = "skyLantern"

    skyLantern.origin = { x = x, y = y }
    skyLantern.destination = { }
    skyLantern.transitionDuration = nil
    skyLantern.transitionStart = nil
    skyLantern.transition = nil
    skyLantern.falling = false

    id = id + 1
    local self = setmetatable({ _obj = skyLantern }, SkyLantern)
    return self
end

function SkyLantern:Move(unitsToMove, ms)
    local skyLantern = self._obj

    if skyLantern.transition == nil then print('transition is nil') return end
    
    -- Pause the transition
    transition.pause(skyLantern.transition)
    
    -- Resume the transition after the delay
    timer.performWithDelay(ms, function() transition.resume(skyLantern.transition) end, 1)
end

function SkyLantern:Delete()
    local obj = self._obj
    if obj.deleted then return end

    tableHelpers.remove( gs:getState("skyLanterns"), function(r) return r._obj.id == obj.id end )
    obj:removeSelf() 
    obj.deleted = true
end

function SkyLantern.initSkyLanterns()
    local numSkyLanterns = math.random(1, 2)
    for i = 1, numSkyLanterns do
        local margin = 100
        local x = math.random(0 - margin, display.contentWidth + margin)
        local y = math.random(display.contentHeight - margin, display.contentHeight)
        local skyLantern = SkyLantern:new(x, y)
        gs:addTableMember("skyLanterns", skyLantern)

        local obj = skyLantern._obj
        
        -- fly in lines angled up, between N and NW, and NE
        local angle
        if (x < display.contentCenterX) then
            skyLantern._obj.fill = skyLanternFlyingRightPaint
            angle = math.random(-75, -35)
        else
            skyLantern._obj.fill = skyLanternFlyingLeftPaint
            angle = math.random(-165, -125)
        end

        local radians = math.rad(angle)
        obj.destination.x = math.cos(radians) * display.contentWidth
        obj.destination.y = math.sin(radians) * display.contentWidth
        obj.transitionDuration = (13000 * 20) / (obj.width / 2)
        obj.transitionStart = system.getTimer()
        obj.transition = transition.to(skyLantern._obj, {time = obj.transitionDuration, x = obj.destination.x, y = obj.destination.y})

        --remove when transition is complete
        timer.performWithDelay(obj.transitionDuration, function() skyLantern:Delete() end, 1)
    end
end

function SkyLantern.startSkyLanternTimerGenerator()
    local skyLanternTimer = gs:getState("skyLanternGeneratorTimerId")
    if skyLanternTimer ~= nil then return end

    SkyLantern.initSkyLanterns()
    SkyLantern.initSkyLanterns()
    SkyLantern.initSkyLanterns()
    local skyLanternGeneratorTimerId = timer.performWithDelay( 2750, function()
        SkyLantern.initSkyLanterns()
    end, 0)
    gs:setState("skyLanternGeneratorTimerId", skyLanternGeneratorTimerId)
end

return SkyLantern