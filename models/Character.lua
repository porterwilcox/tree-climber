local phyics = require("physics")
physics.start()

local GameState = require("states.GameState")
local gs = GameState:new()

local Anchor = require("models.Anchor")

local Character = {}
Character.__index = Character

local id = 1

local function onCollision( event )
    local character = event.target
    
    if (event.other.name == "anchor") then
        local anchor = event.other

        if (event.phase == "began") then
            local index = table.indexOf( character.swingableAnchors, anchor )
            if (index ~= nil) then table.remove(character.swingableAnchors, index) end
            table.insert(character.swingableAnchors, anchor)
        elseif (event.phase == "ended") then
            local index = table.indexOf( character.swingableAnchors, anchor )
            if (index ~= nil) then table.remove(character.swingableAnchors, index) end
        end
    end
end

function Character:new( group )
    local character = display.newCircle( group, display.contentCenterX, -1, 10 )
    character:setFillColor( 0, 1, 0 )
    physics.addBody(character, "dynamic", {radius = character.width/2, bounce = 0.2, density = 1})
    character.gravityScale = 1
    character:addEventListener("collision", onCollision)
    
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

    character.swinging = true

    local vx, vy = character:getLinearVelocity()
    local angleOfDirection = math.atan2(vy, vx)
    local movingUp = angleOfDirection < 0
    local motorSpeed = 1000
    local isLeftOfAnchor = character.x < anchor.x
    if (movingUp and isLeftOfAnchor) then
        motorSpeed = motorSpeed * -1
    elseif (not movingUp and not isLeftOfAnchor) then
        motorSpeed = motorSpeed * -1
    end

    local pivotJoint = physics.newJoint("pivot", character, anchor, anchor.x, anchor.y)
    pivotJoint.isMotorEnabled = true
    pivotJoint.motorSpeed = motorSpeed
    pivotJoint.maxMotorTorque = 10
    character.pivotJoint = pivotJoint

    if (anchor.y < display.contentHeight * 0.5) then
        local anchor = Anchor:new( gs:getState("treeGroup"), math.random(100, display.contentWidth - 100), math.random(-120, -5) )
        gs:addTableMember("anchors", anchor)

        local anchors = gs:getState("anchors")
        for i = 1, #anchors do
            anchors[i]:MoveDownward(display.contentHeight / 2.5)
        end
    end
end

function Character:setPivotJointMotorTorque(x)
    local character = self._ref
    local pivotJoint = character.pivotJoint
    if (not character.swinging or pivotJoint == nil) then return end

    local distance = display.contentCenterX - x
    local torqueAdjustment = math.ceil(distance / 36)
    pivotJoint.maxMotorTorque = 10 - torqueAdjustment
end

local releaseCount = 1
function Character:release()
    local character = self._ref
    character.angularVelocity = character.angularVelocity * 3  --easy way to manipulate how far the character flys

    if (character.swinging == false) then return end

    character.swinging = false

    self:manageAnchors()
    self:removePivotJoint()
end

function Character:manageAnchors()
    local character = self._ref

    local vx, vy = character:getLinearVelocity()
    local releaseAngle = math.atan2(vy, vx)
    local releaseSpeed = math.sqrt(vx * vx + vy * vy)

    if (releaseAngle > -2.1 and releaseAngle < -0.9 and releaseSpeed > 300) then -- move anchors and create a new one

        -- create a new anchor at a random x position at a random y position between 5 and 80 units above the top of the screen
        local anchor = Anchor:new( gs:getState("treeGroup"), math.random(100, display.contentWidth - 100), math.random(-120, -5) )
        gs:addTableMember("anchors", anchor)

        local unitsToMove = 80;
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

        local anchors = gs:getState("anchors")

        for i = 1, #anchors do
            anchors[i]:MoveDownward(unitsToMove)
        end
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