Bridge.GiveVehicleKey = function(source, plate, vehNetId, virtual)
    return lib.callback.await('ak47_bridge:callback:client:GiveVehicleKey', source, plate, vehNetId, virtual)
end

Bridge.RemoveVehicleKey = function(source, plate, vehNetId, virtual)
    return lib.callback.await('ak47_bridge:callback:client:RemoveVehicleKey', source, plate, vehNetId, virtual)
end