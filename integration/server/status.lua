-- ------------------------------------------------------------------------------------
-- Hunger
-- ------------------------------------------------------------------------------------
Lib47.SetHunger = function(source, amount)
    if not amount then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:set', source, 'hunger', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local finalAmount = math.floor(amount)
            Player.Functions.SetMetaData('hunger', finalAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, finalAmount, Player.PlayerData.metadata['thirst'] or 0)
        end
    else
        -- your custom code here
    end
end

Lib47.AddHunger = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:add', source, 'hunger', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['hunger'] or 0
            local newAmount = math.floor(math.min(100, current + amount))
            Player.Functions.SetMetaData('hunger', newAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, newAmount, Player.PlayerData.metadata['thirst'] or 0)
        end
    else
        -- your custom code here
    end
end

Lib47.RemoveHunger = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:remove', source, 'hunger', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['hunger'] or 0
            local newAmount = math.floor(math.max(0, current - amount))
            Player.Functions.SetMetaData('hunger', newAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, newAmount, Player.PlayerData.metadata['thirst'] or 0)
        end
    else
        -- your custom code here
    end
end

-- ------------------------------------------------------------------------------------
-- Thirst
-- ------------------------------------------------------------------------------------
Lib47.SetThirst = function(source, amount)
    if not amount then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:set', source, 'thirst', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local finalAmount = math.floor(amount)
            Player.Functions.SetMetaData('thirst', finalAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata['hunger'] or 0, finalAmount)
        end
    else
        -- your custom code here
    end
end

Lib47.AddThirst = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:add', source, 'thirst', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['thirst'] or 0
            local newAmount = math.floor(math.min(100, current + amount))
            Player.Functions.SetMetaData('thirst', newAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata['hunger'] or 0, newAmount)
        end
    else
        -- your custom code here
    end
end

Lib47.RemoveThirst = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:remove', source, 'thirst', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['thirst'] or 0
            local newAmount = math.floor(math.max(0, current - amount))
            Player.Functions.SetMetaData('thirst', newAmount)
            TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata['hunger'] or 0, newAmount)
        end
    else
        -- your custom code here
    end
end

-- ------------------------------------------------------------------------------------
-- Stress
-- ------------------------------------------------------------------------------------
Lib47.SetStress = function(source, amount)
    if not amount then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:set', source, 'stress', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local finalAmount = math.floor(amount)
            Player.Functions.SetMetaData('stress', finalAmount)
            TriggerClientEvent('hud:client:UpdateStress', source, finalAmount)
        end
    else
        -- your custom code here
    end
end

Lib47.AddStress = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:add', source, 'stress', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['stress'] or 0
            local newAmount = math.floor(math.min(100, current + amount))
            Player.Functions.SetMetaData('stress', newAmount)
            TriggerClientEvent('hud:client:UpdateStress', source, newAmount)
        end
    else
        -- your custom code here
    end
end

Lib47.RemoveStress = function(source, amount)
    if not amount or amount <= 0 then return end
    amount = math.max(0, math.min(100, amount))

    if Lib47.Framework == 'esx' then
        TriggerEvent('esx_status:remove', source, 'stress', math.floor(amount * 10000))
    elseif Lib47.Framework == 'qb' or Lib47.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        if Player then
            local current = Player.PlayerData.metadata['stress'] or 0
            local newAmount = math.floor(math.max(0, current - amount))
            Player.Functions.SetMetaData('stress', newAmount)
            TriggerClientEvent('hud:client:UpdateStress', source, newAmount)
        end
    else
        -- your custom code here
    end
end

RegisterNetEvent('ak47_lib:server:SetHunger', function( amount )
    Lib47.SetHunger(source, amount)
end)

RegisterNetEvent('ak47_lib:server:AddHunger', function( amount )
    Lib47.AddHunger(source, amount)
end)

RegisterNetEvent('ak47_lib:server:RemoveHunger', function( amount )
    Lib47.RemoveHunger(source, amount)
end)

RegisterNetEvent('ak47_lib:server:SetThirst', function( amount )
    Lib47.SetThirst(source, amount)
end)

RegisterNetEvent('ak47_lib:server:AddThirst', function( amount )
    Lib47.AddThirst(source, amount)
end)

RegisterNetEvent('ak47_lib:server:RemoveThirst', function( amount )
    Lib47.RemoveThirst(source, amount)
end)

RegisterNetEvent('ak47_lib:server:SetStress', function( amount )
    Lib47.SetStress(source, amount)
end)

RegisterNetEvent('ak47_lib:server:AddStress', function( amount )
    Lib47.AddStress(source, amount)
end)

RegisterNetEvent('ak47_lib:server:RemoveStress', function( amount )
    Lib47.RemoveStress(source, amount)
end)