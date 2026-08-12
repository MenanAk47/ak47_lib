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
local internalPolygons = {}
local internalRotations = {}

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
    if _type == 'vector2' then
        return vec3(coords.x, coords.y, 0.0)
    end
    if _type == 'table' or _type == 'vector4' then
        return vec3(coords[1] or coords.x, coords[2] or coords.y, coords[3] or coords.z or 0.0)
    end
    error(("^1[ak47_lib] expected type 'vector3' or 'table' (received %s)^0"):format(_type))
end

local function getSafeZCoord(points)
    local zCounts = {}
    for i = 1, #points do
        local z = points[i].z or 0.0
        zCounts[z] = (zCounts[z] or 0) + 1
    end

    local sortedZ = {}
    for z, count in pairs(zCounts) do sortedZ[#sortedZ + 1] = { coord = z, count = count } end
    table.sort(sortedZ, function(a, b) return a.count > b.count end)

    local zCoord = sortedZ[1] and sortedZ[1].coord or 0.0
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
    internalPolygons[self.id] = nil
    internalRotations[self.id] = nil
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

function CZone:destroy()
    self:remove()
end

function CZone:onPointInOut(fnPosition, cb)
    self.onEnter = function() cb(true) end
    self.onExit = function() cb(false) end
end

function CZone:contains(coords, updateDistance)
    coords = convertToVector(coords or (isClient and GetEntityCoords(PlayerPedId()) or vec3(0,0,0)))
    local dist = #(self.coords - coords)
    
    if updateDistance then self.distance = dist end

    if self.__type == 'sphere' then
        return dist < self.radius
    else
        local poly = internalPolygons[self.id] or self.polygon
        local result = glm.polygon.contains(poly, coords, self.thickness / 2)
        return result
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

    data.isPointInside = function(self, coords)
        local internalZone = Zones[self.id] or self
        return CZone.contains(internalZone, coords)
    end
    data.contains = function(self, coords, updateDistance)
        local internalZone = Zones[self.id] or self
        return CZone.contains(internalZone, coords, updateDistance)
    end
    data.destroy = function(self)
        local internalZone = Zones[self.id] or self
        CZone.remove(internalZone)
    end
    data.onPointInOut = function(self, fnPosition, cb)
        local internalZone = Zones[self.id]
        if internalZone then
            CZone.onPointInOut(internalZone, fnPosition, cb)
        end
    end

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

    local polygon = glm.polygon.new(points)

    if (data.minZ and data.maxZ) or not polygon:isPlanar() then
        local safeZ
        if data.minZ and data.maxZ then
            safeZ = data.minZ + (data.thickness / 2)
        else
            safeZ = getSafeZCoord(points)
        end
        for i = 1, pointN do points[i] = vec3(points[i].x, points[i].y, safeZ) end
        polygon = glm.polygon.new(points)
    end

    data.coords = polygon:centroid()
    data.__type = 'poly'
    
    local maxRadius = 0
    for i = 1, pointN do
        local dist = #(points[i] - data.coords)
        if dist > maxRadius then maxRadius = dist end
    end
    data.radius = maxRadius

    local zone = setZone(data)
    internalPolygons[zone.id] = polygon
    return zone
end

function Lib47.Zones.Box(data)
    data.coords = convertToVector(data.coords)
    data.size = data.size and (convertToVector(data.size) / 2) or vec3(2.0, 2.0, 2.0)
    data.thickness = data.size.z * 2
    data.rotation = quat(data.rotation or 0, vec3(0, 0, 1))
    data.__type = 'box'
    data.width = data.size.x * 2
    data.length = data.size.y * 2
    
    local polygon = (data.rotation * glm.polygon.new({
        vec3(data.size.x, data.size.y, 0),
        vec3(-data.size.x, data.size.y, 0),
        vec3(-data.size.x, -data.size.y, 0),
        vec3(data.size.x, -data.size.y, 0),
    }) + data.coords)

    data.radius = #(vec3(data.size.x, data.size.y, 0))
    local rot = data.rotation
    data.rotation = nil

    local zone = setZone(data)
    internalPolygons[zone.id] = polygon
    internalRotations[zone.id] = rot
    return zone
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
        local c = zone.debugColour or {r = 0, g = 255, b = 0, a = 100}
        local r, g, b, a = c.r or 0, c.g or 255, c.b or 0, c.a or 100
        if zone.__type == 'sphere' then
            DrawMarker(28, zone.coords.x, zone.coords.y, zone.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, zone.radius, zone.radius, zone.radius, r, g, b, a, false, false, 0, false, false, false, false)
        else
            local p = internalPolygons[zone.id] or zone.polygon
            if not p or #p == 0 then return end
            local minZ = (zone._polyCompat and zone._polyCompat.minZ) or zone.minZ
            local maxZ = (zone._polyCompat and zone._polyCompat.maxZ) or zone.maxZ
            local zOffset = vec3(0, 0, zone.thickness / 2)

            local center = zone.coords or vec3(0, 0, 0)
            local topCenter = vec3(center.x, center.y, maxZ or (center.z + (zone.thickness / 2)))
            local btmCenter = vec3(center.x, center.y, minZ or (center.z - (zone.thickness / 2)))

            for i = 1, #p do
                local pA = p[i]
                local pB = p[i + 1] or p[1]
                local topA, btmA, topB, btmB

                if minZ and maxZ then
                    topA = vec3(pA.x, pA.y, maxZ)
                    btmA = vec3(pA.x, pA.y, minZ)
                    topB = vec3(pB.x, pB.y, maxZ)
                    btmB = vec3(pB.x, pB.y, minZ)
                else
                    topA = pA + zOffset
                    btmA = pA - zOffset
                    topB = pB + zOffset
                    btmB = pB - zOffset
                end

                -- Wireframe Edges
                DrawLine(topA.x, topA.y, topA.z, btmA.x, btmA.y, btmA.z, r, g, b, 255)
                DrawLine(topA.x, topA.y, topA.z, topB.x, topB.y, topB.z, r, g, b, 255)
                DrawLine(btmA.x, btmA.y, btmA.z, btmB.x, btmB.y, btmB.z, r, g, b, 255)

                -- Poly Faces (Side Walls - 2-sided)
                DrawPoly(btmA.x, btmA.y, btmA.z, topA.x, topA.y, topA.z, topB.x, topB.y, topB.z, r, g, b, a)
                DrawPoly(btmA.x, btmA.y, btmA.z, topB.x, topB.y, topB.z, btmB.x, btmB.y, btmB.z, r, g, b, a)
                DrawPoly(topB.x, topB.y, topB.z, topA.x, topA.y, topA.z, btmA.x, btmA.y, btmA.z, r, g, b, a)
                DrawPoly(btmB.x, btmB.y, btmB.z, topB.x, topB.y, topB.z, btmA.x, btmA.y, btmA.z, r, g, b, a)

                -- Poly Faces (Top Roof & Bottom Floor)
                if #p >= 3 then
                    local faceA = math.floor(a * 0.7)
                    DrawPoly(topCenter.x, topCenter.y, topCenter.z, topA.x, topA.y, topA.z, topB.x, topB.y, topB.z, r, g, b, faceA)
                    DrawPoly(topB.x, topB.y, topB.z, topA.x, topA.y, topA.z, topCenter.x, topCenter.y, topCenter.z, r, g, b, faceA)
                    DrawPoly(btmCenter.x, btmCenter.y, btmCenter.z, btmB.x, btmB.y, btmB.z, btmA.x, btmA.y, btmA.z, r, g, b, faceA)
                    DrawPoly(btmA.x, btmA.y, btmA.z, btmB.x, btmB.y, btmB.z, btmCenter.x, btmCenter.y, btmCenter.z, r, g, b, faceA)
                end
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

            Wait(1000)
        end
    end)

    CreateThread(function()
        while true do
            local sleep = 1000
            for _, zone in pairs(Zones) do
                if zone.debug then
                    sleep = 0
                    drawDebug(zone)
                end
            end
            if next(insideZones) then
                sleep = 0
                for _, zone in pairs(insideZones) do
                    if zone.inside and zone.insideZone then
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

-- ==========================================
-- PolyZone Compatibility Wrapper
-- ==========================================
if not _G.PolyZone then
    _G.PolyZone = {
        getPlayerPosition = function()
            return GetEntityCoords(PlayerPedId())
        end
    }
    
    function PolyZone:Create(points, options)
        options = options or {}
        local minZ = options.minZ or (points[1] and points[1].z and (points[1].z - 2.0) or 0.0)
        local maxZ = options.maxZ or (points[1] and points[1].z and (points[1].z + 10.0) or 10.0)
        local thickness = maxZ - minZ

        local zone = Lib47.Zones.Poly({
            name = options.name or "polyzone_compat",
            points = points,
            thickness = thickness,
            debug = options.debugGrid or options.debugPoly,
            debugColour = {r = 0, g = 255, b = 0, a = 100}
        })

        zone.isPointInside = nil -- Override the one added by setZone if they want compat behavior, or leave it. Actually it's already bound to CZone.contains
        zone.destroy = nil
        
        zone._polyCompat = {
            minZ = minZ,
            maxZ = maxZ,
            points = points
        }
        
        local old_index = getmetatable(zone).__index
        setmetatable(zone, {
            __index = function(t, k)
                if k == 'minZ' or k == 'maxZ' or k == 'points' then
                    return t._polyCompat[k]
                end
                if type(old_index) == 'function' then
                    return old_index(t, k)
                elseif type(old_index) == 'table' then
                    return old_index[k]
                end
            end,
            __newindex = function(t, k, v)
                if k == 'minZ' or k == 'maxZ' then
                    t._polyCompat[k] = v
                    local thickness = t._polyCompat.maxZ - t._polyCompat.minZ
                    rawset(t, 'thickness', thickness)
                    
                    local newPoints = t._polyCompat.points
                    if newPoints and #newPoints > 2 then
                        local safeZ = t._polyCompat.minZ + (thickness / 2)
                        local rebuilt = {}
                        for i = 1, #newPoints do
                            local p = newPoints[i]
                            rebuilt[i] = vec3(p.x or p[1], p.y or p[2], safeZ)
                        end
                        local polygon = glm.polygon.new(rebuilt)
                        internalPolygons[t.id] = polygon
                        rawset(t, 'coords', polygon:centroid())
                    end
                elseif k == 'points' then
                    t._polyCompat.points = v
                    local newPoints = {}
                    for i = 1, #v do
                        local _type = type(v[i])
                        if _type == 'vector3' then 
                            newPoints[i] = v[i]
                        elseif _type == 'table' or _type == 'vector4' then
                            newPoints[i] = vec3(v[i][1] or v[i].x, v[i][2] or v[i].y, v[i][3] or v[i].z or t._polyCompat.minZ)
                        elseif _type == 'vector2' then
                            newPoints[i] = vec3(v[i].x, v[i].y, t._polyCompat.minZ + (t.thickness / 2))
                        else
                            newPoints[i] = vec3(0, 0, 0)
                        end
                    end
                    if #newPoints > 2 then
                        local polygon = glm.polygon.new(newPoints)
                        if not polygon:isPlanar() then
                            local safeZ = t._polyCompat.minZ + (t.thickness / 2)
                            for i = 1, #newPoints do newPoints[i] = vec3(newPoints[i].xy, safeZ) end
                            polygon = glm.polygon.new(newPoints)
                        end
                        if isClient then removeZoneFromGrid(t) end
                        internalPolygons[t.id] = polygon
                        rawset(t, 'coords', polygon:centroid())
                        local maxRadius = 0
                        for i = 1, #newPoints do
                            local dist = #(newPoints[i] - t.coords)
                            if dist > maxRadius then maxRadius = dist end
                        end
                        rawset(t, 'radius', maxRadius)
                        if isClient then addZoneToGrid(t) end
                    end
                else
                    rawset(t, k, v)
                end
            end
        })

        return zone
    end
end
