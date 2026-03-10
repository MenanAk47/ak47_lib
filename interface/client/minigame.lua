local minigamePromise = nil
local minigameState = { visible = false, invoked = nil }

Interface.StartTensionMinigame = function(variant, difficulty, customSettings)
    if minigamePromise then 
        return false 
    end

    minigameState.invoked = GetInvokingResource()
    minigameState.visible = true

    variant = variant or 'classic'
    difficulty = difficulty or 'medium'
    
    local settings = {}
    if Config.Defaults.Minigame.tension[difficulty] and Config.Defaults.Minigame.tension[difficulty][variant] then
        for k, v in pairs(Config.Defaults.Minigame.tension[difficulty][variant]) do
            settings[k] = v
        end
    end

    if customSettings and type(customSettings) == 'table' then
        for k, v in pairs(customSettings) do
            settings[k] = v
        end
    end

    SetNuiFocus(true, false)
    
    minigamePromise = promise.new()
    
    SendNUIMessage({
        action = 'START_TENSION_MINIGAME',
        variant = variant,
        settings = settings
    })
    
    local result = Citizen.Await(minigamePromise)
    
    SetNuiFocus(false, false)
    minigamePromise = nil
    
    minigameState.visible = false
    minigameState.invoked = nil
    
    return result
end

Interface.CancelMinigame = function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_TENSION_MINIGAME' })
    if minigamePromise then minigamePromise:resolve(false) end
end

RegisterNUICallback('tensionResult', function(data, cb)
    if minigamePromise then 
        minigamePromise:resolve(data.success) 
    end
    cb('ok')
end)

-- Exports & Global assignment
exports('StartTensionMinigame', Interface.StartTensionMinigame)
exports('CancelMinigame', Interface.CancelMinigame)

Lib47.StartTensionMinigame = Interface.StartTensionMinigame
Lib47.CancelMinigame = Interface.CancelMinigame


-- Cleanup if the resource that started the minigame is stopped/restarted
AddEventHandler('onResourceStop', function(resourceName)
    if minigameState.visible and minigameState.invoked == resourceName then
        Interface.CancelMinigame()
    end
end)

--==================== Examples ===============
--[[
-- Example 1: Standard fishing (uses default icon)
RegisterCommand('testfish', function()
    local success = Interface.StartTensionMinigame('frenzy', 'medium')
    if success then print("Caught it!") end
end)

-- Example 2: Lockpicking an engine (Custom Icon)
RegisterCommand('testlockpick', function()
    local customOverrides = {
        icon = 'fa-solid fa-key',  -- Passing the custom font-awesome icon
        barSize = 15
    }
    
    local success = Interface.StartTensionMinigame('momentum', 'easy', customOverrides)
    
    if success then
        print("Engine started!")
    else
        print("You broke the key!")
    end
end)
]]