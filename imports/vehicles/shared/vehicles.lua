Lib47.GetPlate = function(vehicle)
    if vehicle == 0 or vehicle == nil then return end
    return Lib47.String.Trim(GetVehicleNumberPlateText(vehicle))
end

Lib47.IsSpawnPointClear = function(coords, radius)
    if not coords then return false end
    if not radius then radius = 5.0 end
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    local vehicles = GetGamePool('CVehicle')
    local closeVeh = {}
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if distance <= radius then
            closeVeh[#closeVeh + 1] = vehicles[i]
        end
    end
    if #closeVeh > 0 then return false end
    return true
end

Lib47.GetVehicleFromPlate = function(plate)
    if not plate then return false end
    plate = Lib47.String.Trim(plate)
    for _, v in pairs(GetGamePool('CVehicle')) do
        if plate == Lib47.GetPlate(v) then
            return v
        end
    end
    return false
end