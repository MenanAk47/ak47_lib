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
                RegisterInventoryEvents()
                return
            end
        end
    end)
end

Lib47.SetInventoryBusy = function(state)
    LocalPlayer.state:set('invBusy', state, true)
    LocalPlayer.state:set('inv_busy', state, true)
end

Lib47.OpenSearchInventory = function(targetServerId)
    if Config.Inventory == 'ak47_inventory' then
        exports['ak47_inventory']:OpenInventory(targetServerId)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        exports['ak47_qb_inventory']:OpenInventory(targetServerId)

    elseif Config.Inventory == 'ox_inventory' then
        exports['ox_inventory']:openInventory('player', targetServerId)

    elseif Config.Inventory == 'qs-inventory' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", targetServerId)

    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent('ak47_lib:openqbinventory', targetServerId)

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

Lib47.OpenStash = function(identifier, name, weight, slots)
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

    elseif Config.Inventory == 'lj-inventory' then
        TriggerServerEvent("lj-inventory:server:OpenInventory", "stash", identifier, {maxweight = weight * 1000, slots = slots})
        TriggerEvent("lj-inventory:client:SetCurrentStash", identifier)

    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent("ak47_qb_policejob:OpenQbStash", identifier, {maxweight = weight * 1000, slots = slots, label = name})

    elseif Config.Inventory == 'ox_inventory' then
        TriggerServerEvent('ak47_lib:registeroxinventory', identifier, {weight = weight, slots = slots}, uid)
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

Lib47.CloseInventory = function()
    if Config.Inventory == 'ak47_inventory' then
        exports['ak47_inventory']:CloseInventory()

    elseif Config.Inventory == 'ak47_qb_inventory' then
        exports['ak47_qb_inventory']:CloseInventory()

    elseif Config.Inventory == 'ox_inventory' then
        exports['ox_inventory']:closeInventory()

    elseif Config.Inventory == 'qb-inventory' then
        TriggerServerEvent('ak47_lib:closeqbinventory')

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

Lib47.GetInventoryImageLink = function()
    if Config.Inventory == 'ak47_inventory' then
        return "nui://ak47_inventory/web/build/images/"

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return "nui://ak47_qb_inventory/web/build/images/"

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        return "nui://qb-inventory/html/images/"

    elseif Config.Inventory == 'ps-inventory' then
        return "nui://ps-inventory/html/images/"

    elseif Config.Inventory == 'ox_inventory' then
        return "nui://ox_inventory/web/images/"

    elseif Config.Inventory == 'qs-inventory' then
        return "nui://qs-inventory/html/images/"

    elseif Config.Inventory == 'cheeza_inventory' then
        return "nui://cheeza_inventory/html/images/" -- not sure

    elseif Config.Inventory == 'core_inventory' then
        return "nui://core_inventory/html/images/" -- not sure

    elseif Config.Inventory == 'codem-inventory' then
        return "nui://codem-inventory/html/images/" -- not sure
    end
end

Lib47.GetItemImageLink = function(name, format)
    if not name then
        print("^1Image link requested but no item name was provided!^0")
        return 
    end
    return Lib47.GetInventoryImageLink() .. name .. (format or '.png')
end

RegisterInventoryEvents = function()
    if Config.Inventory == 'ak47_inventory' or Config.Inventory == 'ak47_qb_inventory' then
        RegisterNetEvent('ak47_inventory:onRemoveItem', function(item, amount, slot, has)
            TriggerEvent('ak47_lib:OnRemoveItem', item, has)
            TriggerEvent('ak47_bridge:OnRemoveItem', item, has) -- will be removed soon
        end)
    elseif Config.Framework == 'esx' then
        RegisterNetEvent('esx:removeInventoryItem', function(item, count)
            TriggerEvent('ak47_lib:OnRemoveItem', item, count)
            TriggerEvent('ak47_bridge:OnRemoveItem', item, count) -- will be removed soon
        end)
    end
    -- other detections are based on framework data set
    -- check client/functions.lua
end