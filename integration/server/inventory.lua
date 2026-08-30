Lib47.ItemsReady = false
Lib47.Items = {}
Lib47.ItemsByHash = {}
Lib47.Weapons = {}

local function WaitForItems(callback)
    CreateThread(function()
        local stableTicks = 0
        local previousCount = -1
        local timeout = 0
        local maxWaitTime = 40 -- 40 * 500ms = 20 seconds maximum wait time

        print("^3['INVENTORY']: Waiting for inventory to finish initializing items...^0")

        while timeout < maxWaitTime do
            Wait(500)
            
            local items = Integration.GetItems()
            local currentCount = 0

            if items and type(items) == 'table' then
                for _ in pairs(items) do
                    currentCount = currentCount + 1
                end
            end

            if currentCount > 0 then
                if currentCount == previousCount then
                    stableTicks = stableTicks + 1
                    if stableTicks >= 4 then
                        break
                    end
                else
                    stableTicks = 0
                    previousCount = currentCount
                end
            end

            timeout = timeout + 1
        end

        if timeout >= maxWaitTime then
            print("^1['INVENTORY']: Item loading wait timed out. Proceeding with fetched items anyway. Check your inventory script if items are missing.^0")
        end

        callback()
    end)
end

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
        'core_inventory',
        'jaksam_inventory',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                if script == 'ak47_qb_inventory' and Lib47.GetResourceVersion('ak47_qb_inventory') > 12.5 then
                    script = 'ak47_inventory'
                end

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

                WaitForItems(function()
                    FetchInvItems()
                end)
                return
            end
        end
    end)
else
    CreateThread(function()
        WaitForItems(function()
            FetchInvItems()
        end)
    end)
end

FetchInvItems = function()
    Lib47.Items = Integration.GetItems()
    local itemsCount, weaponsCount = 0, 0

    for i, v in pairs(Lib47.Items) do
        local name = v.name or i
        name = name:lower()
        local nameHash = GetHashKey(name)
        Lib47.ItemsByHash[nameHash] = v
        Lib47.ItemsByHash[nameHash].name = name
        if Lib47.IsItemTypeWeapon(name) then
            Lib47.Weapons[name] = v
            weaponsCount = weaponsCount + 1
        else
            itemsCount = itemsCount + 1
        end
    end

    print(string.format("^2['FRAMEWORK ITEMS']: x%s^0", itemsCount))
    print(string.format("^2['FRAMEWORK WEAPONS']: x%s^0", weaponsCount))

    Lib47.ItemsReady = true
end

Lib47.IsItemsReady = function()
    return Lib47.ItemsReady
end

Lib47.Callback.Register('ak47_lib:callback:getitems', function( source )
    return Lib47.Items
end)

Integration.GetItems = function()
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:Items()

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:Items()

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:Items()

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:GetItemList()

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

