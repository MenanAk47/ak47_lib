Lib47.GetStreetNametAtCoords = function(coords)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return { main = GetStreetNameFromHashKey(s1), cross = GetStreetNameFromHashKey(s2) }
end

Lib47.GetZoneAtCoords = function(coords) 
    return GetLabelText(GetNameOfZone(coords)) 
end

Lib47.GetCardinalDirection = function(entity)
    entity = DoesEntityExist(entity) and entity or PlayerPedId()
    if DoesEntityExist(entity) then
        local heading = GetEntityHeading(entity)
        if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then return 'North'
        elseif (heading >= 45 and heading < 135) then return 'West'
        elseif (heading >= 135 and heading < 225) then return 'South'
        elseif (heading >= 225 and heading < 315) then return 'East' end
    end
    return 'Cardinal Direction Error'
end

Lib47.GetGroundZCoord = function(coords)
    if not coords then return end
    local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, 0)
    return retval and vector3(coords.x, coords.y, groundZ) or coords
end

Lib47.GetGroundHash = function(entity)
    local coords = GetEntityCoords(entity)
    local num = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 1, 1, entity, 7)
    local retval, success, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(num)
    return materialHash, entityHit, surfaceNormal, endCoords, success, retval
end