local phyics = require("physics")
physics.start()

local GameState = require("states.GameState")
local gs = GameState:new()

local Monkey = {}
Monkey.__index = Monkey

local id = 1

local lastBranchSwungFrom

local function onCollision( event )
    local monkey = event.target
    
    if (event.other.name == "branch") then
        local branch = event.other

        if (event.phase == "began") then
            local index = table.indexOf( monkey.swingableBranches, branch )
            if (index ~= nil) then table.remove(monkey.swingableBranches, index) end
            table.insert(monkey.swingableBranches, branch)
        elseif (event.phase == "ended") then
            local index = table.indexOf( monkey.swingableBranches, branch )
            if (index ~= nil) then table.remove(monkey.swingableBranches, index) end
        end
    end
end

function Monkey:new( group )
    local monkey = display.newCircle( group, display.contentCenterX, 650, 10 )
    monkey:setFillColor( 0, 1, 0 )
    physics.addBody(monkey, "dynamic", {radius = monkey.width/2, bounce = 0.2, density = 1})
    monkey.gravityScale = 0
    monkey:addEventListener("collision", onCollision)
    
    monkey.id = id
    monkey.name = "monkey"
    monkey.bananaCount = 0
    monkey.swingableBranches = {}
    monkey.swinging = false
    id = id + 1
    local self = setmetatable({ _ref = monkey }, Monkey)
    return self
end

function Monkey:swing()
    local monkey = self._ref

    local branch = monkey.swingableBranches[#monkey.swingableBranches]
    if (branch == nil) then return end

    lastBranchSwungFrom = branch

    monkey.swinging = true

    local pivotJoint = physics.newJoint("pivot", monkey, branch, branch.x, branch.y)
    pivotJoint.isMotorEnabled = true
    pivotJoint.motorSpeed = -1000
    pivotJoint.maxMotorTorque = 10
    monkey.pivotJoint = pivotJoint

    -- Could be improved to mimic real physics per swing direction better
    local previousVelocity = monkey.angularVelocity
    timer.performWithDelay( 20, function() 
        if (monkey.angularVelocity < previousVelocity) then
            pivotJoint.motorSpeed = pivotJoint.motorSpeed * -1
        end
    end, 1)
end

function Monkey:setPivotJointMotorTorque(x)
    local monkey = self._ref
    local pivotJoint = monkey.pivotJoint
    if (not monkey.swinging or pivotJoint == nil) then return end

    local distance = display.contentCenterX - x
    local torqueAdjustment = math.ceil(distance / 36)
    pivotJoint.maxMotorTorque = 10 - torqueAdjustment
end

function Monkey:release()
    local monkey = self._ref

    if (monkey.swinging == false) then return end

    monkey.swinging = false

    monkey.gravityScale = 1
    local xForce = 5 * math.sin(monkey.rotation)
    local yForce = -1 * math.cos(monkey.rotation)
    monkey:applyForce(xForce, yForce, monkey.x, monkey.y)

    self:removePivotJoint()
end

function Monkey:removePivotJoint()
    local monkey = self._ref

    if (monkey.pivotJoint) then
        monkey.pivotJoint:removeSelf()
        monkey.pivotJoint = nil
    end
end

return Monkey