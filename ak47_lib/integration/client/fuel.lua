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

    end
end