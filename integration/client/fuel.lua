if Config.FuelScript == 'auto' then
    local scripts = {
        'LegacyFuel',
        'ox_fuel',
        'ps-fuel',
        'rcore_fuel_beta',
        'rcore_fuel',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.FuelScript = script
                print(string.format("^2['FUEL']: %s^0", Config.FuelScript))
                return
            end
        end
    end)
end

Lib47.GetVehicleFuel = function(vehicle)
    if Config.FuelScript == 'LegacyFuel' then
        return exports['LegacyFuel']:GetFuel(vehicle)
    elseif Config.FuelScript == 'ox_fuel' then
        return Entity(vehicle).state.fuel
    elseif Config.FuelScript == 'ps-fuel' then
        return exports['ps-fuel']:GetFuel(vehicle)
    elseif Config.FuelScript == 'rcore_fuel' or Config.FuelScript == 'rcore_fuel_beta' then
         return exports[Config.FuelScript]:GetFuel(vehicle)
    elseif Config.FuelScript == 'custom' then
        -- your custom code below

    else
        return GetVehicleFuelLevel(vehicle)
    end
end

Lib47.SetVehicleFuel = function(vehicle, amount)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    amount = tonumber(amount) or 100.0
    if Config.FuelScript == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, amount + 0.0)
    elseif Config.FuelScript == 'ox_fuel' then
        Entity(vehicle).state.fuel = amount
    elseif Config.FuelScript == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, amount + 0.0)
    elseif Config.FuelScript == 'rcore_fuel' or Config.FuelScript == 'rcore_fuel_beta' then
        exports[Config.FuelScript]:SetFuel(vehicle, amount + 0.0)
    elseif Config.FuelScript == 'custom' then
        -- your custom code below

    else
        SetVehicleFuelLevel(vehicle, amount + 0.0)
    end
end

Lib47.Callback.Register('ak47_lib:callback:client:GetVehicleFuel', function(vehNetId)
    local vehicle = nil
    if vehNetId and vehNetId ~= 0 then
        local timeout = 0
        while not NetworkDoesNetworkIdExist(vehNetId) and timeout < 20 do
            Wait(50)
            timeout = timeout + 1
        end
        if NetworkDoesNetworkIdExist(vehNetId) then
            vehicle = NetToVeh(vehNetId)
        end
    end
    return Lib47.GetVehicleFuel(vehicle)
end)

RegisterNetEvent('ak47_lib:client:SetVehicleFuel', function( vehNetId, fuel )
    if not vehNetId or vehNetId == 0 then return end
    local timeout = 0
    while not NetworkDoesNetworkIdExist(vehNetId) and timeout < 30 do
        Wait(50)
        timeout = timeout + 1
    end
    if NetworkDoesNetworkIdExist(vehNetId) then
        local vehicle = NetToVeh(vehNetId)
        if vehicle and DoesEntityExist(vehicle) then
            Lib47.SetVehicleFuel(vehicle, fuel)
        end
    end
end)

exports('GetVehicleFuel', Lib47.GetVehicleFuel)
exports('SetVehicleFuel', Lib47.SetVehicleFuel)
