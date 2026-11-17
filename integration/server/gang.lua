Integration.GetGangs = function(source)
    local tablename = (GetResourceState('ak47_gangs') == 'started' and 'ak47_gangs') or
        (GetResourceState('ak47_qb_gangs') == 'started' and 'ak47_qb_gangs') or
        (GetResourceState('ak47_territories') == 'started' and 'ak47_territories_gangs') or
        (GetResourceState('ak47_qb_territories') == 'started' and 'ak47_qb_territory_gangs')

    if tablename then
        local gangs = MySQL.Sync.fetchAll("SELECT tag, label, ranks FROM "..tablename)
        local qbFormatGangs = {}

        for _, data in pairs(gangs) do
            local grades = {}
            local ranksList = data.ranks and json.decode(data.ranks) or {}
            for i, rankData in ipairs(ranksList) do
                local gradeIndex = tostring(i - 1)
                grades[gradeIndex] = {
                    name = rankData.label or rankData.tag or "Unknown Rank"
                }
            end
            qbFormatGangs[data.tag] = {
                label = data.label,
                grades = grades
            }
        end

        return qbFormatGangs
    end

    if GetResourceState('ars_gangsystem') == 'started' and Lib47.DoesExportExist('ars_gangsystem', 'GetGangs') then
        local gangs = exports['ars_gangsystem']:GetGangs()
        local qbFormatGangs = {}

        for tag, data in pairs(gangs) do
            local grades = {}
            local ranksList = data.ranks or {}
            for i, rankLabel in ipairs(ranksList) do
                -- key by raw ars rank (1 = highest) so grades[GetGang().grade.level] resolves correctly
                grades[tostring(i)] = {
                    name = rankLabel
                }
            end
            qbFormatGangs[tag] = {
                label = data.name,
                grades = grades
            }
        end

        return qbFormatGangs
    end

    if Config.Framework == 'qb' then
        return QBCore.Shared.Gangs
    elseif Config.Framework == 'qbx' then
        return exports.qbx_core:GetGangs()
    end

    return {}
end

Integration.GetGang = function(source)
    local gangData = nil

    if GetResourceState('ak47_gangs') == 'started' or GetResourceState('ak47_gangs') == 'uninitialized' then
        gangData = exports['ak47_gangs']:GetPlayerGang(source)
    elseif GetResourceState('ak47_qb_gangs') == 'started' or GetResourceState('ak47_qb_gangs') == 'uninitialized' then
        gangData = exports['ak47_qb_gangs']:GetPlayerGang(source)
    elseif GetResourceState('ak47_territories') == 'started' or GetResourceState('ak47_territories') == 'uninitialized' then
        gangData = exports['ak47_territories']:GetPlayerGang(source)
    elseif GetResourceState('ak47_qb_territories') == 'started' or GetResourceState('ak47_qb_territories') == 'uninitialized' then
        gangData = exports['ak47_qb_territories']:GetPlayerGang(source)
    elseif GetResourceState('ars_gangsystem') == 'started' and Lib47.DoesExportExist('ars_gangsystem', 'GetPlayerGang') then
        gangData = exports['ars_gangsystem']:GetPlayerGang(source)
    end

    if gangData then
        if gangData.player then -- ars_gangsystem shape
            return {
                name = gangData.tag,
                label = gangData.name,
                isboss = gangData.player.rank == 1,
                grade = {
                    level = gangData.player.rank or 0,
                    name = gangData.player.rankName
                }
            }
        end

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

Integration.SetGang = function(source, name, grade)
    --[[ -- incomplete exports
    if GetResourceState('ak47_gangs') == 'started' or GetResourceState('ak47_gangs') == 'uninitialized' then
        exports['ak47_gangs']:SetPlayerGang(source, name, grade)
    elseif GetResourceState('ak47_qb_gangs') == 'started' or GetResourceState('ak47_qb_gangs') == 'uninitialized' then
        exports['ak47_qb_gangs']:SetPlayerGang(source, name, grade)
    elseif GetResourceState('ak47_territories') == 'started' or GetResourceState('ak47_territories') == 'uninitialized' then
        exports['ak47_territories']:SetPlayerGang(source, name, grade)
    elseif GetResourceState('ak47_qb_territories') == 'started' or GetResourceState('ak47_qb_territories') == 'uninitialized' then
        exports['ak47_qb_territories']:SetPlayerGang(source, name, grade)
    end
    ]]

    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = Lib47.GetPlayer(source)
        return Player and Player.SetGang.SetGang(name, grade)
    end
end

Lib47.Callback.Register('ak47_lib:getakganglist', function()
    return Integration.GetGangs()
end)

Lib47.Callback.Register('ak47_lib:getakgang', function(source)
    return Integration.GetGang(source)
end)