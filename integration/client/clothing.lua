local isMale = function(ped)
    return GetEntityModel(ped) == `mp_m_freemode_01`
end

local clothingCategories = {
    ["mask"]      = {type = "variation", id = 1},
    ["arms"]      = {type = "variation", id = 3},
    ["pants"]     = {type = "variation", id = 4},
    ["bag"]       = {type = "variation", id = 5},
    ["shoes"]     = {type = "variation", id = 6},
    ["accessory"] = {type = "variation", id = 7},
    ["t-shirt"]   = {type = "variation", id = 8},
    ["vest"]      = {type = "variation", id = 9},
    ["decals"]    = {type = "variation", id = 10},
    ["torso2"]    = {type = "variation", id = 11},

    ["hat"]       = {type = "prop",      id = 0},
    ["glass"]     = {type = "prop",      id = 1},
    ["ear"]       = {type = "prop",      id = 2},
    ["watch"]     = {type = "prop",      id = 6},
    ["bracelet"]  = {type = "prop",      id = 7},
}

local function ConvertToEsx(skin)
    if not skin then return {} end
    local esxData = {}

    if skin.mask then
        esxData.mask_1 = skin.mask.item or 0
        esxData.mask_2 = skin.mask.texture or 0
    end
    if skin.arms then
        esxData.arms = skin.arms.item or 0
        esxData.arms_2 = skin.arms.texture or 0
    end
    if skin.pants then
        esxData.pants_1 = skin.pants.item or 0
        esxData.pants_2 = skin.pants.texture or 0
    end
    if skin.shoes then
        esxData.shoes_1 = skin.shoes.item or 0
        esxData.shoes_2 = skin.shoes.texture or 0
    end
    if skin.accessory then
        esxData.chain_1 = skin.accessory.item or 0
        esxData.chain_2 = skin.accessory.texture or 0
    end
    if skin['t-shirt'] then
        esxData.tshirt_1 = skin['t-shirt'].item or 0
        esxData.tshirt_2 = skin['t-shirt'].texture or 0
    end
    if skin.vest then
        esxData.bproof_1 = skin.vest.item or 0
        esxData.bproof_2 = skin.vest.texture or 0
    end
    if skin.bag then
        esxData.bags_1 = skin.bag.item or 0
        esxData.bags_2 = skin.bag.texture or 0
    end
    if skin.decals then
        esxData.decals_1 = skin.decals.item or 0
        esxData.decals_2 = skin.decals.texture or 0
    end
    if skin.torso2 then
        esxData.torso_1 = skin.torso2.item or 0
        esxData.torso_2 = skin.torso2.texture or 0
    end

    -- Props
    if skin.hat then
        esxData.helmet_1 = skin.hat.item or -1
        esxData.helmet_2 = skin.hat.texture or 0
    end
    if skin.glass then
        esxData.glasses_1 = skin.glass.item or -1
        esxData.glasses_2 = skin.glass.texture or 0
    end
    if skin.ear then
        esxData.ears_1 = skin.ear.item or -1
        esxData.ears_2 = skin.ear.texture or 0
    end
    if skin.watch then
        esxData.watches_1 = skin.watch.item or -1
        esxData.watches_2 = skin.watch.texture or 0
    end
    if skin.bracelet then
        esxData.bracelets_1 = skin.bracelet.item or -1
        esxData.bracelets_2 = skin.bracelet.texture or 0
    end

    return esxData
end

Lib47.GetOutfit = function()
    local ped = PlayerPedId()
    local currentOutfit = {}

    for category, data in pairs(clothingCategories) do
        if data.type == "variation" then
            currentOutfit[category] = {
                item = GetPedDrawableVariation(ped, data.id),
                texture = GetPedTextureVariation(ped, data.id)
            }
        elseif data.type == "prop" then
            currentOutfit[category] = {
                item = GetPedPropIndex(ped, data.id),
                texture = GetPedPropTextureIndex(ped, data.id)
            }
        end
    end

    return currentOutfit
