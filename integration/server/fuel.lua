Lib47.GetVehicleFuel = function(source, vehNetId)
    return Lib47.Callback.Await('ak47_lib:callback:client:GetVehicleFuel', source, vehNetId)
end

Lib47.SetVehicleFuel = function(source, vehNetId, fuel)
    TriggerClientEvent('ak47_lib:client:SetVehicleFuel', source, vehNetId, fuel)
end