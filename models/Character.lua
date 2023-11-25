local phyics = require("physics")
physics.start()

local tableHelpers = require( "helpers.tableHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local Building = require("models.Building")
local SkyLantern = require("models.SkyLantern")
local Firework = require("models.Firework")

local Character = {}
Character.__index = Character

local id = 1

local tuckedPaint = {
    type = "image",
    filename = "assets/images/ninja-tucked.png"
}
local swingingPaint = {
    type = "image",
    filename = "assets/images/ninja-swinging.png"
}
local charPhysMod = 2

local skyLanternSwingCount

local function onCollision( event )
    local character = event.target

    local isAnchor = event.other.name == "anchor"
    local isSkyLantern = event.other.name == "skyLantern"
    local isFirework = event.other.name == "firework"
    
    if ( isAnchor or isSkyLantern or isFirework) then
        local swingable = event.other
        
        if (event.phase == "began") then
            if isSkyLantern then
                if (swingable.x < 0 and swingable.direction == "left") or (swingable.x > display.contentWidth and swingable.direction == "right") then
                    return
                end
            end

            local index = table.indexOf( character.swingables, swingable )
            if (index ~= nil) then table.remove(character.swingables, index) end
            table.insert(character.swingables, swingable)
            
            if (not character.swinging) then 
                if (isAnchor) then
                    swingable.alpha = 0.5 
                elseif (isSkyLantern) then
                    swingable.alpha = 1
                end
            end
        elseif (event.phase == "ended") then
            local index = table.indexOf( character.swingables, swingable )
            if (index ~= nil) then table.remove(character.swingables, index) end


            if (isAnchor) then
                swingable.alpha = 0
            elseif (isSkyLantern) then
                swingable.alpha = 0.7
            end

            if (character.swingable == swingable) then  
                if (isAnchor) then
                    swingable.alpha = 0.5
                elseif (isSkyLantern) then
                    swingable.alpha = 1
                end
            end
        end
    end
end

local function updateRopePosition(character)
    if character.x and character.swingable and character.swingable.x then

        if character.rope then character.rope:removeSelf() end

        character.rope = display.newLine(gs:getState("gameGroup"), character.x, character.y, character.swingable.x, character.swingable.y)
        character.rope.strokeWidth = 3
        character.rope:setStrokeColor( 1, 1, 1, 0.5 )
    end
end

local function onEnterFrame()
    local character = gs:getState("character")._obj
    if character == nil then return end
    updateRopePosition(character)
end

function Character:new( group )
    skyLanternSwingCount = 0

    local character = display.newCircle( group, display.contentCenterX, display.contentHeight + 100, 10 * charPhysMod )
    character.fill = tuckedPaint
    physics.addBody(character, "dynamic", {radius = character.width/2, bounce = 0.2, density = 1 / charPhysMod})
    character.gravityScale = 1
    character:addEventListener("collision", onCollision)
    character:applyLinearImpulse(0, -6 * charPhysMod, character.x, character.y)
    character.angularVelocity = -200 -- make the character do backflips
    
    character.id = id
    character.name = "character"
    character.swingables = {}
    character.swinging = false
    id = id + 1
    local self = setmetatable({ _obj = character }, Character)
    return self
end

function Character:swing()
    local character = self._obj

    local swingable = character.swingables[#character.swingables]
    if (swingable == nil or swingable.x == nil) then
        tableHelpers.remove( character.swingables, function(r) return r.id == swingable.id end )
        return
    end

    -- transition.cancelAll()
    local isAnchor = swingable.name == "anchor" -- building anchors
    local isSkyLantern = swingable.name == "skyLantern"

    if isSkyLantern then 
        skyLanternSwingCount = skyLanternSwingCount + 1 
        if skyLanternSwingCount == 10 then
            SkyLantern.clearSkyLanternTimerGenerator()
            Firework.startFireworkTimerGenerator()
        end
    end

    character.fill = swingingPaint
    character.swingable = swingable
    character.swinging = true

    local vx, vy = character:getLinearVelocity()

    local dx = character.x - swingable.x
    local dy = character.y - swingable.y

    local crossProduct = vx * dy - vy * dx

    local motorSpeed = 500 * charPhysMod
    if crossProduct > 0 then -- Counterclockwise
        motorSpeed = motorSpeed * 1 
        character.xScale = 1
    elseif crossProduct < 0 then -- Clockwise
        motorSpeed = motorSpeed * -1 
        character.xScale = -1
    end

    -- if the character is not spinning fast enough, speed it up
    if (math.abs(character.angularVelocity) < 200) then
        if isAchor then
            character.angularVelocity = 500
        elseif isSkyLantern then
            character.angularVelocity = 10000
        end
    end

    -- rotate the top of the character to the swingable
    local angle = math.atan2(character.y - swingable.y, character.x - swingable.x) * 180 / math.pi
    character.rotation = angle - 90

    -- get the distance between the character and the swingable
    local distance = math.sqrt((character.x - swingable.x) ^ 2 + (character.y - swingable.y) ^ 2)
    while (distance < 45) do
        local x = swingable.x + (character.x - swingable.x) * 2
        local y = swingable.y + (character.y - swingable.y) * 2
        character.x, character.y = x, y
        distance = math.sqrt((character.x - swingable.x) ^ 2 + (character.y - swingable.y) ^ 2)
    end

    local pivotJoint = physics.newJoint("pivot", character, swingable, swingable.x, swingable.y)
    pivotJoint.isMotorEnabled = true
    pivotJoint.motorSpeed = motorSpeed
    pivotJoint.maxMotorTorque = 10 * charPhysMod
    character.pivotJoint = pivotJoint

    local targetY = display.contentHeight - 225
    local distance = targetY - swingable.y
    if (distance > 0) then
        distance = distance + math.random(-50, 100)
    end
    local updateScreenPosition = math.abs(distance) > 100
    if updateScreenPosition then
        local buildings = gs:getState("buildings")
        for i = 1, #buildings do
            buildings[i]:Move(distance, 500)
        end
        local skyLanterns = gs:getState("skyLanterns")
        for i = 1, #skyLanterns do
            skyLanterns[i]:Move(distance/2, 500, false)
        end
        local fireworks = gs:getState("fireworks")
        for i = 1, #fireworks do
            fireworks[i]:Move(distance, 500)
        end
    end

    if isSkyLantern then
        local delay = 1
        if updateScreenPosition then delay = 500 end
        timer.performWithDelay( delay, function()
            tableHelpers.remove( character.swingables, function(r) return r.id == swingable.id end )
            swingable.falling = true
            swingable.rotation = 0;
            transition.cancel(swingable.transition)
            local distanceToFall = display.contentHeight + 100 - swingable.y
            local fallTime = distanceToFall * 10
            swingable.transition = transition.to(swingable, { time = fallTime, y = display.contentHeight + 100, onComplete = function()
                if (character.swingable == swingable) then
                    self:release()
                end
            end })
        end, 1 )
    end

    updateRopePosition(character)
    Runtime:addEventListener("enterFrame", onEnterFrame)
end

function Character:setLinearDamping(x)
    local character = self._obj
    if (not character.swinging) then return end

    local distance = display.contentCenterX - x
    local linearDampingAdjustment = math.ceil(distance / 36) * .1
    character.linearDamping = 0 + linearDampingAdjustment
end

function Character:release()
    local character = self._obj

    character.linearDamping = 0

    if (character.swinging == false) then return end

    if character.rope ~= nil then
        character.rope:removeSelf()
        character.rope = nil
        Runtime:removeEventListener("enterFrame", onEnterFrame)
    end

    character.fill = tuckedPaint
    character.swingable = nil
    character.swinging = false

    self:moveElements()
    self:removePivotJoint()
end

function Character:moveElements()
    local character = self._obj
    if (character.x == nil) then return end

    local vx, vy = character:getLinearVelocity()
    local releaseAngle = math.atan2(vy, vx)
    local releaseSpeed = math.sqrt(vx * vx + vy * vy)

    if (releaseAngle > -2.1 and releaseAngle < -0.9 and releaseSpeed > 300) then

        local unitsToMove = 120;
        if (releaseSpeed > 500) then
            unitsToMove = unitsToMove * 2;
        elseif (releaseSpeed > 450) then
            unitsToMove = unitsToMove * 1.5;
        elseif (releaseSpeed > 400) then
            unitsToMove = unitsToMove * 1.25;
        elseif (releaseSpeed > 350) then
            unitsToMove = unitsToMove * 1.1;
        end 

        local magnifier = 1;
        if (releaseAngle > -1.65 and releaseAngle < -1.35) then -- great release
            magnifier = 2;
        elseif (releaseAngle > -1.8 and releaseAngle < -1.2) then -- good release
            magnifier = 1.5;
        else -- fair release
            -- do nothing
        end

        unitsToMove = unitsToMove * magnifier;

        local skyLanterns = gs:getState("skyLanterns")
        for i = 1, #skyLanterns do
            skyLanterns[i]:Move(unitsToMove, 350 * magnifier, true)
        end

        local fireworks = gs:getState("fireworks")
        for i = 1, #fireworks do
            fireworks[i]:Move(unitsToMove, 350 * magnifier)
        end

        local buildings = gs:getState("buildings")
        local buildingsToKeep = {}
        local buildingsToRemove = {}
        gs:setState("buildings", buildingsToKeep)

        for i = 1, #buildings do
            local building = buildings[i]
            local keep = building:Move(unitsToMove, 350 * magnifier)
            if (keep) then
                gs:addTableMember("buildings", building)
            else
                table.insert(buildingsToRemove, building)
            end
        end

        if #gs:getState("buildings") == 4 then
            SkyLantern.startSkyLanternTimerGenerator()
            -- Firework.startFireworkTimerGenerator()
        end

        for i = 1, #buildingsToRemove do
            local building = buildingsToRemove[i]._obj
            local anchors = building.anchors
            for i = 1, #anchors do
                anchors[i]._obj:removeSelf()
            end
            building.anchors = {}
            building:removeSelf()
        end

        local mountains = gs:getState("mountains")
        transition.to(mountains, {time = ms, y = mountains.y + unitsToMove * 0.05})
    end
end

function Character:removePivotJoint()
    local character = self._obj

    if (character.pivotJoint ~= nil) then
        character.pivotJoint:removeSelf()
        character.pivotJoint = nil
    end
end

function Character:isOffScreen()
    local character = self._obj
    local edgePadding = 100

    if (character.swinging) then return false end
    
    -- Check off left
    if (character.x + character.width * 0.5) < 0 - edgePadding then
        return true
    end

    -- Check off right
    if (character.x - character.width * 0.5) > display.contentWidth + edgePadding then
        return true
    end

    -- Check off top
    -- if (character.y + character.height * 0.5) < 0 then
    --     return true
    -- end

    -- Check off bottom
    if (character.y - character.height * 0.5) > display.contentHeight + edgePadding then
        return true
    end

    return false
end

return Character