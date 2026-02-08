RegisterNetEvent('ak47_lib:server:PlaySound', function(data)
    TriggerClientEvent('ak47_lib:client:PlaySound', -1, data)
end)

RegisterNetEvent('ak47_lib:server:StopSound', function(soundId)
    TriggerClientEvent('ak47_lib:client:StopSound', -1, soundId)
end)