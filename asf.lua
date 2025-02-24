--[[
    Advanced String Functions
]]

asf = {}

function asf:clone(str, n)
    local newstr = ""
    for i = 1, n do
        newstr = newstr .. str
    end
    return newstr
end

function asf:from_array(array)
    local newstr = ""
    for i = 1, #array do
        newstr = newstr .. array[i] .. " "
    end
    return newstr
end

function asf:fill_right(str, n)
    str = str .. asf:clone(" ", n - #str)

    return str
end

return asf