end

Lib47.SetOutfit = function(data)
    if not data then return end

    if Lib47.Framework == 'esx' then
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent('skinchanger:loadClothes', skin, ConvertToEsx(data))
        end)
    else
        TriggerEvent('qb-clothing:client:loadOutfit', {outfitData = data})
    end
end

Lib47.LoadOutfit = function(data)
    if not data then return end
    local ped = PlayerPedId()

    -- Components
    if data["mask"] ~= nil then
        SetPedComponentVariation(ped, 1, data["mask"].item or 0, data["mask"].texture or 0, 0)
    end
    if data["arms"] ~= nil then
        SetPedComponentVariation(ped, 3, data["arms"].item or 0, data["arms"].texture or 0, 0)
    end
    if data["pants"] ~= nil then
        SetPedComponentVariation(ped, 4, data["pants"].item or 0, data["pants"].texture or 0, 0)
    end
    if data["bag"] ~= nil then
        SetPedComponentVariation(ped, 5, data["bag"].item or 0, data["bag"].texture or 0, 0)
    end
    if data["shoes"] ~= nil then
        SetPedComponentVariation(ped, 6, data["shoes"].item or 0, data["shoes"].texture or 0, 0)
    end
    if data["accessory"] ~= nil then
        SetPedComponentVariation(ped, 7, data["accessory"].item or 0, data["accessory"].texture or 0, 0)
    end
    if data["t-shirt"] ~= nil then
        SetPedComponentVariation(ped, 8, data["t-shirt"].item or 0, data["t-shirt"].texture or 0, 0)
    end
    if data["vest"] ~= nil then
        SetPedComponentVariation(ped, 9, data["vest"].item or 0, data["vest"].texture or 0, 0)
    end
    if data["decals"] ~= nil then
        SetPedComponentVariation(ped, 10, data["decals"].item or 0, data["decals"].texture or 0, 0)
    end
    if data["torso2"] ~= nil then
        SetPedComponentVariation(ped, 11, data["torso2"].item or 0, data["torso2"].texture or 0, 0)
    end

    -- Props (-1 indicates empty/none)
    if data["hat"] ~= nil then
        if data["hat"].item ~= -1 then
            SetPedPropIndex(ped, 0, data["hat"].item, data["hat"].texture or 0, true)
        else
            ClearPedProp(ped, 0)
        end
    end

    if data["glass"] ~= nil then
        if data["glass"].item ~= -1 then
            SetPedPropIndex(ped, 1, data["glass"].item, data["glass"].texture or 0, true)
        else
            ClearPedProp(ped, 1)
        end
    end

    if data["ear"] ~= nil then
        if data["ear"].item ~= -1 then
            SetPedPropIndex(ped, 2, data["ear"].item, data["ear"].texture or 0, true)
        else
            ClearPedProp(ped, 2)
        end
    end

    if data["watch"] ~= nil then
        if data["watch"].item ~= -1 then
            SetPedPropIndex(ped, 6, data["watch"].item, data["watch"].texture or 0, true)
        else
            ClearPedProp(ped, 6)
        end
    end

    if data["bracelet"] ~= nil then
        if data["bracelet"].item ~= -1 then
            SetPedPropIndex(ped, 7, data["bracelet"].item, data["bracelet"].texture or 0, true)
        else
            ClearPedProp(ped, 7)
        end
    end
end

Lib47.ResetOutfit = function()
    if Lib47.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    else
        if GetResourceState('illenium-appearance') == 'started' then
            TriggerEvent('illenium-appearance:client:reloadSkin')
        elseif GetResourceState('fivem-appearance') == 'started' then
            TriggerEvent('fivem-appearance:client:reloadSkin')
        elseif GetResourceState('qb-clothing') == 'started' then
            TriggerServerEvent('qb-clothing:loadPlayerSkin')
        end
    end
end