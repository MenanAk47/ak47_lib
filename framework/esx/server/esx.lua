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

Lib47.GetName = function(source) -- will be removed soon
	return Lib47.GetCharacterName(source)
end

Lib47.GetCharacterName = function(source)
	local xPlayer = Lib47.GetPlayer(source)
	if xPlayer and xPlayer.firstName and xPlayer.lastName then
		return xPlayer.firstName .. ' '.. xPlayer.lastName
	end
	local identifier = Lib47.GetIdentifier(source)
    return Lib47.GetNameFromIdentifier(identifier)
end

Lib47.GetNameFromIdentifier = function(identifier)
	local namedb = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
    if namedb and namedb[1] then
        local name = namedb[1].firstname or ''
        name = namedb[1].lastname and name..' '..namedb[1].lastname or name
        return name
    end
    return 'Unknown'
end

Lib47.GetPhoneNumber = function(source)
	local identifier = Lib47.GetIdentifier(source)
	local result = MySQL.Sync.fetchAll('SELECT phone_number FROM users WHERE identifier = ?', {identifier})
    return result and result[1] and result[1].phone_number
end

Lib47.GetMetaData = function(source, key)
    local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.getMeta(key)
end

Lib47.SetMetaData = function(source, key, value)
    local xPlayer = Lib47.GetPlayer(source)
	return xPlayer.setMeta(key, value)
end

Lib47.GetPlayerMetaValue = function(source, type) -- will be removed soon
    return Lib47.GetMetaData(source, type)
end

Lib47.SetPlayerMetaValue = function(source, type, val) -- will be removed soon
    Lib47.SetMetaData(source, type, val)
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

Lib47.HasGroupPermission = function(source, group)
	local xPlayer = Lib47.GetPlayer(source)
	if not xPlayer then return false end
	return xPlayer.getGroup() == group
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

Lib47.AddSocietyMoney = function(job, money, reason, ignoreBankingExport)
    Integration.AddSocietyMoney(job, money, reason, ignoreBankingExport)
end

Lib47.RemoveSocietyMoney = function(job, money, reason, ignoreBankingExport)
    Integration.RemoveSocietyMoney(job, money, reason, ignoreBankingExport)
end

Lib47.GetSocietyMoney = function(job, ignoreBankingExport)
    return Integration.GetSocietyMoney(job, ignoreBankingExport)
end

-- ====================================================================================
--                                OFFLINE DATA MANAGEMENT
-- ====================================================================================

Lib47.GetAllOfflinePlayers = function()
    local playersData = {}
    local results = MySQL.Sync.fetchAll('SELECT identifier, firstname, lastname, accounts, job FROM users', {})
    
    if results then
        for _, p in ipairs(results) do
            local accounts = json.decode(p.accounts or '{}')
            
            table.insert(playersData, {
                citizenid = p.identifier,
                charinfo = {
                    firstname = p.firstname or "Unknown",
                    lastname = p.lastname or ""
                },
                money = {
                    bank = accounts.bank or 0,
                    cash = accounts.money or accounts.cash or 0
                },
                job = {
                    name = p.job or "unemployed",
                    label = p.job or "Unemployed" 
                }
            })
        end
    end
    return playersData
end

Lib47.GetJobs = function()
    local formattedJobs = {}
    local rawJobs = {}

    if ESX.GetJobs then
        rawJobs = ESX.GetJobs()
    else
        local jobsResult = MySQL.Sync.fetchAll('SELECT * FROM jobs')
        local gradesResult = MySQL.Sync.fetchAll('SELECT * FROM job_grades')
        
        for _, job in ipairs(jobsResult) do
            rawJobs[job.name] = job
            rawJobs[job.name].grades = {}
        end
        for _, grade in ipairs(gradesResult) do
            if rawJobs[grade.job_name] then
                rawJobs[grade.job_name].grades[tostring(grade.grade)] = grade
            end
        end
    end

    for jobName, jobData in pairs(rawJobs) do
        local formattedGrades = {}
        
        if jobData.grades then
            for gradeIndex, gradeData in pairs(jobData.grades) do
                formattedGrades[tostring(gradeIndex)] = {
                    name = gradeData.label or gradeData.name,
                    payment = gradeData.salary or 0,
                    isboss = (gradeData.name == 'boss')
                }
            end
        end

        formattedJobs[jobName] = {
            label = jobData.label,
            defaultDuty = true,
            offDutyPay = false,
            grades = formattedGrades
        }
    end

    return formattedJobs
end

Lib47.GetOfflineMoney = function(identifier, account)
    local type = account == 'cash' and 'money' or account
    local result = MySQL.Sync.fetchAll('SELECT accounts FROM users WHERE identifier = ?', {identifier})
    if result and result[1] and result[1].accounts then
        local accounts = json.decode(result[1].accounts)
        if type(accounts) == "table" then
            return accounts[type] or 0
        end
    end
    return 0
end

Lib47.AddOfflineMoney = function(identifier, account, amount)
    local type = account == 'cash' and 'money' or account
    MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and result[1].accounts then
            local accounts = json.decode(result[1].accounts)
            if accounts and type(accounts) == "table" then
                accounts[type] = (accounts[type] or 0) + amount
                MySQL.Async.execute('UPDATE users SET accounts = ? WHERE identifier = ?', {json.encode(accounts), identifier})
            end
        end
    end)
end

Lib47.RemoveOfflineMoney = function(identifier, account, amount)
    local type = account == 'cash' and 'money' or account
    MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and result[1].accounts then
            local accounts = json.decode(result[1].accounts)
            if accounts and type(accounts) == "table" then
                accounts[type] = (accounts[type] or 0) - amount
                MySQL.Async.execute('UPDATE users SET accounts = ? WHERE identifier = ?', {json.encode(accounts), identifier})
            end
        end
    end)
end

Lib47.GetOfflineMetaData = function(identifier, key)
    local result = MySQL.Sync.fetchAll('SELECT metadata FROM users WHERE identifier = ?', {identifier})
    if result and result[1] and result[1].metadata then
        local metadata = json.decode(result[1].metadata)
        return metadata and metadata[key]
    end
    return nil
end

Lib47.SetOfflineMetaData = function(identifier, key, value)
    MySQL.Async.fetchAll('SELECT metadata FROM users WHERE identifier = ?', {identifier}, function(result)
        local metadata = {}
        if result and result[1] and result[1].metadata then
            metadata = json.decode(result[1].metadata) or {}
        end
        metadata[key] = value
        pcall(function()
            MySQL.Async.execute('UPDATE users SET metadata = ? WHERE identifier = ?', {json.encode(metadata), identifier})
        end)
    end)
end

-- ====================================================================================
--                                    INVENTORY
-- ====================================================================================

Lib47.GetInventoryItems = function(inventoryId)
    return Integration.GetInventoryItems(inventoryId)
end

Lib47.GetItems = function()
    return Integration.GetItems()
end

Lib47.GetItemLabel = function(item)
    local items = Lib47.GetItems()
    if items and items[item] then
        return items[item].label
    end
    return item
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
