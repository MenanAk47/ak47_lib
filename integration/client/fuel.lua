if Config.FuelScript == 'auto' then
    local scripts = {
        'LegacyFuel',
        'ox_fuel',
        'ps-fuel',
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
        exports['LegacyFuel']:GetFuel(vehicle)
    elseif Config.FuelScript == 'ox_fuel' then
        return Entity(vehicle).state.fuel
    elseif Config.FuelScript == 'ps-fuel' then
        return exports['ps-fuel']:GetFuel(vehicle)
    elseif Config.FuelScript == 'rcore_fuel' then
        return exports['rcore_fuel']:GetFuel(vehicle)
    elseif Config.FuelScript == 'custom' then
        -- your custom code below

    else
        return GetVehicleFuelLevel(vehicle)
    end
end

Lib47.SetVehicleFuel = function(vehicle, amount)
    if Config.FuelScript == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, tonumber(amount) + 0.0)
    elseif Config.FuelScript == 'ox_fuel' then
        Entity(vehicle).state.fuel = tonumber(amount)
    elseif Config.FuelScript == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, tonumber(amount) + 0.0)
    elseif Config.FuelScript == 'rcore_fuel' then
        exports['rcore_fuel']:SetFuel(vehicle, tonumber(amount) + 0.0)
    elseif Config.FuelScript == 'custom' then
        -- your custom code below

    else
        SetVehicleFuelLevel(vehicle, tonumber(amount))
    end
end