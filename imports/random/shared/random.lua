Lib47.Random = {}

local StringCharset = {}
local NumberCharset = {}

for i = 48, 57 do table.insert(NumberCharset, string.char(i)) end
for i = 65, 90 do table.insert(StringCharset, string.char(i)) end
for i = 97, 122 do table.insert(StringCharset, string.char(i)) end

Lib47.Random.Str = function(length)
    if length > 0 then
        return Lib47.Random.Str(length - 1) .. StringCharset[math.random(1, #StringCharset)]
    else
        return ''
    end
end

Lib47.Random.Int = function(length)
    if length > 0 then
        return Lib47.Random.Int(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
    else
        return ''
    end
end
