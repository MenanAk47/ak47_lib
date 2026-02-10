local currentTasks = {}
local checklistState = { visible = false, invoked = nil }

Interface.ShowChecklist = function(tasks, title, position)
    local invoked = GetInvokingResource()
    Interface.HideChecklist()

    checklistState.invoked = invoked
    checklistState.visible = true

    currentTasks = tasks or {}
    local title = title or Config.Defaults.Checklist.title
    local pos = position or Config.Defaults.Checklist.position
    local hour = GetClockHours()
    local isNight = Config.Defaults.Checklist.nightEffect and (hour >= 21 or hour < 6)
    
    SendNUIMessage({
        action = 'updateChecklist',
        data = {
            type = 'set',
            title = title,
            tasks = currentTasks,
            position = pos,
            visible = true,
            isNight = isNight
        }
    })
end

Interface.UpdateChecklist = function(index, isComplete, subIndex)
    if currentTasks[index] then
        if subIndex then
            if currentTasks[index].subTasks and currentTasks[index].subTasks[subIndex] then
                currentTasks[index].subTasks[subIndex].completed = isComplete
                
                SendNUIMessage({
                    action = 'updateChecklist',
                    data = {
                        type = 'update',
                        index = index - 1, 
                        subIndex = subIndex - 1,
                        status = isComplete
                    }
                })
            else
                print("^1[HUD] SubIndex " .. tostring(subIndex) .. " not found on Task " .. tostring(index))
            end
        else
            currentTasks[index].completed = isComplete
            SendNUIMessage({
                action = 'updateChecklist',
                data = {
                    type = 'update',
                    index = index - 1, 
                    status = isComplete
                }
            })
        end
    end
end

Interface.HideChecklist = function()
    checklistState.visible = false
    SendNUIMessage({ action = 'updateChecklist', data = { visible = false } })
end

AddEventHandler('onResourceStop', function(resourceName)
    if checklistState.visible and checklistState.invoked == resourceName then
        Interface.HideChecklist()
    end
end)

exports('ShowChecklist', Interface.ShowChecklist)
exports('UpdateChecklist', Interface.UpdateChecklist)
exports('HideChecklist', Interface.HideChecklist)

Lib47.ShowChecklist = Interface.ShowChecklist
Lib47.UpdateChecklist = Interface.UpdateChecklist
Lib47.HideChecklist = Interface.HideChecklist

--[[

-- Demo Command: /subtest
RegisterCommand('subtest', function(source, args)
    local pos = args[1] or 'top'

    Interface.ShowChecklist("Mission Tasks", {
        { label = "Secure Perimeter", completed = false },
        { 
            label = "Hack Terminals", 
            completed = false,
            subTasks = {
                { label = "Server Room A <k>E</k>", completed = false },
                { label = "Server Room B <k>E</k>", completed = false }
            }
        },
        { label = "Escape", completed = false }
    }, pos)

    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        -- Update Main Task 2, Sub Task 1
        Interface.UpdateChecklist(1, true) 

        Citizen.Wait(2000)
        -- Update Main Task 2, Sub Task 1
        Interface.UpdateChecklist(2, true, 1) 
        
        Citizen.Wait(2000)
        -- Update Main Task 2, Sub Task 2
        Interface.UpdateChecklist(2, true, 2)

        Citizen.Wait(2000)
        -- Update Main Task 2, Sub Task 1
        Interface.UpdateChecklist(2, true, 1) 
        
        Citizen.Wait(2000)
        -- Update Main Task 2, Sub Task 2
        Interface.UpdateChecklist(2, true, 2)
        
        Citizen.Wait(1000)
        -- Mark Main Task 2 as complete (optional, visual preference)
        Interface.UpdateChecklist(2, true)
    end)
end)

]]