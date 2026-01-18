if Config.Inventory == 'auto' then
    local scripts = {
        'ak47_qb_inventory',
        'ak47_inventory',
        'ox_inventory',
        'qs-inventory',
        'qb-inventory',
        'ps-inventory',
        'lj-inventory',
        'codem-inventory',
        'origen_inventory',
        'tgiann-inventory',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.Inventory = script
                print(string.format("^2['INVENTORY']: %s^0", Config.Inventory))
                return
            end
        end
    end)
end

Bridge.SetInventoryBusy = function(state)
    LocalPlayer.state:set('invBusy', state, true)
    LocalPlayer.state:set('inv_busy', state, true)
end

Bridge.OpenSearchInventory = function(targetServerId)
    if Config.Inventory == 'ak47_inventory' then
        exports['ak47_inventory']:OpenInventory(targetServerId)
    elseif Config.Inventory == 'ak47_qb_inventory' then
        exports['ak47_qb_inventory']:OpenInventory(targetServerId)
    elseif Config.Inventory == 'ox_inventory' then
        exports['ox_inventory']:openInventory('player', targetServerId)
    elseif Config.Inventory == 'qs-inventory' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", targetServerId)
    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent('ak47_bridge:openqbinventory', targetServerId)
    elseif Config.Inventory == 'qb-inventory-old' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", targetServerId)
    elseif Config.Inventory == 'ps-inventory' then
        TriggerServerEvent("ps-inventory:server:OpenInventory", "otherplayer", targetServerId)
    elseif Config.Inventory == 'lj-inventory' then
        TriggerServerEvent("lj-inventory:server:OpenInventory", "otherplayer", targetServerId)
    elseif Config.Inventory == 'codem-inventory' then
        TriggerClientEvent('codem-inventory:client:robplayer')
    elseif Config.Inventory == 'origen_inventory' then
        exports['origen_inventory']:openInventory('player', targetServerId)
    elseif Config.Inventory == 'tgiann-inventory' then
        exports["tgiann-inventory"]:OpenInventory('otherplayer', targetServerId)
    end
end

Bridge.OpenStash = function(identifier, name, weight, slots)
    if Config.Inventory == 'ak47_inventory' then
        exports["ak47_inventory"]:OpenInventory({identifier = identifier, type = 'stash', label = name, maxWeight = weight * 1000, slots = slots})
    elseif Config.Inventory == 'ak47_qb_inventory' then
        exports["ak47_qb_inventory"]:OpenInventory({identifier = identifier, type = 'stash', label = name, maxWeight = weight * 1000, slots = slots})
    elseif Config.Inventory == 'qb-inventory-old' then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", identifier, {maxweight = weight * 1000, slots = slots})
        TriggerEvent("inventory:client:SetCurrentStash", identifier)
    elseif Config.Inventory == 'ps-inventory' then
        TriggerServerEvent("ps-inventory:server:OpenInventory", "stash", identifier, {maxweight = weight * 1000, slots = slots})
        TriggerEvent("ps-inventory:client:SetCurrentStash", identifier)
    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent("ak47_qb_policejob:OpenQbStash", identifier, {maxweight = weight * 1000, slots = slots, label = name})
    elseif Config.Inventory == 'ox_inventory' then
        TriggerServerEvent('ak47_bridge:registeroxinventory', identifier, {weight = weight, slots = slots}, uid)
        exports["ox_inventory"]:openInventory('stash', identifier)
    elseif Config.Inventory == 'qs-inventory' then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", identifier, {maxweight = weight, slots = slots})
        TriggerEvent("inventory:client:SetCurrentStash", identifier)
    elseif Config.Inventory == 'cheeza_inventory' then
        TriggerEvent('inventory:openHouse', name, identifier, "Stash", weight)
    elseif Config.Inventory == 'core_inventory' then
        TriggerServerEvent('core_inventory:server:openInventory', identifier, 'stash')
    elseif Config.Inventory == 'codem-inventory' then
        TriggerServerEvent('codem-inventory:server:openstash', identifier, slots, weight, identifier)
    end
end

Bridge.CloseInventory = function()
    if Config.Inventory == 'ak47_inventory' then
        exports['ak47_inventory']:CloseInventory()
    elseif Config.Inventory == 'ak47_qb_inventory' then
        exports['ak47_qb_inventory']:CloseInventory()
    elseif Config.Inventory == 'ox_inventory' then
        exports['ox_inventory']:closeInventory()
    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent('ak47_bridge:closeqbinventory')
    elseif Config.Inventory == 'cheeza_inventory' then
        exports['inventory']:CloseInventory()
    elseif Config.Inventory == 'core_inventory' then
        exports['core_inventory']:closeInventory()
    elseif Config.Inventory == 'codem-inventory' then
        -- unknown
    elseif Config.Inventory == 'qs-inventory' then
        -- unknown
    elseif Config.Inventory == 'qb-inventory-old' then
        -- unknown
    elseif Config.Inventory == 'ps-inventory' then
        -- unknown
    elseif Config.Inventory == 'lj-inventory' then
        -- unknown
    end
end