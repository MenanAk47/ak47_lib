if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()

-- ====================================================================================
--                                    CORE PLAYER
-- ====================================================================================

Lib47.GetPlayer = function(source)
	return ESX.GetPlayerFromId(source)
end

Lib47.GetSource = function(xPlayer)
	return xPlayer.source
end

Lib47.GetSourceFromIdentifier = function(identifier)
	local xPlayer = Lib47.GetPlayerFromIdentifier(identifier)
	return xPlayer and xPlayer.source
end

Lib47.GetPlayerFromIdentifier = function(identifier)
	return ESX.GetPlayerFromIdentifier(identifier)
end

Lib47.GetIdentifier = function(source)
	local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.identifier
end

Lib47.GetIdentifierByType = function(playerId, idtype)
    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

Lib47.GetLicense = function( source )
	return Lib47.GetIdentifierByType(source, 'license')
end

-- ====================================================================================
--                                IDENTITY & METADATA
-- ====================================================================================

Lib47.GetName = function(source)
	local identifier = Lib47.GetIdentifier(source)
	local namedb = MySQL.Sync.fetchAll('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', {identifier})
    local name = namedb[1].firstname or ''
    name = namedb[1].lastname and name..' '..namedb[1].lastname or ''
    return name
end

Lib47.GetNameFromIdentifier = function(identifier)
	local namedb = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
    local name = namedb[1].firstname or ''
    name = namedb[1].lastname and name..' '..namedb[1].lastname or ''
    return name
end

Lib47.GetPhoneNumber = function(source)
	local identifier = Lib47.GetIdentifier(source)
	local result = MySQL.Sync.fetchAll('SELECT phone_number FROM users WHERE identifier = ?', {identifier})
    return result and result[1] and result[1].phone_number
end

Lib47.GetPlayerMetaValue = function(source, type)
	local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.getMeta(type)
end

Lib47.SetPlayerMetaValue = function(source, type, val)
	local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.setMeta(type, val)
end

-- ====================================================================================
--                                   JOB, GANG & ADMIN
-- ====================================================================================

-- returns data in qb format to maintain consistency
Lib47.GetJob = function(source)
	local xPlayer = Lib47.GetPlayer(source)
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

Lib47.SetJob = function(source, job, grade)
    local xPlayer = Lib47.GetPlayer(source)
    if xPlayer then
        xPlayer.setJob(job, grade)
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
	local account = account == 'cash' and 'money' or account
	local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.getAccount(account).money
end

Lib47.AddMoney = function(source, account, amount)
	local account = account == 'cash' and 'money' or account
	local xPlayer = Lib47.GetPlayer(source)
	xPlayer.addAccountMoney(account, amount)
end

Lib47.RemoveMoney = function(source, account, amount)
	local account = account == 'cash' and 'money' or account
	local xPlayer = Lib47.GetPlayer(source)
	xPlayer.removeAccountMoney(account, amount)
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
--                                    INVENTORY
-- ====================================================================================

Lib47.GetInventoryItems = function(inventoryId)
    return Integration.GetInventoryItems(inventoryId)
end

Lib47.GetItems = function()
	if GetResourceState('qs-inventory') == 'started' then
		return exports['qs-inventory']:GetItemList()
	elseif GetResourceState('ox_inventory') == 'started' then
		return exports['ox_inventory']:Items()
	else
		return exports['es_extended']:getSharedObject().Items
	end
end

Lib47.GetItemLabel = function(item)
	local items = Lib47.GetItems()
    if items and items[item] then
	   return items[item].label
    else
        print('^1Item: ^3['..item..']^1 missing^0')
        return item
    end
end

Lib47.GetInventoryItem = function(source, item)
	local xPlayer = Lib47.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and inv.count or 0
end

Lib47.GetItemAmount = function(source, item)
	local xPlayer = Lib47.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and (inv.amount or inv.count) or 0
end

Lib47.HasEnoughItem = function(source, item, amount)
	local xPlayer = Lib47.GetPlayer(source)
	local inv = xPlayer.getInventoryItem(item)
	return inv and ((inv.count and inv.count >= amount) or (inv.amount and inv.amount >= amount)) or false
end

Lib47.CanCarryItem = function(source, item, amount)
	local xPlayer = Lib47.GetPlayer(source)
	if xPlayer.canCarryItem then
		return xPlayer.canCarryItem(item, amount)
	else
		return true
	end
end

Lib47.AddItem = function(source, item, amount, slot, meta)
	return Integration.AddItem(source, item, amount, slot, meta)
end

Lib47.RemoveItem = function(source, item, amount)
	local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.removeInventoryItem(item, amount)
end

Lib47.CreateUseableItem = ESX.RegisterUsableItem

-- ====================================================================================
--                                    VEHICLES
-- ====================================================================================

Lib47.Vehicles = {}

Lib47.IsVehicleOwner = function(source, plate)
	local identifier = Lib47.GetIdentifier(source)
    local found = MySQL.Sync.fetchScalar('SELECT 1 FROM owned_vehicles WHERE `owner` = ? AND `plate` = ?', {identifier, plate})
    return found and found > 0
end

Lib47.GetVehicleOwner = function(plate)
    local found = MySQL.Sync.fetchAll('SELECT owner FROM owned_vehicles WHERE `plate` = ?', {plate})
    return found and found[1] and found[1].owner
end

-- Format Syntax: "A" = Letter, "1" = Number. 
-- Anything else (spaces, dashes) is kept as-is.
Lib47.GeneratePlate = function(format, prefix)
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
        return Lib47.GeneratePlate(format, prefix)
    else
        return plate
    end
end

Lib47.GiveVehicle = function( source, model )
	local identifier = Lib47.GetIdentifier(source)
	local plate = Lib47.GeneratePlate("AAAA 11A")

    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
    {
        ['@owner']      = identifier,
        ['@plate']      = plate,
        ['@vehicle']    = json.encode({model = GetHashKey(model), plate = plate}),
    })
end

-- ====================================================================================
--                                THREADS & EXPORTS
-- ====================================================================================

Citizen.CreateThread(function()
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM vehicles')
    if vehicles then
    	for i, v in pairs(vehicles) do
        	Lib47.Vehicles[GetHashKey(v.model)] = v.name
        end
    else
        print('^1Vehicle table not found!^0')
    end
end)