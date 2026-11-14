-- ====================================================================================
--                                     STATUS
-- ====================================================================================

Lib47.SetHunger = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:set', 'hunger', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:SetHunger', amount)
end

Lib47.AddHunger = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:add', 'hunger', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:AddHunger', amount)
end

Lib47.RemoveHunger = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:remove', 'hunger', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:RemoveHunger', amount)
end

Lib47.SetThirst = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:set', 'thirst', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:SetThirst', amount)
end

Lib47.AddThirst = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:add', 'thirst', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:AddThirst', amount)
end

Lib47.RemoveThirst = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:remove', 'thirst', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:RemoveThirst', amount)
end

Lib47.SetStress = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:set', 'stress', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:SetStress', amount)
end

Lib47.AddStress = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:add', 'stress', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:AddStress', amount)
end

Lib47.RemoveStress = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Lib47.Framework == 'esx' and Lib47.GetResourceVersion('esx_status') <= 1.0 then
        amount = math.max(0, math.min(100, amount))
        TriggerEvent('esx_status:remove', 'stress', math.floor(amount * 10000))
        return
    end
    TriggerServerEvent('ak47_lib:server:RemoveStress', amount)
end
