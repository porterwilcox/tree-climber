local state = {
    gameGroup = nil,
    character = nil,
    buildings = {},
    anchors = {},
    mountains = nil
}

local GameState = {}
GameState.__index = GameState

function GameState:new()
    local self = setmetatable({ _test = 1 }, GameState)
    return self
end

function GameState:getState(property)
    if (property ~= nil) then
        return state[property]
    else
        return state
    end
end

function GameState:setState(property, value)
    state[property] = value
end

function GameState:addTableMember(property, value)
    table.insert(state[property], value)
end

return GameState