RegisterNetEvent('ak47_bridge:server:PlaySound', function(data)
    TriggerClientEvent('ak47_bridge:client:PlaySound', -1, data)
end)

RegisterNetEvent('ak47_bridge:server:StopSound', function(soundId)
    TriggerClientEvent('ak47_bridge:client:StopSound', -1, soundId)
end)