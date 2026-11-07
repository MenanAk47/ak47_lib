local function split(str)
    local parts = {}
    local cleaned = string.gsub(str or "", "[^%d%.]", "")
    for part in string.gmatch(cleaned, "([^%.]+)") do
        table.insert(parts, tonumber(part) or 0)
    end
    return parts
end

local IsVersionLower = function(currentVersion, newVersion)
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

-- Checks if a consuming script's version meets minimum requirements
Lib47.IsVersionCompatible = function(requiredVersion)
    local invokedResource = GetInvokingResource()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    if IsVersionLower(currentVersion, requiredVersion) then
        CreateThread(function()
            Wait(1000)
            print(string.format("^1Incompatible [ak47_lib] version for resource: [%s]^0", invokedResource))
            print(string.format("^3You need minimum [ak47_lib] version: %s^0", requiredVersion))
            print(string.format("^3Download latest ak47_lib:^5 %s^0", 'https://github.com/MenanAk47/ak47_lib/releases/latest'))
        end)
        return false
    end
    return true
end

-- Automated GitHub Release Checker
local function CheckGitHubVersion()
    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, 'version', 0) or '1.0.0'
    local repo = 'MenanAk47/ak47_lib'
    local url = string.format('https://api.github.com/repos/%s/releases/latest', repo)

    PerformHttpRequest(url, function(status, responseText, headers)
        if status ~= 200 or not responseText then
            return
        end

        local success, data = pcall(json.decode, responseText)
        if not success or not data or not data.tag_name then
            return
        end

        local latestVersion = data.tag_name

        if IsVersionLower(currentVersion, latestVersion) then
            print('^2----------------------------------------------------------------------^0')
            print(string.format('^1An update is available!^0'))
            print(string.format('^3Current Version: ^1%s^0 | ^3Latest Version: ^2%s^0', currentVersion, latestVersion))
            if data.html_url then
                print(string.format('^3Download: ^5%s^0', data.html_url))
            end
            print('^2----------------------------------------------------------------------^0')
        end
    end, 'GET', '', {
        ['User-Agent'] = 'FiveM-' .. resourceName,
        ['Accept'] = 'application/vnd.github.v3+json'
    })
end

CreateThread(function()
    Wait(3000)
    CheckGitHubVersion()
end)