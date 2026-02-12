local StatusCache = {
    LastStand = {},
    IsDead = {}
}

local function CalculateLastStand(target)
    local ped = target and GetPlayerPed(GetPlayerFromServerId(target)) or PlayerPedId()
    if target then
        if (GetResourceState('ak47_ambulancejob') == 'started' or GetResourceState('ak47_qb_ambulancejob') == 'started') and Player(target).state.down then
            return true
        end

        return Lib47.GetTargetMetaValue(target, 'inlaststand')
    else
        if (GetResourceState('ak47_ambulancejob') == 'started' or GetResourceState('ak47_qb_ambulancejob') == 'started') and LocalPlayer.state.down then
            return true
        end

        if Config.Framework == 'qb' or Config.Framework == 'qbx' then
            return Lib47.PlayerData.metadata.inlaststand
        end
    end

    if IsEntityPlayingAnim(ped, 'combat@damage@writhe', 'writhe_loop', 3) then
        return true
    end

    return false
end

local function CalculateIsDead(target)
    local ped = target and GetPlayerPed(GetPlayerFromServerId(target)) or PlayerPedId()
    if target then
        if (GetResourceState('ak47_ambulancejob') == 'started' or GetResourceState('ak47_qb_ambulancejob') == 'started') and Player(target).state.dead then
            return true
        end

        if Config.Framework == 'esx' then
            return Player(target).state.isDead
        end

        return Lib47.GetTargetMetaValue(target, 'isdead')
    else
        if (GetResourceState('ak47_ambulancejob') == 'started' or GetResourceState('ak47_qb_ambulancejob') == 'started') and LocalPlayer.state.dead then
            return true
        end

        if Config.Framework == 'esx' then
            return LocalPlayer.state.isDead
        end

        if Config.Framework == 'qb' or Config.Framework == 'qbx' then
            return Lib47.PlayerData.metadata.isdead
        end
    end

    if IsEntityDead(ped) or 
        IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3) or
        IsEntityPlayingAnim(ped, 'dead', 'dead_b', 3) or
        IsEntityPlayingAnim(ped, 'dead', 'dead_c', 3) then
        return true
    end

    return false
end

Lib47.IsLastStand = function(target)
    local currentTime = GetGameTimer()
    local cacheKey = target or 'self'

    if StatusCache.LastStand[cacheKey] and (currentTime - StatusCache.LastStand[cacheKey].time < 1000) then
        return StatusCache.LastStand[cacheKey].value
    end

    local result = CalculateLastStand(target)
    StatusCache.LastStand[cacheKey] = { time = currentTime, value = result }
    
    return result
end

Lib47.IsDead = function(target)
    local currentTime = GetGameTimer()
    local cacheKey = target or 'self'

    if StatusCache.IsDead[cacheKey] and (currentTime - StatusCache.IsDead[cacheKey].time < 1000) then
        return StatusCache.IsDead[cacheKey].value
    end

    local result = CalculateIsDead(target)
    StatusCache.IsDead[cacheKey] = { time = currentTime, value = result }
    
    return result
end

Lib47.IsIncapacitated = function(target)
    return Lib47.IsLastStand(target) or Lib47.IsDead(target)
end