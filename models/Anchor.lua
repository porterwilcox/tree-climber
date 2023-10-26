local physics = require("physics")
physics.start()

local Anchor = {}
Anchor.__index = Anchor

local id = 1

function Anchor:new( group, x, y )
    local anchor = display.newCircle( group, x, y, 10 )
    anchor:setFillColor( 1, 1, 1 )
    physics.addBody(anchor, "static", {radius = 120, isSensor = true})
    
    anchor.id = id
    anchor.name = "anchor"
    id = id + 1
    local self = setmetatable({ _ref = anchor }, Anchor)
    return self
end

function Anchor:MoveDownward(unitsToMove)
    local anchor = self._ref

    transition.to(anchor, {time = 250, y = anchor.y + unitsToMove})
end

return Anchor