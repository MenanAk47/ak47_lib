if Config.VehicleKey == 'auto' then
    local scripts = {
        'ak47_vehiclekeys',
        'ak47_qb_vehiclekeys',
        'wasabi_carlock',
        'qs-vehiclekeys',
        'cd_garage',
        'qb-vehiclekeys',
        'qbx_vehiclekeys',
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

Lib47.GiveVehicleKey = function(plate, vehicle, virtual)
    if Config.VehicleKey == 'ak47_vehiclekeys' then
        if virtual then
            exports['ak47_vehiclekeys']:GiveVirtualKey(plate)
        else
            exports['ak47_vehiclekeys']:GiveKey(plate)
        end
    elseif Config.VehicleKey == 'ak47_qb_vehiclekeys' then
        if virtual then
            exports['ak47_qb_vehiclekeys']:GiveVirtualKey(plate)
        else
            exports['ak47_qb_vehiclekeys']:GiveKey(plate)
        end
    elseif Config.VehicleKey == 'wasabi_carlock' then
        exports['wasabi_carlock']:GiveKey(plate)
    elseif Config.VehicleKey == 'qs-vehiclekeys' then
        exports['qs-vehiclekeys']:GiveKeys(plate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    elseif Config.VehicleKey == 'cd_garage' then
        TriggerEvent('cd_garage:AddKeys', plate)
    elseif Config.VehicleKey == 'qb-vehiclekeys' or Config.VehicleKey == 'qbx_vehiclekeys' then
        TriggerEvent("qb-vehiclekeys:client:AddKeys", plate)
    elseif Config.VehicleKey == 'custom' then
        -- your custom code below

    end
end

Lib47.Callback.Register('ak47_lib:callback:client:GiveVehicleKey', function( plate, vehNetId, virtual )
    local vehicle = nil
    if NetworkDoesNetworkIdExist(vehNetId) then
        vehicle = NetToVeh(vehNetId)
    end
    return Lib47.GiveVehicleKey(plate, vehicle, virtual)
end)

Lib47.RemoveVehicleKey = function(plate, vehicle, virtual)
    if Config.VehicleKey == 'ak47_vehiclekeys' then
        if virtual then
            exports['ak47_vehiclekeys']:RemoveVirtualKey(plate)
        else
            exports['ak47_vehiclekeys']:RemoveKey(plate)
        end
    elseif Config.VehicleKey == 'ak47_qb_vehiclekeys' then
        if virtual then
            exports['ak47_qb_vehiclekeys']:RemoveVirtualKey(plate)
        else
            exports['ak47_qb_vehiclekeys']:RemoveKey(plate)
        end
    elseif Config.VehicleKey == 'wasabi_carlock' then
        exports['wasabi_carlock']:RemoveKey(plate)
    elseif Config.VehicleKey == 'qs-vehiclekeys' then
        exports['qs-vehiclekeys']:RemoveKeys(plate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    elseif Config.VehicleKey == 'cd_garage' then
        TriggerEvent('cd_garage:RemoveKeys', plate)
    elseif Config.VehicleKey == 'qb-vehiclekeys' or Config.VehicleKey == 'qbx_vehiclekeys' then
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)
    elseif Config.VehicleKey == 'custom' then
        -- your custom code below

    end
end

Lib47.Callback.Register('ak47_lib:callback:client:RemoveVehicleKey', function( plate, vehNetId, virtual )
    local vehicle = nil
    if NetworkDoesNetworkIdExist(vehNetId) then
        vehicle = NetToVeh(vehNetId)
    end
    return Lib47.RemoveVehicleKey(plate, vehicle, virtual)
end)