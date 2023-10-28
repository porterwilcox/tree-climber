local physics = require("physics")
physics.start()

local tablehelpers = require( "helpers.tablehelpers" )

local Anchor = require("models.Anchor")

local Building = {}
Building.__index = Building

local id = 1

local left = 0
local right = display.contentWidth

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

function Building:new( group, side, y )
    local buildingConfigIndex = math.random(1, #buildingConfigs)
    local bc = buildingConfigs[buildingConfigIndex]

    local building = display.newImageRect( group, "assets/images/" .. bc.fileName, bc.w, bc.h  )

    local sideOfScreen
    local buildingCenterX
    if (side == 1) then
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

    self:addAnchor(group, bc, sideOfScreen, y)

    return self
end

function Building:addAnchor(group, bc, sideOfScreen, buildingBottom, anchorConfigIndex)
    local stopRecursion = anchorConfigIndex ~= nil
    local anchorConfigIndex = anchorConfigIndex or math.random(1, #bc.anchorConfigs)
    local ac = bc.anchorConfigs[anchorConfigIndex]

    local x = ac.x
    if (sideOfScreen == right) then
        x = x*-1
    end
    local anchorX = sideOfScreen + x
    local anchorY = buildingBottom - ac.y
    local anchor = Anchor:new(group, anchorX, anchorY)
    table.insert(self._ref.anchors, anchor)

    if (not stopRecursion) then
        if (anchorConfigIndex < 6) then
            self:addAnchor(group, bc, sideOfScreen, buildingBottom, math.random(12, 16))
        elseif (anchorConfigIndex > 11) then
            self:addAnchor(group, bc, sideOfScreen, buildingBottom, math.random(1, 5))
        end
    end
end

function Building:MoveDownward(unitsToMove, ms)
    local building = self._ref

    if (building.y > display.contentHeight + building.height) then
        return false
    end
    
    transition.to(building, {time = ms, y = building.y + unitsToMove})

    local anchors = building.anchors
    for i = 1, #anchors do
        anchors[i]:MoveDownward(unitsToMove, ms)
    end

    return true
end

return Building