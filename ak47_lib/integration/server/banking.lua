if Config.Banking == 'auto' then
    local scripts = {
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

Integration.AddSocietyMoney = function(job, amount)
    if Config.Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                account.addMoney(amount)
            end
        end)
        return
    elseif Config.Framework == 'qb' and GetResourceState('qb-management') == 'started' then
        local success, result = pcall(function()
            return exports['qb-management']:AddMoney(job, amount )
        end)

        if success then
            return
        end
    end

    if Config.Banking == 'qb-banking' then
        exports['qb-banking']:AddMoney(job, amount)
    elseif Config.Banking == 'okokBanking' then
        exports['okokBanking']:AddMoney(job, amount)
    elseif Config.Banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:addAccountMoney(job, amount)
    end
end

Integration.RemoveSocietyMoney = function(job, amount)
    if Config.Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                account.removeMoney(amount)
            end
        end)
        return
    elseif Config.Framework == 'qb' and GetResourceState('qb-management') == 'started' then
        local success, result = pcall(function()
            return exports['qb-management']:RemoveMoney(job, amount )
        end)

        if success then
            return
        end
    end

    if Config.Banking == 'qb-banking' then
        exports['qb-banking']:RemoveMoney(job, amount)
    elseif Config.Banking == 'okokBanking' then
        exports['okokBanking']:RemoveMoney(job, amount)
    elseif Config.Banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:removeAccountMoney(job, amount)
    end
end

Integration.GetSocietyMoney = function(job)
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

    if Config.Banking == 'qb-banking' then
        return exports['qb-banking']:GetAccountBalance(job)
    elseif Config.Banking == 'okokBanking' then
        return exports['okokBanking']:GetAccount(job)
    elseif Config.Banking == 'Renewed-Banking' then
        return exports['Renewed-Banking']:getAccountMoney(job)
    end

    return 0
end




