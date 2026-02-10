if Config.Garage == 'auto' then
    local scripts = {
        'ak47_garage',
        'ak47_qb_garage',
        'cd_garage',
        'okokGarage',
        'jg-advancedgarages',
        'loaf_garage',
        'qb-garages',
        'qbx_garages',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.Garage = script
                print(string.format("^2['GARAGE']: %s^0", Config.Garage))
                return
            end
        end
    end)
end

Lib47.StoreVehicleHousing = function(garageid, vehicle)
    if Config.Garage == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:storevehicle", "Housing "..garageid, 'car')
    elseif Config.Garage == 'ak47_qb_garage' then
        TriggerEvent("ak47_qb_garage:housing:storevehicle", "Housing "..garageid, 'car')
    elseif Config.Garage == 'cd_garage' then
        TriggerEvent('cd_garage:StoreVehicle_Main', 1, false)
    elseif Config.Garage == 'okokGarage' then
        TriggerEvent("okokGarage:StoreVehiclePrivate")
    elseif Config.Garage == 'jg-advancedgarages' then
        TriggerEvent('jg-advancedgarages:client:store-vehicle', 'housing:'..garageid, "car")
    elseif Config.Garage == 'loaf_garage' then
        exports.loaf_garage:StoreVehicle("property", vehicle)
    elseif Config.Garage == 'custom' then
        -- your custom code below

    end
end

Lib47.OpenGarageHousing = function(garageid)
    local playerCoords, playerHeading = GetEntityCoords(cache.ped), GetEntityHeading(cache.ped)
    if Config.Garage == 'cd_garage' then
        TriggerEvent('cd_garage:PropertyGarage', 'quick', nil)
    elseif Config.Garage == 'okokGarage' then
        TriggerEvent("okokGarage:OpenPrivateGarageMenu", GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
    elseif Config.Garage == 'jg-advancedgarages' then
        TriggerEvent('jg-advancedgarages:client:open-garage', 'housing:'..garageid, "car", vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading))
    elseif Config.Garage == 'ak47_garage' then
        TriggerEvent("ak47_garage:housing:takevehicle", "Housing "..garageid, 'car')
    elseif Config.Garage == 'loaf_garage' then
        exports.loaf_garage:BrowseVehicles("property", vec4(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading))
    elseif Config.Garage == 'custom' then
        -- your custom code below

    end
end