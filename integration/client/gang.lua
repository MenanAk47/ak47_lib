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

Lib47.GetGang = function()
    local gangData = nil

    if GetResourceState('ak47_gangs') == 'started' or GetResourceState('ak47_gangs') == 'uninitialized' then
        gangData = exports['ak47_gangs']:GetPlayerGang()
    elseif GetResourceState('ak47_qb_gangs') == 'started' or GetResourceState('ak47_qb_gangs') == 'uninitialized' then
        gangData = exports['ak47_qb_gangs']:GetPlayerGang()
    elseif GetResourceState('ak47_territories') == 'started' or GetResourceState('ak47_territories') == 'uninitialized' then
        gangData = exports['ak47_territories']:GetPlayerGang()
    elseif GetResourceState('ak47_qb_territories') == 'started' or GetResourceState('ak47_qb_territories') == 'uninitialized' then
        gangData = exports['ak47_qb_territories']:GetPlayerGang()
    end

    if gangData then
        return {
            name = gangData.tag,
            label = gangData.label,
            isboss = gangData.access and gangData.access.boss,
            grade = {
                level = gangData.rankid,
                name = gangData.ranklable or gangData.ranklabel
            }
        }
    end

    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        return Player and Player.PlayerData.gang
    end

    return {
        name = "none",
        label = "No Gang",
        isboss = false,
        grade = {
            level = 0,
            name = "None"
        }
    }
end