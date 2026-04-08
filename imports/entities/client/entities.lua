Lib47.GetVehicles = function() return GetGamePool('CVehicle') end
Lib47.GetObjects = function() return GetGamePool('CObject') end
Lib47.GetPlayers = function() return GetActivePlayers() end
Lib47.GetPeds = function(ignoreList)
    local pedPool = GetGamePool('CPed')
    local peds, ignoreTable = {}, {}
    ignoreList = ignoreList or {}
    for i = 1, #ignoreList do ignoreTable[ignoreList[i]] = true end
    for i = 1, #pedPool do
        if not ignoreTable[pedPool[i]] then peds[#peds + 1] = pedPool[i] end
    end
    return peds
end

Lib47.GetPlayersFromCoords = function(coords, distance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
    distance = distance or 5
    local closePlayers = {}
    for _, player in ipairs(players) do
        local targetCoords = GetEntityCoords(GetPlayerPed(player))
        if #(targetCoords - coords) <= distance then closePlayers[#closePlayers + 1] = player end
    end
    return closePlayers
end

Lib47.GetClosestPlayer = function(coords)
    local ped = PlayerPedId()
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
    local closestPlayers = Lib47.GetPlayersFromCoords(coords)
    local closestDistance, closestPlayer = -1, -1
    for i = 1, #closestPlayers do
        if closestPlayers[i] ~= PlayerId() and closestPlayers[i] ~= -1 then
            local distance = #(GetEntityCoords(GetPlayerPed(closestPlayers[i])) - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

Lib47.GetClosestPed = function(coords, ignoreList)
    local ped = PlayerPedId()
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
    local peds = Lib47.GetPeds(ignoreList)
    local closestDistance, closestPed = -1, -1
    for i = 1, #peds do
        local distance = #(GetEntityCoords(peds[i]) - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestPed = peds[i]
            closestDistance = distance
        end
    end
    return closestPed, closestDistance
end

Lib47.GetClosestVehicle = function(coords)
    local ped = PlayerPedId()
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance, closestVehicle = -1, -1
    for i = 1, #vehicles do
        local distance = #(GetEntityCoords(vehicles[i]) - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

Lib47.GetClosestObject = function(coords)
    local ped = PlayerPedId()
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(ped)
    local objects = GetGamePool('CObject')
    local closestDistance, closestObject = -1, -1
    for i = 1, #objects do
        local distance = #(GetEntityCoords(objects[i]) - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestObject = objects[i]
            closestDistance = distance
        end
    end
    return closestObject, closestDistance
end

Lib47.LookAtEntity = function(entity, timeout, speed)
    if not DoesEntityExist(entity) then return end
    local ped = PlayerPedId()
    local targetHeading = GetHeadingFromVector_2d(GetEntityCoords(entity).x - GetEntityCoords(ped).x, GetEntityCoords(entity).y - GetEntityCoords(ped).y)
    SetEntityHeading(ped, targetHeading)
end

Lib47.GetClosestBone = function(entity, list)
    local playerCoords, bone, coords, distance = GetEntityCoords(PlayerPedId())
    for _, element in pairs(list) do
        local boneCoords = GetWorldPositionOfEntityBone(entity, element.id or element)
        local boneDistance = #(playerCoords - boneCoords)
        if not coords or distance > boneDistance then
            bone, coords, distance = element, boneCoords, boneDistance
        end
    end
    if not bone then
        bone = { id = GetEntityBoneIndexByName(entity, 'bodyshell'), type = 'remains', name = 'bodyshell' }
        coords = GetWorldPositionOfEntityBone(entity, bone.id)
        distance = #(coords - playerCoords)
    end
    return bone, coords, distance
end

Lib47.GetBoneDistance = function(entity, boneType, boneIndex)
    local bone = (boneType == 1) and GetPedBoneIndex(entity, boneIndex) or GetEntityBoneIndexByName(entity, boneIndex)
    return #(GetWorldPositionOfEntityBone(entity, bone) - GetEntityCoords(PlayerPedId()))
end

Lib47.AttachProp = function(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    local modelHash = type(model) == 'string' and joaat(model) or model
    local bone = GetPedBoneIndex(ped, boneId)
    Lib47.RequestModel(modelHash)
    local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 1, not vertex and 2 or 0, 1)
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end