local tableHelpers = {}

function tableHelpers.find(t, predicate)
    for _, value in ipairs(t) do
        if predicate(value) then
            return value
        end
    end
    return nil
end

function tableHelpers.remove(t, predicate)
    for i = #t, 1, -1 do
        if predicate(t[i]) then
            table.remove(t, i)
        end
    end
end

function tableHelpers.filter(t, predicate)
    local result = {}
    for _, value in ipairs(t) do
        if predicate(value) then
            table.insert(result, value)
        end
    end
    return result
end


return tableHelpers