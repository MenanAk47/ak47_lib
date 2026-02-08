local IsVersionLower = function(currentVersion, newVersion)
    local function split(str)
        local parts = {}
        for part in string.gmatch(str, "([^%.]+)") do
            table.insert(parts, tonumber(part) or 0)
        end
        return parts
    end

    local vA = split(currentVersion)
    local vB = split(newVersion)
    local maxLen = math.max(#vA, #vB)

    for i = 1, maxLen do
        local numA = vA[i] or 0
        local numB = vB[i] or 0

        if numA < numB then
            return true 
        elseif numA > numB then
            return false 
        end
    end

    return false
end

Lib47.IsVersionCompatible = function(requiredVersion)
    local invokedResource = GetInvokingResource()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    if IsVersionLower(currentVersion, requiredVersion) then
        print(string.format("^1Incomatible ak47_lib version for resource: [%s]^0", invokedResource))
        print(string.format("^3You need minimum ak47_lib version: %s^0", requiredVersion))
        print(string.format("^3Download latest ak47_lib:^5 %s^0", 'https://github.com/MenanAk47/ak47_lib/releases/latest'))
        return false
    end
    return true
end