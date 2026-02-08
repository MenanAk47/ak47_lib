Lib47.GiveVehicleKey = function(source, plate, vehNetId, virtual)
    return Lib47.Callback.Await('ak47_lib:callback:client:GiveVehicleKey', source, plate, vehNetId, virtual)
end

Lib47.RemoveVehicleKey = function(source, plate, vehNetId, virtual)
    return Lib47.Callback.Await('ak47_lib:callback:client:RemoveVehicleKey', source, plate, vehNetId, virtual)
end