if Config.Framework == 'auto' and GetResourceState('qbx_core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qbx' then return end
Config.Framework = 'qbx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

-- ====================================================================================
--                                    CORE PLAYER
-- ====================================================================================

Bridge.GetPlayer = function(source)
    return exports.qbx_core:GetPlayer(source)
end

Bridge.GetSource = function(Player)
    return Player.PlayerData.source
end

Bridge.GetSourceFromIdentifier = function(identifier)
    local Player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    return Player and Player.PlayerData.source
end

Bridge.GetPlayerFromIdentifier = function(identifier)
    return exports.qbx_core:GetPlayerByCitizenId(identifier)
end

Bridge.GetIdentifier = function(source)
    local Player = Bridge.GetPlayer(source)
    return Player and Player.PlayerData.citizenid
end

Bridge.GetIdentifierByType = function(source, idtype)
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

Bridge.GetLicense = function(source)
    return Bridge.GetIdentifierByType(source, 'license')
end

-- ====================================================================================
--                                IDENTITY & METADATA
-- ====================================================================================

Bridge.GetName = function(source)
    local Player = Bridge.GetPlayer(source)
    if Player then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
    return ''
end

Bridge.GetNameFromIdentifier = function(identifier)
    local result = MySQL.Sync.fetchAll('SELECT charinfo FROM players WHERE citizenid = ?', {identifier})
    if result and result[1] then
        local charinfo = json.decode(result[1].charinfo)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
    return ''
end

Bridge.GetPhoneNumber = function(source)
    local Player = Bridge.GetPlayer(source)
    return Player and Player.PlayerData.charinfo.phone
end

Bridge.GetPlayerMetaValue = function(source, type)
    local Player = Bridge.GetPlayer(source)
    return Player and Player.PlayerData.metadata[type]
end

Bridge.SetPlayerMetaValue = function(source, type, val)
    local Player = Bridge.GetPlayer(source)
    if Player then
        Player.Functions.SetMetaData(type, val)
    end
end

-- ====================================================================================
--                                   JOB, GANG & ADMIN
-- ====================================================================================

Bridge.GetJob = function(source)
    local Player = Bridge.GetPlayer(source)
    return Player and Player.PlayerData.job
end

Bridge.SetJob = function(source, job, grade)
    local Player = Bridge.GetPlayer(source)
    if Player then
        Player.Functions.SetJob(job, grade)
    end
end

Bridge.GetGang = function(source)
    return Integration.GetGang(source)
end

Bridge.SetGang = function(source, gang, grade)
    Integration.SetGang(source, gang, grade)
end

Bridge.IsAdmin = function(source)
    return IsPlayerAceAllowed(source, 'command')
end

-- ====================================================================================
--                                     ECONOMY
-- ====================================================================================

Bridge.GetMoney = function(source, account)
    local Player = Bridge.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    return Player.Functions.GetMoney(type)
end

Bridge.AddMoney = function(source, account, amount)
    local Player = Bridge.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    Player.Functions.AddMoney(type, amount)
end

Bridge.RemoveMoney = function(source, account, amount)
    local Player = Bridge.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    Player.Functions.RemoveMoney(type, amount)
end

Bridge.AddSocietyMoney = function(job, money)
    Integration.AddSocietyMoney(job, money)
end

Bridge.RemoveSocietyMoney = function(job, money)
    Integration.RemoveSocietyMoney(job, money)
end

Bridge.GetSocietyMoney = function(job)
    return Integration.GetSocietyMoney(job)
end

-- ====================================================================================
--                                INVENTORY
--                          (Strictly Ox Inventory)
-- ====================================================================================

Bridge.GetInventoryItems = function(inventoryId)
    return exports.ox_inventory:GetInventoryItems(inventoryId)
end

Bridge.GetItems = function()
    return exports.ox_inventory:Items()
end

Bridge.GetItemLabel = function(item)
    local items = Bridge.GetItems()
    if items[item] then
        return items[item].label
    else
        return item
    end
end

Bridge.GetInventoryItem = function(source, item)
    local itemData = exports.ox_inventory:GetItem(source, item, nil, false)
    return itemData and itemData.count or 0
end

Bridge.GetItemAmount = function(source, item)
    return Bridge.GetInventoryItem(source, item)
end

Bridge.HasEnoughItem = function(source, item, amount)
    local count = Bridge.GetInventoryItem(source, item)
    return count >= amount
end

Bridge.CanCarryItem = function(source, item, amount)
    return exports.ox_inventory:CanCarryItem(source, item, amount)
end

Bridge.AddItem = function(source, item, amount, slot, meta)
    return exports.ox_inventory:AddItem(source, item, amount, meta, slot)
end

Bridge.RemoveItem = function(source, item, amount)
    return exports.ox_inventory:RemoveItem(source, item, amount)
end

Bridge.CreateUseableItem = function(item, cb)
    exports.qbx_core:CreateUseableItem(item, cb)
end

-- ====================================================================================
--                                    VEHICLES
-- ====================================================================================

Bridge.Vehicles = {}

Bridge.IsVehicleOwner = function(source, plate)
    local citizenid = Bridge.GetIdentifier(source)
    local result = MySQL.Sync.fetchScalar('SELECT 1 FROM player_vehicles WHERE `citizenid` = ? AND `plate` = ?', {citizenid, plate})
    return result and result > 0
end

Bridge.GetVehicleOwner = function(plate)
    local result = MySQL.Sync.fetchAll('SELECT citizenid FROM player_vehicles WHERE `plate` = ?', {plate})
    return result and result[1] and result[1].citizenid
end

Bridge.GeneratePlate = function(format, prefix)
    local pattern = format or "AAAA 11A"
    local plate = ""
    
    if prefix then 
        plate = tostring(prefix) 
    end

    for i = 1, #pattern do
        local c = pattern:sub(i, i)
        if c == 'A' then
            plate = plate .. string.char(math.random(65, 90))
        elseif c == '1' then
            plate = plate .. math.random(0, 9)
        else
            plate = plate .. c 
        end
    end

    plate = plate:upper()

    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })

    if result then
        return Bridge.GeneratePlate(format, prefix)
    else
        return plate
    end
end

Bridge.GiveVehicle = function(source, model)
    local citizenid = Bridge.GetIdentifier(source)
    local plate = Bridge.GeneratePlate("AAAA 11A")
    local hash = GetHashKey(model)
    
    MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)',
    {
        Bridge.GetLicense(source),
        citizenid,
        model,
        hash,
        json.encode({plate = plate, model = hash}),
        plate,
        1 
    })
end

-- ====================================================================================
--                                THREADS & EXPORTS
-- ====================================================================================

Citizen.CreateThread(function()
    local sharedVehicles = exports.qbx_core:GetVehiclesByName()
    if sharedVehicles then
        for k, v in pairs(sharedVehicles) do
            Bridge.Vehicles[GetHashKey(v.model)] = v.name
        end
    end
end)