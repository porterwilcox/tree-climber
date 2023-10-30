local physics = require("physics")
physics.start()

local GameState = require("states.GameState")
local gs = GameState:new()

local Anchor = {}
Anchor.__index = Anchor

local id = 1

function Anchor:new( x, y )
    local anchor = display.newCircle( gs:getState("gameGroup"), x, y, 10 )
    anchor:setFillColor( 1, 169/255, 1/255 )
    anchor.alpha = 0
    physics.addBody(anchor, "static", {radius = 120, isSensor = true})
    
    anchor.id = id
    anchor.name = "anchor"
    id = id + 1
    local self = setmetatable({ _obj = anchor }, Anchor)
    return self
end

function Anchor:Move(unitsToMove, ms)
    local anchor = self._obj

    transition.to(anchor, {time = ms, y = anchor.y + unitsToMove})
end

return Anchor