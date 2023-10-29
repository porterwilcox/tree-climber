local mathHelpers = {}

function mathHelpers.random(min, max, numsToExclude)
    local num
    repeat
        num = math.random(min, max)
    until table.indexOf(numsToExclude, num) == nil
    return num
end


return mathHelpers