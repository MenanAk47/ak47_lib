local glm = require 'glm'
local isServer = IsDuplicityVersion()
local isClient = not isServer

Lib47.Zones = {}
local Zones = {}
local zoneCounter = 0

-- State tables
local insideZones = isClient and {} or nil
local exitingZones = isClient and {} or nil
local enteringZones = isClient and {} or nil
local nearbyZones = {}

-- ==========================================
-- Spatial Grid Math (Map Boundaries)
-- ==========================================
local mapMinX = -3700
local mapMinY = -4400
local mapMaxX = 4500
local mapMaxY = 8000
local xDelta = (mapMaxX - mapMinX) / 34
local yDelta = (mapMaxY - mapMinY) / 50
local grid = {}
local gridCache = {}
local entrySet = {}

local function getGridDimensions(point, length, width)
    local minX = (point.x - width - mapMinX) // xDelta
    local maxX = (point.x + width - mapMinX) // xDelta
    local minY = (point.y - length - mapMinY) // yDelta
    local maxY = (point.y + length - mapMinY) // yDelta

    return minX, maxX, minY, maxY
end

local function addZoneToGrid(entry)
    entry.gridLength = entry.length or (entry.radius * 2)
    entry.gridWidth = entry.width or (entry.radius * 2)
    local minX, maxX, minY, maxY = getGridDimensions(entry.coords, entry.gridLength, entry.gridWidth)

    for y = minY, maxY do
        local row = grid[y] or {}

        for x = minX, maxX do
            local cell = row[x] or {}
            cell[#cell + 1] = entry
            row[x] = cell
        end

        grid[y] = row
    end
    table.wipe(gridCache)
end

local function removeZoneFromGrid(entry)
    local minX, maxX, minY, maxY = getGridDimensions(entry.coords, entry.gridLength, entry.gridWidth)

    for y = minY, maxY do
        local row = grid[y]
        if row then
            for x = minX, maxX do
                local cell = row[x]
                if cell then
                    for i = 1, #cell do
                        if cell[i] == entry then
                            table.remove(cell, i)
                            break
                        end
                    end
                    if #cell == 0 then row[x] = nil end
                end
            end
            if not next(row) then grid[y] = nil end
        end
    end
    table.wipe(gridCache)
end

local function getNearbyGridEntries(point)
    local minX, maxX, minY, maxY = getGridDimensions(point, xDelta, yDelta)

    if gridCache.minX == minX and gridCache.maxX == maxX and gridCache.minY == minY and gridCache.maxY == maxY then
        return gridCache.entries, gridCache.count
    end

    local entries = {}
    local n = 0
    table.wipe(entrySet)

    for y = minY, maxY do
        local row = grid[y]
        if row then
            for x = minX, maxX do
                local cell = row[x]
                if cell then
                    for j = 1, #cell do
                        local entry = cell[j]
                        if not entrySet[entry] then
                            n = n + 1
                            entrySet[entry] = true
                            entries[n] = entry
                        end
                    end
                end
            end
        end
    end

    gridCache.minX = minX
    gridCache.maxX = maxX
    gridCache.minY = minY
    gridCache.maxY = maxY
    gridCache.entries = entries
    gridCache.count = n

    return entries, n
end

-- ==========================================
-- Utility Functions
-- ==========================================
local function convertToVector(coords)
    local _type = type(coords)
    if _type == 'vector3' then return coords end
    if _type == 'table' or _type == 'vector4' then
        return vec3(coords[1] or coords.x, coords[2] or coords.y, coords[3] or coords.z)
    end
    error(("^1[ak47_lib] expected type 'vector3' or 'table' (received %s)^0"):format(_type))
end

local function getSafeZCoord(points)
    local zCounts = {}
    for i = 1, #points do
        local z = points[i].z
        zCounts[z] = (zCounts[z] or 0) + 1
    end

    local sortedZ = {}
    for z, count in pairs(zCounts) do sortedZ[#sortedZ + 1] = { coord = z, count = count } end
    table.sort(sortedZ, function(a, b) return a.count > b.count end)

    local zCoord = sortedZ[1].coord
    local averageTo = 1

    for i = 1, #sortedZ do
        if sortedZ[i].count < sortedZ[1].count then
            averageTo = i - 1
            break
        end
    end

    if averageTo > 1 then
        for i = 2, averageTo do zCoord = zCoord + sortedZ[i].coord end
        zCoord = zCoord / averageTo
    end

    return zCoord
end

-- ==========================================
-- CZone Metatable
-- ==========================================
local CZone = {}
CZone.__index = CZone

function CZone:remove()
    Zones[self.id] = nil
    if isClient then removeZoneFromGrid(self) end

    if isServer then return end

    if insideZones[self.id] then insideZones[self.id] = nil end
    
    for i = #exitingZones, 1, -1 do 
        if exitingZones[i] == self then table.remove(exitingZones, i) end 
    end
    for i = #enteringZones, 1, -1 do 
        if enteringZones[i] == self then table.remove(enteringZones, i) end 
    end
    for i = #nearbyZones, 1, -1 do 
        if nearbyZones[i] == self then table.remove(nearbyZones, i) end 
    end
end

function CZone:contains(coords, updateDistance)
    coords = convertToVector(coords or (isClient and GetEntityCoords(PlayerPedId()) or vec3(0,0,0)))
    local dist = #(self.coords - coords)
    
    if updateDistance then self.distance = dist end

    if self.__type == 'sphere' then
        return dist < self.radius
    else
        return glm.polygon.contains(self.polygon, coords, self.thickness / 4)
    end
end

function CZone:setDebug(enable, colour)
    if isServer then return end

    if not enable and insideZones[self.id] then 
        insideZones[self.id] = nil 
    end

    self.debugColour = enable and {
        r = glm.tointeger(colour and colour.r or self.debugColour and self.debugColour.r or 255),
        g = glm.tointeger(colour and colour.g or self.debugColour and self.debugColour.g or 42),
        b = glm.tointeger(colour and colour.b or self.debugColour and self.debugColour.b or 24),
        a = glm.tointeger(colour and colour.a or self.debugColour and self.debugColour.a or 100)
    } or nil

    self.debug = enable or nil
end

-- ==========================================
-- Zone Registration
-- ==========================================
local function setZone(data)
    zoneCounter = zoneCounter + 1
    data.id = zoneCounter
    data.distance = 0.0
    data.insideZone = false
    
    -- Track which resource created this zone
    data.resource = GetInvokingResource() or GetCurrentResourceName()

    setmetatable(data, CZone)

    if isClient and data.debug then
        data.debug = nil
        data:setDebug(true, data.debugColour)
    elseif isServer then
        data.debug = nil
    end

    Zones[data.id] = data
    if isClient then addZoneToGrid(data) end

    return data
end

-- ==========================================
-- Constructors
-- ==========================================
function Lib47.Zones.Poly(data)
    data.thickness = data.thickness or 4.0
    local pointN = #data.points
    local points = table.create(pointN, 0)

    for i = 1, pointN do points[i] = convertToVector(data.points[i]) end

    data.polygon = glm.polygon.new(points)

    if not data.polygon:isPlanar() then
        local safeZ = getSafeZCoord(points)
        for i = 1, pointN do points[i] = vec3(data.points[i].xy, safeZ) end
        data.polygon = glm.polygon.new(points)
    end

    data.coords = data.polygon:centroid()
    data.__type = 'poly'
    
    local maxRadius = 0
    for i = 1, pointN do
        local dist = #(points[i] - data.coords)
        if dist > maxRadius then maxRadius = dist end
    end
    data.radius = maxRadius

    return setZone(data)
end

function Lib47.Zones.Box(data)
    data.coords = convertToVector(data.coords)
    data.size = data.size and (convertToVector(data.size) / 2) or vec3(2.0, 2.0, 2.0)
    data.thickness = data.size.z * 2
    data.rotation = quat(data.rotation or 0, vec3(0, 0, 1))
    data.__type = 'box'
    data.width = data.size.x * 2
    data.length = data.size.y * 2
    data.polygon = (data.rotation * glm.polygon.new({
        vec3(data.size.x, data.size.y, 0),
        vec3(-data.size.x, data.size.y, 0),
        vec3(-data.size.x, -data.size.y, 0),
        vec3(data.size.x, -data.size.y, 0),
    }) + data.coords)

    data.radius = #(vec3(data.size.x, data.size.y, 0))

    return setZone(data)
end

function Lib47.Zones.Sphere(data)
    data.coords = convertToVector(data.coords)
    data.radius = (data.radius or 2.0) + 0.0
    data.__type = 'sphere'

    return setZone(data)
end

function Lib47.Zones.getAllZones() return Zones end
function Lib47.Zones.getCurrentZones() return insideZones end
function Lib47.Zones.getNearbyZones() return nearbyZones end

-- ==========================================
-- Client Loop
-- ==========================================
if isClient then
    local function drawDebug(zone)
        local c = zone.debugColour
        if zone.__type == 'sphere' then
            DrawMarker(28, zone.coords.x, zone.coords.y, zone.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, zone.radius, zone.radius, zone.radius, c.r, c.g, c.b, c.a, false, false, 0, false, false, false, false)
        else
            local p = zone.polygon
            local zOffset = vec3(0, 0, zone.thickness / 2)
            for i = 1, #p do
                local topA = p[i] + zOffset
                local btmA = p[i] - zOffset
                local topB = (p[i + 1] or p[1]) + zOffset
                local btmB = (p[i + 1] or p[1]) - zOffset

                DrawLine(topA.x, topA.y, topA.z, btmA.x, btmA.y, btmA.z, c.r, c.g, c.b, 255)
                DrawLine(topA.x, topA.y, topA.z, topB.x, topB.y, topB.z, c.r, c.g, c.b, 255)
                DrawLine(btmA.x, btmA.y, btmA.z, btmB.x, btmB.y, btmB.z, c.r, c.g, c.b, 255)
            end
        end
    end

    CreateThread(function()
        while true do
            local coords = GetEntityCoords(PlayerPedId())
            local newNearby, newCount = getNearbyGridEntries(coords)
            
            for i = 1, #nearbyZones do
                local zone = nearbyZones[i]
                local stillNearby = false
                for j = 1, newCount do
                    if newNearby[j] == zone then stillNearby = true break end
                end
                
                if zone.insideZone and not stillNearby then
                    zone.insideZone = false
                    insideZones[zone.id] = nil
                    if zone.onExit then exitingZones[#exitingZones + 1] = zone end
                end
            end
            
            nearbyZones = newNearby

            for i = 1, newCount do
                local zone = nearbyZones[i]
                local contains = zone:contains(coords, true)

                if contains then
                    if not zone.insideZone then
                        zone.insideZone = true
                        if zone.onEnter then enteringZones[#enteringZones + 1] = zone end
                        if zone.inside or zone.debug then insideZones[zone.id] = zone end
                    end
                else
                    if zone.insideZone then
                        zone.insideZone = false
                        insideZones[zone.id] = nil
                        if zone.onExit then exitingZones[#exitingZones + 1] = zone end
                    end
                    if zone.debug then insideZones[zone.id] = zone end
                end
            end

            local exitingSize = #exitingZones
            local enteringSize = #enteringZones

            if exitingSize > 0 then
                table.sort(exitingZones, function(a, b) return a.distance < b.distance end)
                for i = exitingSize, 1, -1 do exitingZones[i]:onExit() end
                for i = 1, exitingSize do exitingZones[i] = nil end
            end

            if enteringSize > 0 then
                table.sort(enteringZones, function(a, b) return a.distance < b.distance end)
                for i = 1, enteringSize do enteringZones[i]:onEnter() end
                for i = 1, enteringSize do enteringZones[i] = nil end
            end

            Wait(300)
        end
    end)

    CreateThread(function()
        while true do
            local sleep = 1000
            if next(insideZones) then
                sleep = 0
                for _, zone in pairs(insideZones) do
                    if zone.debug then
                        drawDebug(zone)
                        if zone.inside and zone.insideZone then zone:inside() end
                    else
                        zone:inside()
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

-- ==========================================
-- Resource Cleanup Handler
-- ==========================================
AddEventHandler('onResourceStop', function(resourceName)
    for _, zone in pairs(Zones) do
        if zone.resource == resourceName then
            zone:remove()
        end
    end
end)