Lib47.Points = {}
local activePoints = {}
local nearbyPoints = {}
local nearbyCount = 0
local closestPoint = nil
local tickActive = false

function Lib47.Points.New(data)
    local id = data.id or (#activePoints + 1)
    local invokingResource = GetInvokingResource() or GetCurrentResourceName()
    
    local point = {
        id = id,
        resource = invokingResource,
        coords = vec3(data.coords.x, data.coords.y, data.coords.z),
        distance = data.distance or 2.0,
        onEnter = data.onEnter,
        onExit = data.onExit,
        nearby = data.nearby,
        isInside = false,
        isClosest = false,
        currentDistance = nil
    }

    for k, v in pairs(data) do
        if point[k] == nil then
            point[k] = v
        end
    end

    function point:remove()
        activePoints[self.id] = nil
        
        if closestPoint and closestPoint.id == self.id then
            closestPoint = nil
        end
        
        for i = 1, nearbyCount do
            if nearbyPoints[i].id == self.id then
                table.remove(nearbyPoints, i)
                nearbyCount = nearbyCount - 1
                break
            end
        end
    end

    activePoints[id] = point
    return point
end

Citizen.CreateThread(function()
    while true do
        local plyCoords = GetEntityCoords(PlayerPedId())
        local tempNearby = {}
        local tempCount = 0
        
        closestPoint = nil

        for id, point in pairs(activePoints) do
            local dist = #(plyCoords - point.coords)

            if point.distance and dist <= point.distance then
                point.currentDistance = dist
                tempCount = tempCount + 1
                tempNearby[tempCount] = point

                if not closestPoint or dist < closestPoint.currentDistance then
                    if closestPoint then closestPoint.isClosest = false end
                    point.isClosest = true
                    closestPoint = point
                end


                if not point.isInside then
                    point.isInside = true
                    if point.onEnter then 
                        pcall(function() point:onEnter() end) 
                    end
                end
            else
                if point.isInside then
                    point.isInside = false
                    point.isClosest = false
                    point.currentDistance = nil
                    if point.onExit then 
                        pcall(function() point:onExit() end)
                    end
                end
            end
        end

        nearbyPoints = tempNearby
        nearbyCount = tempCount

        if nearbyCount > 0 and not tickActive then
            tickActive = true
            
            Citizen.CreateThread(function()
                while tickActive do
                    for i = 1, nearbyCount do
                        local p = nearbyPoints[i]
                        if p and p.nearby then
                            pcall(function() p:nearby() end)
                        end
                    end
                    
                    if nearbyCount == 0 then
                        tickActive = false
                    end
                    
                    Citizen.Wait(0)
                end
            end)
        elseif nearbyCount == 0 then
            tickActive = false
        end

        Citizen.Wait(300)
    end
end)

function Lib47.Points.GetAll() return activePoints end
function Lib47.Points.GetNearby() return nearbyPoints end
function Lib47.Points.GetClosest() return closestPoint end

AddEventHandler('onResourceStop', function(resourceName)
    for id, point in pairs(activePoints) do
        if point.resource == resourceName then
            point:remove()
        end
    end
end)