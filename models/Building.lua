local physics = require("physics")
physics.start()

local Anchor = require("models.Anchor")

local Building = {}
Building.__index = Building

local id = 1

local left = 0
local right = display.contentWidth

local buildingConfigs = {
    { fileName = "building1.png", w = 164, h = 290, p = 10, anchorConfigs = { 
        {x = 90, y = 98 }, 
        {x = 78, y = 136 }, 
        {x = 70, y = 171 }, 
        {x = 63, y = 206 }, 
        {x = 55, y = 240 }, 
        {x = 46, y = 273 }, 
    } },
    { fileName = "building2.png", w = 157, h = 188, p = 30, anchorConfigs = {
        { x = 107, y = 77 },
        { x = 90, y = 114 },
        { x = 80, y = 150 },
        { x = 30, y = 187 },
    } }
}

function Building:new( group, y )
    local buildingConfigIndex = math.random(1, #buildingConfigs)
    local bc = buildingConfigs[buildingConfigIndex]

    local building = display.newImageRect( group, "assets/images/" .. bc.fileName, bc.w, bc.h  )

    local sideOfScreen
    local buildingCenterX
    if (math.random(1, 2) == 1) then
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

function Building:addAnchor(group, bc, sideOfScreen, buildingBottom)
    local anchorConfigIndex = math.random(1, #bc.anchorConfigs)
    local ac = bc.anchorConfigs[anchorConfigIndex]

    local x = ac.x
    print( "sideOfScreen: " .. sideOfScreen .. " right: " .. right )
    if (sideOfScreen == right) then
        x = x*-1
    end
    print("x: " .. x)
    local anchorX = sideOfScreen + x
    local anchorY = buildingBottom - ac.y
    local anchor = Anchor:new(group, anchorX, anchorY)
    table.insert(self._ref.anchors, anchor)
end

function Building:MoveDownward(unitsToMove)
    local building = self._ref

    if (building.y > display.contentHeight + building.height) then
        local anchors = building.anchors
        for i = 1, #anchors do
            anchors[i]._ref:removeSelf()
        end
        building:removeSelf()
        return
    end

    transition.to(building, {time = 250, y = building.y + unitsToMove})

    local anchors = building.anchors
    for i = 1, #anchors do
        anchors[i]:MoveDownward(unitsToMove)
    end
end

return Building