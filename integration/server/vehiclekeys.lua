if Config.VehicleKey == 'auto' then
    local scripts = {
        'ak47_vehiclekeys',
        'ak47_qb_vehiclekeys',
        'wasabi_carlock',
        'qs-vehiclekeys',
        'cd_garage',
        'qbx_vehiclekeys',
        'qb-vehiclekeys',
        'keys',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.VehicleKey = script
                print(string.format("^2['VEHICLEKEY']: %s^0", Config.VehicleKey))
                return
            end
        end
    end)
end

Lib47.GiveVehicleKey = function(source, plate, vehNetId, virtual)
    return Lib47.Callback.Await('ak47_lib:callback:client:GiveVehicleKey', source, plate, vehNetId, virtual)
end

Lib47.RemoveVehicleKey = function(source, plate, vehNetId, virtual)
    return Lib47.Callback.Await('ak47_lib:callback:client:RemoveVehicleKey', source, plate, vehNetId, virtual)
end

RegisterNetEvent('ak47_lib:server:GiveVehicleKey', function(plate, vNid, virtual)
    local src = source  
    if Config.VehicleKey == 'qbx_vehiclekeys' then
        local vehicle = NetworkGetEntityFromNetworkId(vNid)
        exports['qbx_vehiclekeys']:GiveKeys(src, vehicle)
    end
end)

RegisterNetEvent('ak47_lib:server:RemoveVehicleKey', function(plate, vNid, virtual)
    local src = source  
    if Config.VehicleKey == 'qbx_vehiclekeys' then
        local vehicle = NetworkGetEntityFromNetworkId(vNid)
        exports['qbx_vehiclekeys']:RemoveKeys(src, vehicle)
    end
end)