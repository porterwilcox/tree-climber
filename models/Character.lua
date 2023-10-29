local phyics = require("physics")
physics.start()

local GameState = require("states.GameState")
local gs = GameState:new()

local Building = require("models.Building")

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

local function onCollision( event )
    local character = event.target
    
    if (event.other.name == "anchor") then
        local anchor = event.other

        if (event.phase == "began") then
            local index = table.indexOf( character.swingableAnchors, anchor )
            if (index ~= nil) then table.remove(character.swingableAnchors, index) end
            table.insert(character.swingableAnchors, anchor)
            if (not character.swinging) then anchor.alpha = 0.8 end
        elseif (event.phase == "ended") then
            local index = table.indexOf( character.swingableAnchors, anchor )
            if (index ~= nil) then table.remove(character.swingableAnchors, index) end
            anchor.alpha = 0.5
            if (character.anchor == anchor) then anchor.alpha = 0.8 end
        end
    end
end

function Character:new( group )
    local character = display.newCircle( group, display.contentCenterX, display.contentHeight + 100, 10 * charPhysMod )
    character.fill = tuckedPaint
    physics.addBody(character, "dynamic", {radius = character.width/2, bounce = 0.2, density = 1 / charPhysMod})
    character.gravityScale = 1
    character:addEventListener("collision", onCollision)
    character:applyLinearImpulse(0, -6 * charPhysMod, character.x, character.y)
    -- make the character spin on it axis ie rotate
    character.angularVelocity = -200
    
    character.id = id
    character.name = "character"
    character.swingableAnchors = {}
    character.swinging = false
    id = id + 1
    local self = setmetatable({ _ref = character }, Character)
    return self
end

function Character:swing()
    local character = self._ref

    local anchor = character.swingableAnchors[#character.swingableAnchors]
    if (anchor == nil) then return end

    transition.cancelAll()

    character.fill = swingingPaint
    character.anchor = anchor
    character.swinging = true

    -- local vx, vy = character:getLinearVelocity()
    -- local angleOfDirection = math.atan2(vy, vx)
    -- local movingUp = angleOfDirection < 0
    -- local motorSpeed = 1000
    -- local isLeftOfAnchor = character.x < anchor.x
    -- if (movingUp and isLeftOfAnchor) then
    --     motorSpeed = motorSpeed * -1
    -- elseif (not movingUp and not isLeftOfAnchor) then
    --     motorSpeed = motorSpeed * -1
    -- end

    local vx, vy = character:getLinearVelocity()

    local dx = character.x - anchor.x
    local dy = character.y - anchor.y

    local crossProduct = vx * dy - vy * dx

    local motorSpeed = 1000 * charPhysMod
    if crossProduct > 0 then -- Counterclockwise
        motorSpeed = motorSpeed * 1 
        character.xScale = 1
    elseif crossProduct < 0 then -- Clockwise
        motorSpeed = motorSpeed * -1 
        character.xScale = -1
    end

    -- rotate the top of the character to the anchor
    local angle = math.atan2(character.y - anchor.y, character.x - anchor.x) * 180 / math.pi
    character.rotation = angle - 90

    -- get the distance between the character and the anchor
    local distance = math.sqrt((character.x - anchor.x) ^ 2 + (character.y - anchor.y) ^ 2)
    while (distance < 45) do
        local x = anchor.x + (character.x - anchor.x) * 2
        local y = anchor.y + (character.y - anchor.y) * 2
        character.x, character.y = x, y
        distance = math.sqrt((character.x - anchor.x) ^ 2 + (character.y - anchor.y) ^ 2)
    end

    local pivotJoint = physics.newJoint("pivot", character, anchor, anchor.x, anchor.y)
    pivotJoint.isMotorEnabled = true
    pivotJoint.motorSpeed = motorSpeed
    pivotJoint.maxMotorTorque = 10 * charPhysMod
    character.pivotJoint = pivotJoint

    local targetY = display.contentHeight - 225
    local distance = targetY - anchor.y
    if (distance > 0) then
        distance = distance + math.random(-50, 100)
    end
    if (math.abs(distance) > 100) then
        local buildings = gs:getState("buildings")
        for i = 1, #buildings do
            buildings[i]:Move(distance, 500)
        end
    end
end

function Character:setLinearDamping(x)
    local character = self._ref
    if (not character.swinging) then return end

    local distance = display.contentCenterX - x
    local linearDampingAdjustment = math.ceil(distance / 36) * .1
    character.linearDamping = 0 + linearDampingAdjustment
end

function Character:release()
    local character = self._ref

    character.linearDamping = 0

    if (character.swinging == false) then return end

    character.fill = tuckedPaint
    character.anchor = nil
    character.swinging = false

    self:moveElements()
    self:removePivotJoint()
end

function Character:moveElements()
    local character = self._ref

    local vx, vy = character:getLinearVelocity()
    local releaseAngle = math.atan2(vy, vx)
    local releaseSpeed = math.sqrt(vx * vx + vy * vy)

    if (releaseAngle > -2.1 and releaseAngle < -0.9 and releaseSpeed > 300) then -- move anchors and create a new one
        -- local building = Building:new( gs:getState("gameGroup"), 0,  0)
        -- gs:addTableMember("buildings", building)
        -- building = Building:new( gs:getState("gameGroup"), 1,  0)
        -- gs:addTableMember("buildings", building)

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
        
        for i = 1, #buildingsToRemove do
            local building = buildingsToRemove[i]._ref
            local anchors = building.anchors
            for i = 1, #anchors do
                anchors[i]._ref:removeSelf()
            end
            building.anchors = {}
            building:removeSelf()
        end

        local mountains = gs:getState("mountains")
        transition.to(mountains, {time = ms, y = mountains.y + unitsToMove * 0.05})
    end
end

function Character:removePivotJoint()
    local character = self._ref

    if (character.pivotJoint) then
        character.pivotJoint:removeSelf()
        character.pivotJoint = nil
    end
end

function Character:isOffScreen()
    local character = self._ref
    local edgePadding = 50

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