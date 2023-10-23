local physics = require("physics")
physics.start()

local Branch = {}
Branch.__index = Branch

local id = 1

function Branch:new( group, x, y )
    local branch = display.newCircle( group, x, y, 10 )
    branch:setFillColor( 1, 1, 1 )
    physics.addBody(branch, "static", {radius = 120, isSensor = true})
    
    branch.id = id
    branch.name = "branch"
    id = id + 1
    local self = setmetatable({ _ref = branch }, Branch)
    return self
end

return Branch