local physics = require("physics")
physics.start()

local GameState = require("states.GameState")
local gs = GameState:new()

local Owl = require("models.Owl")

local Anchor = {}
Anchor.__index = Anchor

local id = 1

function Anchor:new( x, y, bId )
    local anchor = display.newCircle( gs:getState("gameGroup"), x, y, 10 )
    anchor:setFillColor( 1, 169/255, 1/255 )
    anchor.alpha = 0
    physics.addBody(anchor, "static", {radius = 120, isSensor = true})
    anchor.physicalBodyExists = true
    
    anchor.id = id
    anchor.name = "anchor"
    id = id + 1
    anchor.testingPOC = "testingPOC"
    local self = setmetatable({ _obj = anchor }, Anchor)

    --use the building id to programmaticaly make more Owls as the bId is higher
    local randomComparer = math.random(6, 52)
    if (bId > randomComparer) then
        anchor.owl = Owl:new(anchor)
        anchor:setFillColor( 1, 1, 1 )
    end

    return self
end

function Anchor:move(unitsToMove, ms)
    local anchor = self._obj

    transition.to(anchor, {time = ms, y = anchor.y + unitsToMove, transition = easing.outSine })

    if anchor.owl ~= nil then
        anchor.owl:move(unitsToMove, ms)
    end
end

function Anchor:delete()
    local anchor = self._obj
    if anchor.owl ~= nil then
        anchor.owl:delete()
    end
    anchor:removeSelf()
    anchor.deleted = true
end

return Anchor