Integration.AddItem = function(inventoryId, item, amount, slot, meta)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:AddItem(inventoryId, item, amount, meta, slot)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ps-inventory' then
        return exports['ps-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'lj-inventory' then
        return exports['lj-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        return exports['qb-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:AddItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'core_inventory' then
        return exports['core_inventory']:addItem(inventoryId, item, amount, meta)

    elseif Config.Inventory == 'jaksam_inventory' then
        return exports['jaksam_inventory']:addItem(inventoryId, item, amount, meta)

    -- add your inventory support above this code
    elseif type(inventoryId) == 'number' and Lib47.GetPlayer(inventoryId) then
    
        if Config.Framework == 'esx' then
            local xPlayer = Lib47.GetPlayer(inventoryId)
            return xPlayer.addInventoryItem(item, amount)
        elseif Config.Framework == 'qb' then
            local Player = Lib47.GetPlayer(inventoryId)
            return Player.Functions.AddItem(item, amount, slot, meta)
        end
    else
        print('^1No supported inventory found for Integration.AddItem.^0')
        print('^3Please open a ticket in the Discord and submit a request with your inventory documentation link.^0')
        return false

    end
end

Integration.RemoveItem = function(inventoryId, item, amount, slot, meta)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(inventoryId, item, amount, meta, slot)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'ps-inventory' then
        return exports['ps-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'lj-inventory' then
        return exports['lj-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' then
        return exports['qb-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:RemoveItem(inventoryId, item, amount, slot, meta)

    elseif Config.Inventory == 'core_inventory' then
        return exports['core_inventory']:removeItem(inventoryId, item, amount)

    elseif Config.Inventory == 'jaksam_inventory' then
        return exports['jaksam_inventory']:removeItem(inventoryId, item, amount)

    -- add your inventory support above this code
    elseif type(inventoryId) == 'number' and Lib47.GetPlayer(inventoryId) then
    
        if Config.Framework == 'esx' then
            local xPlayer = Lib47.GetPlayer(inventoryId)
            return xPlayer.removeInventoryItem(item, amount)
        elseif Config.Framework == 'qb' then
            local Player = Lib47.GetPlayer(inventoryId)
            return Player.Functions.RemoveItem(item, amount, slot, meta)
        end
    else
        print('^1No supported inventory found for Integration.RemoveItem.^0')
        print('^3Please open a ticket in the Discord and submit a request with your inventory documentation link.^0')
        return false

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
        return inventory or {}

    elseif Config.Inventory == 'qb-inventory' then
        if tonumber(inventoryId) then
            local Player = Lib47.GetPlayer(tonumber(inventoryId))
            return Player and Player.PlayerData.items or {}
        else
            local inventory = exports['qb-inventory']:GetInventory(inventoryId)
            return inventory and inventory.items or {}
        end

    elseif Config.Inventory == 'codem-inventory' then
        if Lib47.GetPlayer(inventoryId) then
            local inventory = exports['codem-inventory']:GetInventory(Lib47.GetIdentifier(inventoryId), inventoryId)
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
    elseif type(inventoryId) == 'number' and Lib47.GetPlayer(inventoryId) then
    
        if Config.Framework == 'esx' then
            local xPlayer = Lib47.GetPlayer(inventoryId)
            return xPlayer.getInventory()

        elseif Config.Framework == 'qb' then
            local Player = Lib47.GetPlayer(inventoryId)
            return Player.PlayerData.items
        end
    else
        print('^1No supported inventory found for Integration.GetInventoryItems.^0')
        print('^3Please open a ticket in the Discord and submit a request with your inventory documentation link.^0')
        return {}

    end
end

Integration.CanCarryItem = function(inventoryId, item, amount)
    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:CanAddItem(inventoryId, item, amount)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:CanAddItem(inventoryId, item, amount)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:CanCarryItem(inventoryId, item, amount)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:CanCarryItem(inventoryId, item, amount)

    elseif Config.Inventory == 'codem-inventory' then
        return true -- unknown

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:CanCarryItem(inventoryId, item, amount)

    elseif Config.Inventory == 'origen_inventory' then
        return exports['origen_inventory']:canCarryItem(inventoryId, item, amount)

    elseif Config.Inventory == 'core_inventory' then
        return true -- unknown
        
    elseif Config.Inventory == 'jaksam_inventory' then
        return exports['jaksam_inventory']:canCarryItem(inventoryId, item, amount)

    -- add your inventory support above this code
    elseif Config.Framework == 'esx' then
        local xPlayer = Lib47.GetPlayer(inventoryId)
        if xPlayer and xPlayer.canCarryItem then
            return xPlayer.canCarryItem(item, amount)
        end
        return true
        
    elseif Config.Framework == 'qb' then
        local Player = Lib47.GetPlayer(inventoryId)
        if not Player then return false end

        local itemData = Lib47.GetItems()[item]
        if not itemData then return false end

        local itemWeight = (itemData.weight or 0) * amount
        local totalWeight = 0

        for i, v in pairs(Player.PlayerData.items) do
            if v.weight then
                local slotAmount = v.amount or v.count or 1
                totalWeight = totalWeight + (v.weight * slotAmount)
            end
        end

        local maxWeight = 120000 
        local coreConfig = Lib47.GetCoreConfig()
        if coreConfig and coreConfig.Player and coreConfig.Player.MaxWeight then
            maxWeight = coreConfig.Player.MaxWeight
        end

        return (totalWeight + itemWeight) <= maxWeight
    else
        print('^1No supported inventory found for Integration.CanCarryItem.^0')
        print('^3Please open a ticket in the Discord and submit a request with your inventory documentation link.^0')
        return false
    end
end

Lib47.GetWeaponNameFromHash = function( hash )
    return Lib47.ItemsByHash[hash] and Lib47.ItemsByHash[hash].name
end

Lib47.SetItemInfo = function(inventoryId, slot, meta)
    if not slot or not meta then return false end

    if Config.Inventory == 'ak47_inventory' then
        return exports['ak47_inventory']:SetItemInfo(inventoryId, slot, meta)

    elseif Config.Inventory == 'ak47_qb_inventory' then
        return exports['ak47_qb_inventory']:SetItemInfo(inventoryId, slot, meta)

    elseif Config.Inventory == 'ox_inventory' then
        return exports['ox_inventory']:SetMetadata(inventoryId, slot, meta)

    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:SetItemMetadata(inventoryId, slot, meta)

    elseif Config.Inventory == 'codem-inventory' then
        return exports['codem-inventory']:SetItemMetadata(inventoryId, slot, meta)

    elseif Config.Inventory == 'core_inventory' then
        return exports['core_inventory']:setMetadata(inventoryId, slot, meta)

    elseif Config.Inventory == 'tgiann-inventory' then
        return exports['tgiann-inventory']:UpdateItemMetadata(inventoryId, slot, meta)

    elseif Config.Inventory == 'ps-inventory' or Config.Inventory == 'lj-inventory' or Config.Inventory == 'qb-inventory' or Config.Inventory == 'qb-inventory-old' or Lib47.Framework == 'qb' then
        local Player = Lib47.GetPlayer(tonumber(inventoryId))
        if Player and Player.PlayerData and Player.PlayerData.items and Player.PlayerData.items[slot] then
            Player.PlayerData.items[slot].info = meta
            Player.Functions.SetPlayerData("items", Player.PlayerData.items)
            return true
        end
        return false

    else
        local items = Lib47.GetInventoryItems(inventoryId)
        local item = items and items[slot]
        if item and item.name then
            local amount = item.amount or item.count or 1
            if amount > 1 then
                Lib47.RemoveItem(inventoryId, item.name, 1, item.slot)
                Lib47.AddItem(inventoryId, item.name, 1, nil, meta)
            else
                Lib47.RemoveItem(inventoryId, item.name, 1, item.slot)
                Lib47.AddItem(inventoryId, item.name, 1, item.slot, meta)
            end
            return true
        end
        return false
    end
end