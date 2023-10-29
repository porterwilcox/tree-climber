local physics = require("physics")
physics.start()

local mathHelpers = require( "helpers.mathHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local Anchor = require("models.Anchor")

local Building = {}
Building.__index = Building

local id = 1

local left = 0
local right = display.contentWidth
local lastLeftAnchor

local buildingConfigs = {
    -- { fileName = "poc1.png", w = 164, h = 290, p = 10, anchorConfigs = { 
    --     {x = 90, y = 98 }, 
    --     {x = 78, y = 136 }, 
    --     {x = 70, y = 171 }, 
    --     {x = 63, y = 206 }, 
    --     {x = 55, y = 240 }, 
    --     {x = 46, y = 273 }, 
    -- } },
    -- { fileName = "poc.png", w = 157, h = 188, p = 30, anchorConfigs = {
    --     { x = 107, y = 77 },
    --     { x = 90, y = 114 },
    --     { x = 80, y = 150 },
    --     { x = 30, y = 187 },
    -- } }
    { fileName = "building1.png", w = 200, h = 800, p = 0, anchorConfigs = { --16 anchors
        { x = 100, y = 40 },
        { x = 100, y = 90 },
        { x = 100, y = 140 },
        { x = 100, y = 190 },
        { x = 100, y = 240 },
        { x = 100, y = 290 },
        { x = 100, y = 340 },
        { x = 100, y = 390 },
        { x = 100, y = 440 },
        { x = 100, y = 490 },
        { x = 100, y = 540 },
        { x = 100, y = 590 },
        { x = 100, y = 640 },
        { x = 100, y = 690 },
        { x = 100, y = 740 },
        { x = 100, y = 790 },
    } }
}

function Building:new( side, y, bcIndex, acIndex )
    local bcIndex = bcIndex or math.random(1, #buildingConfigs)
    local bc = buildingConfigs[bcIndex]

    local building = display.newImageRect( gs:getState("gameGroup"), "assets/images/" .. bc.fileName, bc.w, bc.h  )

    local sideOfScreen
    local buildingCenterX
    if (side == 0) then
        sideOfScreen = left
        buildingCenterX = left  + bc.p
    else
        sideOfScreen = right
        buildingCenterX = right - bc.p
    end

    local buildingCenterY = y - bc.h/2

    building.x, building.y = buildingCenterX, buildingCenterY
    
    building.id = id
    building.name = "building"
    building.anchors = {}
    id = id + 1
    local self = setmetatable({ _ref = building }, Building)

    self:addAnchor(bc, sideOfScreen, y, acIndex)

    return self
end

function Building:addAnchor(bc, sideOfScreen, buildingBottom, acIndex, stopRecursion)
    local acIndex = acIndex or math.random(1, #bc.anchorConfigs)
    local ac = bc.anchorConfigs[acIndex]

    local x = ac.x
    if (sideOfScreen == right) then
        x = x*-1
    end
    local anchorX = sideOfScreen + x
    local anchorY = buildingBottom - ac.y
    local anchor = Anchor:new( anchorX, anchorY )
    table.insert(self._ref.anchors, anchor)

    if (not stopRecursion) then
        if (acIndex < 7) then
            self:addAnchor(bc, sideOfScreen, buildingBottom, acIndex + 8, true)
        elseif (acIndex > 10) then
            self:addAnchor(bc, sideOfScreen, buildingBottom, acIndex - 8, true)
        end
    end
end

function Building:Move(unitsToMove, ms)
    local building = self._ref

    if (building.y > display.contentHeight + building.height) then
        return false
    end
    
    transition.to(building, {time = ms, y = building.y + unitsToMove})

    local anchors = building.anchors
    for i = 1, #anchors do
        anchors[i]:Move(unitsToMove, ms)
    end

    return true
end

function Building.initTwo( y, isStart )
    local bcIndex = 1
    local acIndex = math.random(3, 7)
    if (not isStart) then
        bcIndex = math.random(1, #buildingConfigs)
        acIndex = math.random(1, #buildingConfigs[bcIndex].anchorConfigs)
    end
    local building = Building:new( 0, y, bcIndex, acIndex )
    gs:addTableMember("buildings", building)

    acIndex = mathHelpers.random(3, 7, { acIndex })
    if (not isStart) then
        acIndex = mathHelpers.random(1, #buildingConfigs[bcIndex].anchorConfigs, { acIndex, acIndex - 8, acIndex + 8 })
    end
    building = Building:new( 1, y, bcIndex, acIndex )
    gs:addTableMember("buildings", building)
end

return Building