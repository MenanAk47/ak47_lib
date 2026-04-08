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

                if Config.Inventory == 'qb-inventory' then
                    RegisterNetEvent('ak47_lib:closeqbinventory', function()
                        local source = source
                        exports['qb-inventory']:CloseInventory(source, Lib47.GetIdentifier(source))
                    end)

                    RegisterNetEvent('ak47_lib:openqbinventory', function(target)
                        exports['qb-inventory']:OpenInventoryById(source, target)
                    end)

                    RegisterNetEvent('ak47_lib:OpenQbStash', function(identifier, data)
                        exports["qb-inventory"]:OpenInventory(source, identifier, data)
                    end)
                elseif Config.Inventory == 'ox_inventory' then
                    RegisterNetEvent('ak47_lib:registeroxinventory', function(identifier, data)
                        exports["ox_inventory"]:RegisterStash(identifier, identifier, data.slots, data.weight * 1000)
                    end)
                end

                print(string.format("^2['INVENTORY']: %s^0", Config.Inventory))
                return
            end
        end
    end)
end

Integration.GetItems = function()
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:Items()

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:Items()

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:Items()

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:GetItemList()

    -- elseif Config.Inventory == 'ps-inventory' then
    --     return exports['ps-inventory']:Items()

    -- elseif Config.Inventory == 'lj-inventory' then
    --     return exports['lj-inventory']:Items()

    -- elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
    --     return exports['qb-inventory']:Items()

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:GetItemList()

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:Items()

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:Items()


    -- add your inventory support above this code
    elseif Config.Framework == 'esx' then
        return ESX.GetItems()
    elseif Config.Framework == 'qb' then
        return QBCore.Shared.Items
    end
end

Integration.AddItem = function(source, item, amount, slot, meta)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:AddItem(source, item, amount, meta, slot)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ps-inventory' then
        return exports['ps-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'lj-inventory' then
        return exports['lj-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        return exports['qb-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:AddItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:AddItem(source, item, amount, slot, meta)


    -- add your inventory support above this code
    elseif Config.Framework == 'esx' then
        local xPlayer = Lib47.GetPlayer(source)
        return xPlayer.addInventoryItem(item, amount)
    elseif Config.Framework == 'qb' then
        local Player = Lib47.GetPlayer(source)
        return Player.Functions.AddItem(item, amount, slot, meta)
    end
end

Integration.RemoveItem = function(source, item, amount, slot, meta)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(source, item, amount, meta, slot)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'ps-inventory' then
        return exports['ps-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'lj-inventory' then
        return exports['lj-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        return exports['qb-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:RemoveItem(source, item, amount, slot, meta)

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:RemoveItem(source, item, amount, slot, meta)


    -- add your inventory support above this code
    elseif Config.Framework == 'esx' then
        local xPlayer = Lib47.GetPlayer(source)
        return xPlayer.removeInventoryItem(item, amount)
    elseif Config.Framework == 'qb' then
        local Player = Lib47.GetPlayer(source)
        return Player.Functions.RemoveItem(item, amount, slot, meta)
    end
end

Integration.GetInventoryItems = function(inventoryId)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:GetInventoryItems(inventoryId)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:GetInventoryItems(inventoryId)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:GetInventoryItems(inventoryId)

    elseif Config.Inventory == 'qs-inventory' then
        local inventory = exports['qs-inventory']:GetInventory(inventoryId)
        return inventory and inventory.items or {}

    elseif Config.Inventory == 'ps-inventory' then
        local inventory = exports['qb-inventory']:GetInventory(inventoryId)
        return inventory and inventory.items or {}

    elseif Config.Inventory == 'lj-inventory' then
        local inventory = exports['lj-inventory']:GetInventory(inventoryId)
        return inventory and inventory.items or {}

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        local inventory = exports['qb-inventory']:GetInventory(inventoryId)
        return inventory and inventory.items or {}

    elseif Config.Inventory == 'codem-inventory' then
        if Lib47.GetPlayer(inventoryId) then
            local inventory = exports['codem-inventory']:GetInventory(inventoryId, inventoryId)
            return inventory and inventory.items or {}
        else
            return exports['codem-inventory']:GetStashItems(inventoryId)
        end

    elseif Config.Inventory == 'tgiann-inventory' then
        if Lib47.GetPlayer(inventoryId) then
            return exports["tgiann-inventory"]:GetPlayerItems(inventoryId)
        else
            local inventory = exports["tgiann-inventory"]:GetInventory(inventoryId, "stash")
            return inventory and inventory.items or {}
        end

    elseif Config.Inventory == 'origen_inventory' then
        return exports.origen_inventory:getInventoryItems(inventoryId)


    -- add your inventory support above this code
    elseif Config.Framework == 'esx' then
        local xPlayer = Lib47.GetPlayer(source)
        return xPlayer.getInventory()

    elseif Config.Framework == 'qb' then
        local Player = Lib47.GetPlayer(source)
        return Player.PlayerData.items
    end
end
