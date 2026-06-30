local function ConvertVersionToDecimal(versionStr)
    if type(versionStr) ~= "string" then return 0 end

    local cleanStr = string.gsub(versionStr, "[^%d%.]", "")
    local parts = {}

    for part in string.gmatch(cleanStr, "([^%.]+)") do
        table.insert(parts, part)
    end

    if #parts == 0 then return 0 end
    if #parts == 1 then return tonumber(parts[1]) or 0 end

    local major = parts[1]
    local decimals = ""
    
    for i = 2, #parts do
        decimals = decimals .. parts[i]
    end
    
    return tonumber(major .. "." .. decimals) or 0
end

Lib47.GetResourceVersion = function(resourceName)
    if GetResourceState(resourceName) == "missing" then
        return 0
    end

    local manifestData = LoadResourceFile(resourceName, "fxmanifest.lua")
    
    if not manifestData then
        manifestData = LoadResourceFile(resourceName, "__resource.lua")
    end

    if not manifestData then
        return 0
    end

    local paddedManifest = "\n" .. manifestData
    local version = string.match(paddedManifest, "\n%s*version%s+['\"](.-)['\"]")

    return ConvertVersionToDecimal(version)
end