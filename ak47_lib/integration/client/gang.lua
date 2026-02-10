Lib47.GetGangName = function()
    if GetResourceState('ak47_gangs') == 'started' or GetResourceState('ak47_gangs') == 'uninitialized' then
        local gang = exports['ak47_gangs']:GetPlayerGang()
        return gang and gang.tag
    elseif GetResourceState('ak47_qb_gangs') == 'started' or GetResourceState('ak47_qb_gangs') == 'uninitialized' then
        local gang = exports['ak47_qb_gangs']:GetPlayerGang()
        return gang and gang.tag
    elseif GetResourceState('ak47_territories') == 'started' or GetResourceState('ak47_territories') == 'uninitialized' then
        local gang = exports['ak47_territories']:GetPlayerGang()
        return gang and gang.tag
    elseif GetResourceState('ak47_qb_territories') == 'started' or GetResourceState('ak47_qb_territories') == 'uninitialized' then
        local gang = exports['ak47_qb_territories']:GetPlayerGang()
        return gang and gang.tag
    end

    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        return PlayerData and PlayerData.gang and PlayerData.gang.name
    end

    return nil
end

Lib47.GetGangRank = function()
    if GetResourceState('ak47_gangs') == 'started' or GetResourceState('ak47_gangs') == 'uninitialized' then
        local gang = exports['ak47_gangs']:GetPlayerGang()
        return gang and gang.rankid
    elseif GetResourceState('ak47_qb_gangs') == 'started' or GetResourceState('ak47_qb_gangs') == 'uninitialized' then
        local gang = exports['ak47_qb_gangs']:GetPlayerGang()
        return gang and gang.rankid
    elseif GetResourceState('ak47_territories') == 'started' or GetResourceState('ak47_territories') == 'uninitialized' then
        local gang = exports['ak47_territories']:GetPlayerGang()
        return gang and gang.rankid
    elseif GetResourceState('ak47_qb_territories') == 'started' or GetResourceState('ak47_qb_territories') == 'uninitialized' then
        local gang = exports['ak47_qb_territories']:GetPlayerGang()
        return gang and gang.rankid
    end

    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        return PlayerData and PlayerData.gang and PlayerData.gang.grade.level
    end

    return nil
end

Lib47.GetGangList = function()
    if GetResourceState('ak47_gangs') == 'started' or 
        GetResourceState('ak47_qb_gangs') == 'started' or 
        GetResourceState('ak47_territories') == 'started' or 
        GetResourceState('ak47_qb_territories') == 'started' then
        return Lib47.Callback.Await('ak47_lib:getakganglist')
    end

    if Config.Framework == 'qb' then
        return QBCore.Shared.Gangs
    elseif Config.Framework == 'qbx' then
        return exports.qbx_core:GetGangs()
    end

    return {}
end