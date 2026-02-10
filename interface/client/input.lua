local inputPromise = nil
local inputState = { visible = false, invoked = nil }

Interface.ShowInput = function(heading, rows, options)
    if inputPromise then return nil end

    inputState.invoked = GetInvokingResource()
    inputState.visible = true

    options = options or {}

    if options.allowCancel == nil then 
        options.allowCancel = true 
    end

    if options.colors == nil then 
        options.colors = Config.Defaults.InputDialog.colors 
    end

    if options.borders == nil then 
        options.borders = Config.Defaults.InputDialog.borders 
    end

    if options.size == nil then 
        options.size = Config.Defaults.InputDialog.size 
    end
    
    inputPromise = promise.new()
    
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'OPEN_INPUT_DIALOG',
        heading = heading,
        rows = rows,
        options = options
    })

    local result = Citizen.Await(inputPromise)
    
    SetNuiFocus(false, false)
    inputPromise = nil
    
    return result
end

Interface.HideInput = function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_INPUT_DIALOG' })
    if inputPromise then inputPromise:resolve(nil) end
end

RegisterNUICallback('submitInput', function(data, cb)
    if inputPromise then 
        inputPromise:resolve(data) 
    end
    cb('ok')
end)

RegisterNUICallback('cancelInput', function(_, cb)
    if inputPromise then 
        inputPromise:resolve(nil) 
    end
    cb('ok')
end)

exports('ShowInput', Interface.ShowInput)
exports('HideInput', Interface.HideInput)

AddEventHandler('onResourceStop', function(resourceName)
    if inputState.visible and inputState.invoked == resourceName then
        Interface.HideInput()
    end
end)


RegisterCommand('testinput', function()
    Citizen.CreateThread(function()
        local input = Interface.ShowInput('Employee Registration', {
            {
                type = "input",
                label = "Full Name",
                placeholder = "John Doe",
                icon = "fa-user",
                required = true,
                minLength = 3
            },
            {
                type = "number",
                label = "Age",
                min = 18,
                max = 99,
                required = true,
                icon = "fa-calendar-days"
            },
            {
                type = "select",
                label = "Department",
                options = {
                    { label = "Police", value = "police" },
                    { label = "Medical", value = "ems" },
                    { label = "Civilian", value = "civ" }
                },
                required = true
            },
            {
                type = "multi-select",
                label = "Licenses",
                options = {
                    { label = "Drive", value = "drive" },
                    { label = "Weapon", value = "weapon" },
                    { label = "Pilot", value = "fly" }
                }
            },
            {
                type = "date-range",
                label = "Contract Period",
                required = true
            },
            {
                type = "checkbox",
                label = "Agree to Terms and Conditions",
                required = true
            }
        }, {
            allowCancel = true,
            size = 'md'
        })

        if input then
            print('Input Result:', json.encode(input))
        end
    end)
end)