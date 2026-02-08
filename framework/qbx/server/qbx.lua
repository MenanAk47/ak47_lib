if Config.Framework == 'auto' and GetResourceState('qbx_core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qbx' then return end
Config.Framework = 'qbx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

-- ====================================================================================
--                                    CORE PLAYER
-- ====================================================================================

Lib47.GetPlayer = function(source)
    return exports.qbx_core:GetPlayer(source)
end

Lib47.GetSource = function(Player)
    return Player.PlayerData.source
end

Lib47.GetSourceFromIdentifier = function(identifier)
    local Player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    return Player and Player.PlayerData.source
end

Lib47.GetPlayerFromIdentifier = function(identifier)
    return exports.qbx_core:GetPlayerByCitizenId(identifier)
end

Lib47.GetIdentifier = function(source)
    local Player = Lib47.GetPlayer(source)
    return Player and Player.PlayerData.citizenid
end

Lib47.GetIdentifierByType = function(source, idtype)
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

Lib47.GetLicense = function(source)
    return Lib47.GetIdentifierByType(source, 'license')
end

-- ====================================================================================
--                                IDENTITY & METADATA
-- ====================================================================================

Lib47.GetName = function(source)
    local Player = Lib47.GetPlayer(source)
    if Player then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
    return ''
end

Lib47.GetNameFromIdentifier = function(identifier)
    local result = MySQL.Sync.fetchAll('SELECT charinfo FROM players WHERE citizenid = ?', {identifier})
    if result and result[1] then
        local charinfo = json.decode(result[1].charinfo)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
    return ''
end

Lib47.GetPhoneNumber = function(source)
    local Player = Lib47.GetPlayer(source)
    return Player and Player.PlayerData.charinfo.phone
end

Lib47.GetPlayerMetaValue = function(source, type)
    local Player = Lib47.GetPlayer(source)
    return Player and Player.PlayerData.metadata[type]
end

Lib47.SetPlayerMetaValue = function(source, type, val)
    local Player = Lib47.GetPlayer(source)
    if Player then
        Player.Functions.SetMetaData(type, val)
    end
end

-- ====================================================================================
--                                   JOB, GANG & ADMIN
-- ====================================================================================

Lib47.GetJob = function(source)
    local Player = Lib47.GetPlayer(source)
    return Player and Player.PlayerData.job
end

Lib47.SetJob = function(source, job, grade)
    local Player = Lib47.GetPlayer(source)
    if Player then
        Player.Functions.SetJob(job, grade)
    end
end

Lib47.GetGang = function(source)
    return Integration.GetGang(source)
end

Lib47.SetGang = function(source, gang, grade)
    Integration.SetGang(source, gang, grade)
end

Lib47.IsAdmin = function(source)
    return IsPlayerAceAllowed(source, 'command')
end

-- ====================================================================================
--                                     ECONOMY
-- ====================================================================================

Lib47.GetMoney = function(source, account)
    local Player = Lib47.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    return Player.Functions.GetMoney(type)
end

Lib47.AddMoney = function(source, account, amount)
    local Player = Lib47.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    Player.Functions.AddMoney(type, amount)
end

Lib47.RemoveMoney = function(source, account, amount)
    local Player = Lib47.GetPlayer(source)
    local type = account == 'money' and 'cash' or account
    Player.Functions.RemoveMoney(type, amount)
end

Lib47.AddSocietyMoney = function(job, money)
    Integration.AddSocietyMoney(job, money)
end

Lib47.RemoveSocietyMoney = function(job, money)
    Integration.RemoveSocietyMoney(job, money)
end

Lib47.GetSocietyMoney = function(job)
    return Integration.GetSocietyMoney(job)
end

-- ====================================================================================
--                                INVENTORY
--                          (Strictly Ox Inventory)
-- ====================================================================================

Lib47.GetInventoryItems = function(inventoryId)
    return exports.ox_inventory:GetInventoryItems(inventoryId)
end

Lib47.GetItems = function()
    return exports.ox_inventory:Items()
end

Lib47.GetItemLabel = function(item)
    local items = Lib47.GetItems()
    if items[item] then
        return items[item].label
    else
        return item
    end
end

Lib47.GetInventoryItem = function(source, item)
    local itemData = exports.ox_inventory:GetItem(source, item, nil, false)
    return itemData and itemData.count or 0
end

Lib47.GetItemAmount = function(source, item)
    return Lib47.GetInventoryItem(source, item)
end

Lib47.HasEnoughItem = function(source, item, amount)
    local count = Lib47.GetInventoryItem(source, item)
    return count >= amount
end

Lib47.CanCarryItem = function(source, item, amount)
    return exports.ox_inventory:CanCarryItem(source, item, amount)
end

Lib47.AddItem = function(source, item, amount, slot, meta)
    return exports.ox_inventory:AddItem(source, item, amount, meta, slot)
end

Lib47.RemoveItem = function(source, item, amount)
    return exports.ox_inventory:RemoveItem(source, item, amount)
end

Lib47.CreateUseableItem = function(item, cb)
    exports.qbx_core:CreateUseableItem(item, cb)
end

-- ====================================================================================
--                                    VEHICLES
-- ====================================================================================

Lib47.Vehicles = {}

Lib47.IsVehicleOwner = function(source, plate)
    local citizenid = Lib47.GetIdentifier(source)
    local result = MySQL.Sync.fetchScalar('SELECT 1 FROM player_vehicles WHERE `citizenid` = ? AND `plate` = ?', {citizenid, plate})
    return result and result > 0
end

Lib47.GetVehicleOwner = function(plate)
    local result = MySQL.Sync.fetchAll('SELECT citizenid FROM player_vehicles WHERE `plate` = ?', {plate})
    return result and result[1] and result[1].citizenid
end

Lib47.GeneratePlate = function(format, prefix)
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
        return Lib47.GeneratePlate(format, prefix)
    else
        return plate
    end
end

Lib47.GiveVehicle = function(source, model)
    local citizenid = Lib47.GetIdentifier(source)
    local plate = Lib47.GeneratePlate("AAAA 11A")
    local hash = GetHashKey(model)
    
    MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)',
    {
        Lib47.GetLicense(source),
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
            Lib47.Vehicles[GetHashKey(v.model)] = v.name
        end
    end
end)