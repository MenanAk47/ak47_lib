Lib47.RequestParticleDict = function(dictionary)
    if HasNamedPtfxAssetLoaded(dictionary) then return end
    RequestNamedPtfxAsset(dictionary)
    while not HasNamedPtfxAssetLoaded(dictionary) do Wait(0) end
end

Lib47.StartParticleAtCoord = function(dict, ptName, looped, coords, rot, scale, alpha, color, duration)
    coords = coords and (type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords) or GetEntityCoords(PlayerPedId())
    Lib47.RequestParticleDict(dict)
    UseParticleFxAssetNextCall(dict)
    SetPtfxAssetNextCall(dict)
    local handle
    if looped then
        handle = StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0)
        if color then SetParticleFxLoopedColour(handle, color.r, color.g, color.b, false) end
        SetParticleFxLoopedAlpha(handle, alpha or 10.0)
        if duration then Wait(duration); StopParticleFxLooped(handle, 0) end
    else
        SetParticleFxNonLoopedAlpha(alpha or 10.0)
        if color then SetParticleFxNonLoopedColour(color.r, color.g, color.b) end
        StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0)
    end
    return handle
end

Lib47.StartParticleOnEntity = function(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration)
    Lib47.RequestParticleDict(dict)
    UseParticleFxAssetNextCall(dict)
    local handle, boneID
    if bone then boneID = (GetEntityType(entity) == 1) and GetPedBoneIndex(entity, bone) or GetEntityBoneIndexByName(entity, bone) end
    if looped then
        if bone then handle = StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale)
        else handle = StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale) end
        if evolution then SetParticleFxLoopedEvolution(handle, evolution.name, evolution.amount, false) end
        if color then SetParticleFxLoopedColour(handle, color.r, color.g, color.b, false) end
        SetParticleFxLoopedAlpha(handle, alpha)
        if duration then Wait(duration); StopParticleFxLooped(handle, 0) end
    else
        SetParticleFxNonLoopedAlpha(alpha or 10.0)
        if color then SetParticleFxNonLoopedColour(color.r, color.g, color.b) end
        if bone then StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale)
        else StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale) end
    end
    return handle
end