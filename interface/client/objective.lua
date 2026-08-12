local currentData = { title = "", text = "", visible = false, invoked = nil }

-- Updated to accept colors argument (table)
Interface.ShowObjective = function(text, title, position, colors)
    local invoked = GetInvokingResource()
    Interface.HideObjective()

    currentData.invoked = invoked
    currentData.text = text
    currentData.title = title or Config.Defaults.Objective.title
    currentData.visible = true

    local pos = position or Config.Defaults.Objective.position
    
    -- Ensure colors is a table or nil
    local customColors = nil
    if type(colors) == 'table' then
        customColors = colors
    end

    local hour = GetClockHours()
    local isNight = Config.Defaults.Objective.nightEffect and (hour >= 21 or hour < 6)

    SendNUIMessage({
        action = 'updateObjective',
        data = {
            type = 'set',
            text = currentData.text,
            title = currentData.title,
            position = pos,
            visible = true,
            isNight = isNight,
            colors = customColors -- Pass colors to NUI
        }
    })
end

Interface.HideObjective = function()
    currentData.visible = false
    SendNUIMessage({
        action = 'updateObjective',
        data = { visible = false }
    })
end

AddEventHandler('onResourceStop', function( resourceName )
    if currentData.visible and currentData.invoked == resourceName then
        Interface.HideObjective()
    end
end)

exports('ShowObjective', Interface.ShowObjective)
exports('HideObjective', Interface.HideObjective)

Lib47.ShowObjective = Interface.ShowObjective
Lib47.HideObjective = Interface.HideObjective

--[[
local text = {
    {
        Title = "Zone Controls",
        List = {
            "Add Point <m>1<m>",
            "Undo Last Point <m>2<m>",
            "Zone Height <m>3<m>",
        }
    },
    {
        Title = "Camera Controls",
        List = {
            "<m><m> & <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
            "Move UP <k>Q<k>",
            "Move Down <k>E<k>",
        }
    },
    { "Cancel Creation <k>DEL<k>" } -- This renders as footer text
}

local colors = {
    colorPrimary = "rgba(0, 0, 255, 0.8)",     -- Background
    colorSecondery = "#00FF00",                -- Borders/Headers (Note spelling matches prompt)
    colorText = "#FFFFFF"                      -- Content Text
}

CreateThread(function( ... )
    Wait(2000)
    Lib47.ShowObjective(text, "Editor Mode", "center", colors)
end)

local text2 = {
    Title = "Quick Menu",
    List = {
        "Option One <m>1<m>",
        "Option Two <m>2<m>"
    }
}
Lib47.ShowObjective(text2, "Menu", "right")


local text3 = {
    "Collect the evidence",
    "Escape the police"
}
Lib47.ShowObjective(text3, "Current Task", "top")

local text4 = "Collect the evidence"
Lib47.ShowObjective(text4, "Current Task", "top")
]]