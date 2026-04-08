Lib47.SpawnVehicle = function(source, model, coords, warp)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(ped) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        while GetVehiclePedIsIn(ped) ~= veh do Wait(0); TaskWarpPedIntoVehicle(ped, veh, -1) end
    end
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    return veh
end

Lib47.CreateAutomobile = function(source, model, coords, warp)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
    local veh = Citizen.InvokeNative(`CREATE_AUTOMOBILE`, model, coords, coords.w or 0.0, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
    return veh
end

Lib47.CreateVehicleServerSetter = function(source, model, vehtype, coords, warp)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
    local veh = CreateVehicleServerSetter(model, vehtype, coords, coords.w or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
    return veh
end