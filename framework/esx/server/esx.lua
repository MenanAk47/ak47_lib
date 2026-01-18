if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()
Bridge = {}
Integration = {}

-- ====================================================================================
--                                    CORE PLAYER
-- ====================================================================================

Bridge.GetPlayer = function(source)
	return ESX.GetPlayerFromId(source)
end

Bridge.GetSource = function(xPlayer)
	return xPlayer.source
end

Bridge.GetSourceFromIdentifier = function(identifier)
	local xPlayer = Bridge.GetPlayerFromIdentifier(identifier)
	return xPlayer and xPlayer.source
end

Bridge.GetPlayerFromIdentifier = function(identifier)
	return ESX.GetPlayerFromIdentifier(identifier)
end

Bridge.GetIdentifier = function(source)
	local xPlayer = Bridge.GetPlayer(source)
	return xPlayer.identifier
end

Bridge.GetIdentifierByType = function(playerId, idtype)
    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

Bridge.GetLicense = function( source )
	return Bridge.GetIdentifierByType(source, 'license')
end

-- ====================================================================================
--                                IDENTITY & METADATA
-- ====================================================================================

Bridge.GetName = function(source)
	local identifier = Bridge.GetIdentifier(source)
	local namedb = MySQL.Sync.fetchAll('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {identifier})
    local name = namedb[1].firstname or ''
    name = namedb[1].lastname and name..' '..namedb[1].lastname or ''
    return name
end

Bridge.GetNameFromIdentifier = function(identifier)
	local namedb = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
    local name = namedb[1].firstname or ''
    name = namedb[1].lastname and name..' '..namedb[1].lastname or ''
    return name
end

Bridge.GetPhoneNumber = function(source)
	local identifier = Bridge.GetIdentifier(source)
	local result = MySQL.Sync.fetchAll('SELECT phone_number FROM users WHERE identifier = ?', {identifier})
    return result and result[1] and result[1].phone_number
end

Bridge.GetPlayerMetaValue = function(source, type)
	local xPlayer = Bridge.GetPlayer(source)
	return xPlayer.getMeta(type)
end

Bridge.SetPlayerMetaValue = function(source, type, val)
	local xPlayer = Bridge.GetPlayer(source)
	return xPlayer.setMeta(type, val)
end

-- ====================================================================================
--                                   JOB, GANG & ADMIN
-- ====================================================================================

-- returns data in qb format to maintain consistency
Bridge.GetJob = function(source)
	local xPlayer = Bridge.GetPlayer(source)
	if not xPlayer then return nil end

	local job = {}
    job.name = xPlayer.job.name
    job.label = xPlayer.job.label
    job.payment = xPlayer.job.grade_salary
    job.isboss = xPlayer.job.grade_name == 'boss'

    job.grade = {}
    job.grade.name = xPlayer.job.grade_label
    job.grade.level = xPlayer.job.grade

	return job
end

Bridge.SetJob = function(source, job, grade)
    local xPlayer = Bridge.GetPlayer(source)
    if xPlayer then
        xPlayer.setJob(job, grade)
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
	local account = account == 'cash' and 'money' or account
	local xPlayer = Bridge.GetPlayer(source)
	return xPlayer.getAccount(account).money
end

Bridge.AddMoney = function(source, account, amount)
	local account = account == 'cash' and 'money' or account
	local xPlayer = Bridge.GetPlayer(source)
	xPlayer.addAccountMoney(account, amount)
end

Bridge.RemoveMoney = function(source, account, amount)
	local account = account == 'cash' and 'money' or account
	local xPlayer = Bridge.GetPlayer(source)
	xPlayer.removeAccountMoney(account, amount)
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
--                                    INVENTORY
-- ====================================================================================

Bridge.GetInventoryItems = function(inventoryId)
    return Integration.GetInventoryItems(inventoryId)
end

Bridge.GetItems = function()
	if GetResourceState('qs-inventory') == 'started' then
		return exports['qs-inventory']:GetItemList()
	elseif GetResourceState('ox_inventory') == 'started' then
		return exports['ox_inventory']:Items()
	else
		return exports['es_extended']:getSharedObject().Items
	end
end

Bridge.GetItemLabel = function(item)
	local items = Bridge.GetItems()
    if items and items[item] then
	   return items[item].label
    else
        print('^1Item: ^3['..item..']^1 missing^0')
        return item
    end
end

Bridge.GetInventoryItem = function(source, item)
	local xPlayer = Bridge.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and inv.count or 0
end

Bridge.GetItemAmount = function(source, item)
	local xPlayer = Bridge.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and (inv.amount or inv.count) or 0
end

Bridge.HasEnoughItem = function(source, item, amount)
	local xPlayer = Bridge.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and ((inv.count and inv.count >= amount) or (inv.amount and inv.amount >= amount)) or false
end

Bridge.CanCarryItem = function(source, item, amount)
	local xPlayer = Bridge.GetPlayer(source)
	if xPlayer.canCarryItem then
		return xPlayer.canCarryItem(item, amount)
	else
		return true
	end
end

Bridge.AddItem = function(source, item, amount, slot, meta)
	return Integration.AddItem(source, item, amount, slot, meta)
end

Bridge.RemoveItem = function(source, item, amount)
	local xPlayer = Bridge.GetPlayer(source)
	return xPlayer.removeInventoryItem(item, amount)
end

Bridge.CreateUseableItem = ESX.RegisterUsableItem

-- ====================================================================================
--                                    VEHICLES
-- ====================================================================================

Bridge.Vehicles = {}

Bridge.IsVehicleOwner = function(source, plate)
	local identifier = Bridge.GetIdentifier(source)
    local found = MySQL.Sync.fetchScalar('SELECT 1 FROM owned_vehicles WHERE `owner` = ? AND `plate` = ?', {identifier, plate})
    return found and found > 0
end

Bridge.GetVehicleOwner = function(plate)
    local found = MySQL.Sync.fetchAll('SELECT owner FROM owned_vehicles WHERE `plate` = ?', {plate})
    return found and found[1] and found[1].owner
end

-- Format Syntax: "A" = Letter, "1" = Number. 
-- Anything else (spaces, dashes) is kept as-is.
Bridge.GeneratePlate = function(format, prefix)
    local pattern = format or "AAAA 11A"
    local plate = ""
    
    if prefix then 
        plate = tostring(prefix) 
    end

    for i = 1, #pattern do
        local c = pattern:sub(i, i) -- Get character at current position
        if c == 'A' then
            plate = plate .. string.char(math.random(65, 90))
        elseif c == '1' then
            plate = plate .. math.random(0, 9)
        else
            plate = plate .. c 
        end
    end

    plate = plate:upper()

    local result = MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ?', { plate })

    if result then
        return Bridge.GeneratePlate(format, prefix)
    else
        return plate
    end
end

Bridge.GiveVehicle = function( source, model )
	local identifier = Bridge.GetIdentifier(source)
	local plate = Bridge.GeneratePlate("AAAA 11A")

    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
    {
        ['@owner']      = identifier,
        ['@plate']      = plate,
        ['@vehicle']    = json.encode({model = GetHashKey(model), plate = plate}),
    })
end

-- ====================================================================================
--                                     UTILS
-- ====================================================================================

Bridge.Notify = function(source, msg, type, duration)
	TriggerClientEvent('ak47_bridge:client:Notify', source, msg, type, duration)
end

-- ====================================================================================
--                                THREADS & EXPORTS
-- ====================================================================================

Citizen.CreateThread(function()
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM vehicles')
    if vehicles then
    	for i, v in pairs(vehicles) do
        	Bridge.Vehicles[GetHashKey(v.model)] = v.name
        end
    else
        print('^1Vehicle table not found!^0')
    end
end)

lib.callback.register('ak47_bridge:callback:server:GetTargetMetaValue', function( source, target, type )
    return Bridge.GetPlayerMetaValue(target, type)
end)

exports('GetBridge', function()
	return Bridge
end)