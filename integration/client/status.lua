-- ====================================================================================
--                                     STATUS
-- ====================================================================================

Lib47.SetHunger = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    TriggerServerEvent('ak47_lib:server:SetHunger', amount)
end

Lib47.AddHunger = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:AddHunger', amount)
end

Lib47.RemoveHunger = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:RemoveHunger', amount)
end

Lib47.SetThirst = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    TriggerServerEvent('ak47_lib:server:SetThirst', amount)
end

Lib47.AddThirst = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:AddThirst', amount)
end

Lib47.RemoveThirst = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:RemoveThirst', amount)
end

Lib47.SetStress = function(amount)
    amount = tonumber(amount)
    if not amount then return end
    TriggerServerEvent('ak47_lib:server:SetStress', amount)
end

Lib47.AddStress = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:AddStress', amount)
end

Lib47.RemoveStress = function(amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    TriggerServerEvent('ak47_lib:server:RemoveStress', amount)
end
