local registeredNpcs = {}
local activeNpcId = nil
local npcState = { visible = false, invoked = nil }
local npcHistoryStack = {}
local npcCam = nil

local function SanitizeForNUI(data)
    local t = type(data)
    if t == 'function' then return nil end
    if t ~= 'table' then return data end
    local res = {}
    for k, v in pairs(data) do
        local val = SanitizeForNUI(v)
        if val ~= nil then res[k] = val end
    end
    return res
end

local function SetupPlayerPosition(entity)
    if not entity or not DoesEntityExist(entity) then return end
    if DoesCamExist(npcCam) then return end

    local playerPed = PlayerPedId()
    local npcCoords = GetEntityCoords(entity)
    local npcHeading = GetEntityHeading(entity)
    
    local playerDistance = 0.8 
    
    local angle = npcHeading * math.pi / 180.0
    local dx = -math.sin(angle) * playerDistance
    local dy = math.cos(angle) * playerDistance
    
    local targetX = npcCoords.x + dx
    local targetY = npcCoords.y + dy
    local targetZ = npcCoords.z 
    local targetCoords = vector3(targetX, targetY, targetZ)
    
    local playerHeading = (npcHeading - 180.0)
    TaskGoStraightToCoord(playerPed, targetX, targetY, targetZ, 1.0, -1, playerHeading, 0.1)
end

local function SetupNpcCamera(entity)
    if not entity or not DoesEntityExist(entity) then return end
    if DoesCamExist(npcCam) then return end
    
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    
    local angle = heading * math.pi / 180.0
    
    local forwardDistance = 1.3
    local rightDistance = -0.7
    
    local dx = (-math.sin(angle) * forwardDistance) + (math.cos(angle) * rightDistance)
    local dy = (math.cos(angle) * forwardDistance) + (math.sin(angle) * rightDistance)
    
    local camCoords = vector3(coords.x + dx, coords.y + dy, coords.z + 0.65)
    
    npcCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(npcCam, camCoords.x, camCoords.y, camCoords.z)
    
    PointCamAtEntity(npcCam, entity, 0.0, 0.0, 0.65, true)
    SetCamActive(npcCam, true)
    RenderScriptCams(true, true, 1000, true, false)

    Wait(1000)
end

local function DestroyNpcCamera()
    if DoesCamExist(npcCam) then
        RenderScriptCams(false, true, 800, true, false)
        DestroyCam(npcCam, false)
        npcCam = nil
    end
end

Interface.RegisterNpcInteract = function(entity, data)
    if not data or not data.id then return end
    data.entity = entity
    registeredNpcs[data.id] = data
end

