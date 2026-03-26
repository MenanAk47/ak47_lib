if Config.Banking == 'auto' then
    local scripts = {
        'ak47_banking',
        'qb-banking',
        'okokBanking',
        'Renewed-Banking',
    }
    CreateThread(function()
        for _, script in pairs(scripts) do
            if GetResourceState(script) == 'started' then
                Config.Banking = script
                print(string.format("^2['BANKING']: %s^0", Config.Banking))
                return
            end
        end
    end)
end

Integration.AddSocietyMoney = function(job, amount, reason, ignoreBankingExport)
    if Config.Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                account.addMoney(amount)
            end
        end)
        return true
    elseif Config.Framework == 'qb' and GetResourceState('qb-management') == 'started' then
        local success, result = pcall(function()
            return exports['qb-management']:AddMoney(job, amount )
        end)

        if success then
            return true
        end
    end

    -- If called from ak47_banking, we stop here and return false instead of looping
    if ignoreBankingExport then return false end

    if Config.Banking == 'ak47_banking' then
        exports['ak47_banking']:AddMoney(job, amount, reason)
        return true
    elseif Config.Banking == 'qb-banking' then
        exports['qb-banking']:AddMoney(job, amount, reason)
        return true
    elseif Config.Banking == 'okokBanking' then
        exports['okokBanking']:AddMoney(job, amount)
        return true
    elseif Config.Banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:addAccountMoney(job, amount)
        return true
    end
    
    return false
end

Integration.RemoveSocietyMoney = function(job, amount, reason, ignoreBankingExport)
    if Config.Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                account.removeMoney(amount)
            end
        end)
        return true
    elseif Config.Framework == 'qb' and GetResourceState('qb-management') == 'started' then
        local success, result = pcall(function()
            return exports['qb-management']:RemoveMoney(job, amount )
        end)

        if success then
            return true
        end
    end

    -- If called from ak47_banking, we stop here and return false instead of looping
    if ignoreBankingExport then return false end

    if Config.Banking == 'ak47_banking' then
        exports['ak47_banking']:RemoveMoney(job, amount, reason)
        return true
    elseif Config.Banking == 'qb-banking' then
        exports['qb-banking']:RemoveMoney(job, amount, reason)
        return true
    elseif Config.Banking == 'okokBanking' then
        exports['okokBanking']:RemoveMoney(job, amount, reason)
        return true
    elseif Config.Banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:removeAccountMoney(job, amount)
        return true
    end
    
    return false
end

Integration.GetSocietyMoney = function(job, ignoreBankingExport)
    if Config.Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                p:resolve(account.money)
            else
                p:resolve(0)
            end
        end)
        return Citizen.Await(p)
    elseif Config.Framework == 'qb' and GetResourceState('qb-management') == 'started' then
        local success, result = pcall(function()
            return exports['qb-management']:GetAccount(job)
        end)

        if success then
            return result
        end
    end

    -- If called from ak47_banking, return nil to signify the native framework manager is missing
    if ignoreBankingExport then return nil end

    if Config.Banking == 'ak47_banking' then
        return exports['ak47_banking']:GetAccountBalance(job)
    elseif Config.Banking == 'qb-banking' then
        return exports['qb-banking']:GetAccountBalance(job)
    elseif Config.Banking == 'okokBanking' then
        return exports['okokBanking']:GetAccount(job)
    elseif Config.Banking == 'Renewed-Banking' then
        return exports['Renewed-Banking']:getAccountMoney(job)
    end

    return 0
end