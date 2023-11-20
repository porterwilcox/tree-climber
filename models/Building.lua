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
    { fileName = "building1.png", w = 200, h = 800, p = 0, anchorConfigs = { 
        left = {
            { x = 95, y = 241 },
            { x = 95, y = 530 },
            { x = 95, y = 785 },
        },
        right = {
            { x = 95, y = 123 },
            { x = 95, y = 375 },
            { x = 95, y = 660 },
        }
    } }
}

function Building:new( side, y, bcIndex )
    local bcIndex = bcIndex or math.random(1, #buildingConfigs)
    local bc = buildingConfigs[bcIndex]

    local building = display.newImageRect( gs:getState("gameGroup"), "assets/images/" .. bc.fileName, bc.w, bc.h  )

    local sideOfScreen
    local buildingCenterX
    local anchorConfigs
    if (side == 0) then
        sideOfScreen = left
        buildingCenterX = left  + bc.p
        anchorConfigs = bc.anchorConfigs.left
    else
        sideOfScreen = right
        buildingCenterX = right - bc.p
        anchorConfigs = bc.anchorConfigs.right
    end

    local buildingCenterY = y - bc.h/2

    building.x, building.y = buildingCenterX, buildingCenterY
    
    building.id = id
    building.name = "building"
    building.anchors = {}
    id = id + 1
    local self = setmetatable({ _obj = building }, Building)

    for i = 1, #anchorConfigs do
        self:addAnchor(sideOfScreen, y, anchorConfigs[i])
    end

    return self
end

function Building:addAnchor(sideOfScreen, buildingBottom, ac)
    local x = ac.x
    if (sideOfScreen == right) then
        x = x*-1
    end
    local anchorX = sideOfScreen + x
    local anchorY = buildingBottom - ac.y
    local anchor = Anchor:new( anchorX, anchorY )
    table.insert(self._obj.anchors, anchor)
end

function Building:Move(unitsToMove, ms)
    local building = self._obj

    if (building.y > display.contentHeight + building.height) then
        return false
    end
    
    transition.to(building, {time = ms, y = building.y + unitsToMove, transition = easing.outSine })

    local anchors = building.anchors
    for i = 1, #anchors do
        anchors[i]:Move(unitsToMove, ms)
    end

    return true
end

function Building.initTwo( y, bcIndex )
    local bcIndex = bcIndex or 1
    local building = Building:new( 0, y )
    gs:addTableMember("buildings", building, bcIndex)

    building = Building:new( 1, y )
    gs:addTableMember("buildings", building, bcIndex)
end

return Building