Interface.ShowNpcInteract = function(id, focusIndex)
    local npcConfig = registeredNpcs[id]
    if not npcConfig then return end

    npcState.invoked = GetInvokingResource()
    npcState.visible = true
    activeNpcId = id

    local processedOptions = {}
    if npcConfig.options then
        for i, opt in ipairs(npcConfig.options) do
            local visible = true
            if opt.isVisible then visible = opt.isVisible() end
            
            if visible then
                local disabled = opt.disabled or false
                if opt.canInteract then disabled = not opt.canInteract() end
                
                local safeOpt = SanitizeForNUI(opt)
                safeOpt.disabled = disabled
                safeOpt.originalIndex = i
                table.insert(processedOptions, safeOpt)
            end
        end
    end

    local randomDialogue = ""
    if npcConfig.dialogues and #npcConfig.dialogues > 0 then
        randomDialogue = npcConfig.dialogues[math.random(1, #npcConfig.dialogues)]
    end

    SetupPlayerPosition(npcConfig.entity)
    SetupNpcCamera(npcConfig.entity)

    local colors = npcConfig.colors or Config.Defaults.NpcInteract.colors

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_NPC_INTERACT',
        data = {
            id = npcConfig.id,
            dialogue = randomDialogue,
            colors = colors,
            focusIndex = focusIndex,
            isSubMenu = (#npcHistoryStack > 0) or (npcConfig.menu ~= nil),
            options = processedOptions
        }
    })
end

Interface.HideNpcInteract = function(runOnExit)
    if runOnExit and activeNpcId then
        local npc = registeredNpcs[activeNpcId]
        if npc and npc.onExit then npc.onExit() end
    end
    
    npcState.visible = false
    activeNpcId = nil
    npcHistoryStack = {}
    DestroyNpcCamera()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_NPC_INTERACT' })
end

RegisterNUICallback('npcAction', function(data, cb)
    if not activeNpcId then cb('ok'); return end
    local npc = registeredNpcs[activeNpcId]
    if not npc then cb('ok'); return end

    local arrayIndex = data.index + 1
    local processedOpt = data.option
    local option = npc.options[processedOpt.originalIndex]
    
    if not option then cb('ok'); return end

    local previousNpcId = activeNpcId

    if option.onSelect then option.onSelect() end
    if option.event then TriggerEvent(option.event) end
    if option.serverEvent then TriggerServerEvent(option.serverEvent) end

    if option.menu then
        table.insert(npcHistoryStack, previousNpcId)
        Interface.ShowNpcInteract(option.menu)
    elseif activeNpcId == previousNpcId and data.close ~= false then
        Interface.HideNpcInteract(true)
    end

    cb('ok')
end)

RegisterNUICallback('npcBack', function(data, cb)
    if #npcHistoryStack > 0 then
        local prevId = table.remove(npcHistoryStack)
        Interface.ShowNpcInteract(prevId)
    else
        local currentNpc = registeredNpcs[activeNpcId]
        if currentNpc and currentNpc.menu then
            Interface.ShowNpcInteract(currentNpc.menu)
        else
            Interface.HideNpcInteract(true)
        end
    end
    cb('ok')
end)

RegisterNUICallback('npcExit', function(data, cb)
    Interface.HideNpcInteract(true)
    cb('ok')
end)

exports('RegisterNpcInteract', Interface.RegisterNpcInteract)
exports('ShowNpcInteract', Interface.ShowNpcInteract)
exports('HideNpcInteract', Interface.HideNpcInteract)

Lib47.RegisterNpcInteract = Interface.RegisterNpcInteract
Lib47.ShowNpcInteract = Interface.ShowNpcInteract
Lib47.HideNpcInteract = Interface.HideNpcInteract

--============================= Example ============================

--[[
local testNpcEntity = 0

CreateThread(function()
    local npcModel = `s_m_m_ciasec_01` 
    local npcCoords = vector4(281.24, -583.08, 43.28, 196.35)

    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(10) end

    testNpcEntity = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcCoords.w, false, false)

    SetEntityHeading(testNpcEntity, npcCoords.w)
    FreezeEntityPosition(testNpcEntity, true)
    SetEntityInvincible(testNpcEntity, true)
    SetBlockingOfNonTemporaryEvents(testNpcEntity, true)
    SetModelAsNoLongerNeeded(npcModel)

    exports['ak47_lib']:RegisterNpcInteract(testNpcEntity, {
        id = 'car_rental_dialogue_test',
        colors = {
            colorPrimary = "rgba(18, 18, 22, 0.9)", 
            colorSecondary = "#FFD700",
            colorText = "#ffffff",
        },
        dialogues = {
            'Hi there, how can I help you today?',
            'Hey! Do you need a vehicle to rent?'
        },
        onExit = function()
            print("Conversation with Car Rental NPC ended.")
        end,
        options = {
            {
                label = '(Talk) "Tell me about the town of Briarwood."',
                icon = 'comments',
                iconColor = '#ffffff',
                -- Because you manually open the submenu here, our fix in `npcAction` ensures it doesn't auto-close!
                onSelect = function() 
                    print("You asked about Briarwood!")
                    exports['ak47_lib']:ShowNpcInteract('car_rental_dialogue_test2')
                end
            },
            {
                label = '(Rent) Compact Car - $500',
                icon = 'car',
                iconColor = '#3498db',
                onSelect = function()
                    print("You rented a compact car!")
                end
            },
            {
                label = '(Leave) "I am good, thanks."',
                icon = 'person-walking-arrow-right',
                iconColor = '#e74c3c',
            }
        }
    })

    exports['ak47_lib']:RegisterNpcInteract(testNpcEntity, {
        id = 'car_rental_dialogue_test2',
        menu = 'car_rental_dialogue_test', -- Setting this now natively supports the Back button!
        dialogues = {
            'Briarwood is a small town, quiet mostly.',
            'Not much happens around here, honestly.'
        },
        onExit = function()
            print("Submenu closed.")
        end,
        options = {
            {
                label = '2(Rent) Compact Car - $500',
                icon = 'car',
                iconColor = '#3498db',
                onSelect = function()
                    print("You rented a compact car from the submenu!")
                end
            },
            {
                label = '(Leave) "I am good, thanks."',
                icon = 'person-walking-arrow-right',
                iconColor = '#e74c3c',
            }
        }
    })
    
    print("^2[Test] Spawning NPC and registering interaction! ID: " .. testNpcEntity .. "^7")
end)

RegisterCommand('testnpc', function()
    if DoesEntityExist(testNpcEntity) then
        exports['ak47_lib']:ShowNpcInteract('car_rental_dialogue_test')
    else
        print("^1[Test] The NPC entity does not exist! Are you near the coordinates?^7")
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if DoesEntityExist(testNpcEntity) then
            DeleteEntity(testNpcEntity)
        end
    end
end)
]]