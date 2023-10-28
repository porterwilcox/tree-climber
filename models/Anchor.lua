local physics = require("physics")
physics.start()

local Anchor = {}
Anchor.__index = Anchor

local id = 1

function Anchor:new( group, x, y )
    local anchor = display.newCircle( group, x, y, 10 )
    anchor:setFillColor( 1, 169/255, 1/255 )
    anchor.alpha = 0.5
    physics.addBody(anchor, "static", {radius = 120, isSensor = true})
    
    anchor.id = id
    anchor.name = "anchor"
    id = id + 1
    local self = setmetatable({ _ref = anchor }, Anchor)
    return self
end

function Anchor:MoveDownward(unitsToMove, ms)
    local anchor = self._ref

    transition.to(anchor, {time = ms, y = anchor.y + unitsToMove})
end

return Anchor