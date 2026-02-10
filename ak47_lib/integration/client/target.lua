local registered = {}

local function getLabels(options)
    local labels = {}
    local items = options
    
    if options.options then
        items = options.options
    end

    for _, v in pairs(items) do
        if type(v) == 'table' and v.label then
            labels[#labels+1] = v.label
        end
    end
    return labels
end

local function register(resource, type, data)
    if not resource then return end
    if not registered[resource] then registered[resource] = {} end
    table.insert(registered[resource], { type = type, data = data })
end

local function convert(options)
    local distance = options.distance
    options = options.options

    for k, v in pairs(options) do
        if type(k) ~= 'number' then
            table.insert(options, v)
        end
    end

    for id, v in pairs(options) do
        if type(id) ~= 'number' then
            options[id] = nil
            goto continue
        end

        v.onSelect = v.action
        v.distance = v.distance or distance
        v.name = v.name or v.label
        v.items = v.item
        v.icon = v.icon
        v.groups = v.job

        local groupType = type(v.groups)
        if groupType == 'nil' then
            v.groups = {}
            groupType = 'table'
        end
        if groupType == 'string' then
            local val = v.gang
            if type(v.gang) == 'table' then
                if table.type(v.gang) ~= 'array' then
                    val = {}
                    for k in pairs(v.gang) do
                        val[#val + 1] = k
                    end
                end
            end

            if val then
                v.groups = {v.groups, type(val) == 'table' and table.unpack(val) or val}
            end

            val = v.citizenid
            if type(v.citizenid) == 'table' then
                if table.type(v.citizenid) ~= 'array' then
                    val = {}
                    for k in pairs(v.citizenid) do
                        val[#val+1] = k
                    end
                end
            end

            if val then
                v.groups = {v.groups, type(val) == 'table' and table.unpack(val) or val}
            end
        elseif groupType == 'table' then
            local val = {}
            if table.type(v.groups) ~= 'array' then
                for k in pairs(v.groups) do
                    val[#val + 1] = k
                end
                v.groups = val
                val = nil
            end

            val = v.gang
            if type(v.gang) == 'table' then
                if table.type(v.gang) ~= 'array' then
                    val = {}
                    for k in pairs(v.gang) do
                        val[#val + 1] = k
                    end
                end
            end

            if val then
                v.groups = {table.unpack(v.groups), type(val) == 'table' and table.unpack(val) or val}
            end

            val = v.citizenid
            if type(v.citizenid) == 'table' then
                if table.type(v.citizenid) ~= 'array' then
                    val = {}
                    for k in pairs(v.citizenid) do
                        val[#val+1] = k
                    end
                end
            end

            if val then
                v.groups = {table.unpack(v.groups), type(val) == 'table' and table.unpack(val) or val}
            end
        end

        if type(v.groups) == 'table' and table.type(v.groups) == 'empty' then
            v.groups = nil
        end

        if v.event and v.type and v.type ~= 'client' then
            if v.type == 'server' then
                v.serverEvent = v.event
            elseif v.type == 'command' then
                v.command = v.event
            end

            v.event = nil
            v.type = nil
        end

        v.action = nil
        v.job = nil
        v.gang = nil
        v.citizenid = nil
        v.item = nil
        v.qtarget = true

        ::continue::
    end

    return options
end

Lib47.AddBoxZone = function(name, center, length, width, options, targetoptions)
    local resource = GetInvokingResource()
    if GetResourceState('ox_target') == 'started' then
        local z = center.z
        if not options.minZ then options.minZ = -100 end
        if not options.maxZ then options.maxZ = 800 end
        if not options.useZ then
            z = z + math.abs(options.maxZ - options.minZ) / 2
            center = vec3(center.x, center.y, z)
        end
        local id = exports.ox_target:addBoxZone({
            name = name,
            coords = center,
            size = vec3(width, length, (options.useZ or not options.maxZ) and center.z or math.abs(options.maxZ - options.minZ)),
            debug = options.debugPoly,
            rotation = options.heading,
            options = convert(targetoptions),
        })
        register(resource, 'zone', id)
        return id
    elseif GetResourceState('qb-target') == 'started' then
        local id = exports['qb-target']:AddBoxZone(name, center, length, width, options, targetoptions)
        register(resource, 'zone', name)
        return id
    elseif GetResourceState('qtarget') == 'started' then
        local id = exports['qtarget']:AddBoxZone(name, center, length, width, options, targetoptions)
        register(resource, 'zone', name)
        return id
    end
end

Lib47.AddPolyZone = function(name, points, options, targetoptions)
    local resource = GetInvokingResource()
    if GetResourceState('ox_target') == 'started' then
        local newPoints = table.create(#points, 0)
        local thickness = math.abs(options.maxZ - options.minZ)
        for i = 1, #points do
            local point = points[i]
            newPoints[i] = vec3(point.x, point.y, options.maxZ - (thickness / 2))
        end
        local id = exports.ox_target:addPolyZone({
            name = name,
            points = newPoints,
            thickness = thickness,
            debug = options.debugPoly,
            options = convert(targetoptions),
        })
        register(resource, 'zone', id)
        return id
    elseif GetResourceState('qb-target') == 'started' then
        local id = exports['qb-target']:AddPolyZone(name, points, options, targetoptions)
        register(resource, 'zone', name)
        return id
    elseif GetResourceState('qtarget') == 'started' then
        local id = exports['qtarget']:AddPolyZone(name, points, options, targetoptions)
        register(resource, 'zone', name)
        return id
    end
end

Lib47.AddCircleZone = function(name, center, radius, options, targetoptions)
    local resource = GetInvokingResource()
    if GetResourceState('ox_target') == 'started' then
        local id = exports.ox_target:addSphereZone({
            name = name,
            coords = center,
            radius = radius,
            debug = options.debugPoly,
            options = convert(targetoptions),
        })
        register(resource, 'zone', id)
        return id
    elseif GetResourceState('qb-target') == 'started' then
        local id = exports['qb-target']:AddCircleZone(name, center, radius, options, targetoptions)
        register(resource, 'zone', name)
        return id
    elseif GetResourceState('qtarget') == 'started' then
        local id = exports['qtarget']:AddCircleZone(name, center, radius, options, targetoptions)
        register(resource, 'zone', name)
        return id
    end
end

Lib47.RemoveZone = function(id)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeZone(id, true)
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:RemoveZone(id.name or id)
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:RemoveZone(id.name or id)
    end
end

Lib47.AddTargetBone = function(bones, options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)
    
    if GetResourceState('ox_target') == 'started' then
        if type(bones) ~= 'table' then bones = { bones } end
        options = convert(options)
        for _, v in pairs(options) do
            v.bones = bones
        end
        exports.ox_target:addGlobalVehicle(options)
        register(resource, 'globalVehicle', { labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetBone(bones, options)
        register(resource, 'bone', { bones = bones, labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddTargetBone(bones, options)
        register(resource, 'bone', { bones = bones, labels = labels })
    end
end

Lib47.AddTargetEntity = function(entities, options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        if type(entities) ~= 'table' then entities = { entities } end
        options = convert(options)
        for i = 1, #entities do
            local entity = entities[i]
            if NetworkGetEntityIsNetworked(entity) then
                exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(entity), options)
            else
                exports.ox_target:addLocalEntity(entity, options)
            end
        end
        register(resource, 'entity', { entities = entities, labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetEntity(entities, options)
        register(resource, 'entity', { entities = entities, labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddTargetEntity(entities, options)
        register(resource, 'entity', { entities = entities, labels = labels })
    end
end

Lib47.RemoveTargetEntity = function(entities, labels)
    if GetResourceState('ox_target') == 'started' then
        if type(entities) ~= 'table' then entities = { entities } end
        for i = 1, #entities do
            local entity = entities[i]
            if NetworkGetEntityIsNetworked(entity) then
                exports.ox_target:removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
            else
                exports.ox_target:removeLocalEntity(entity, labels)
            end
        end
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveTargetEntity(entities, labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveTargetEntity(entities, labels)
    end
end

Lib47.AddTargetModel = function(models, options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addModel(models, convert(options))
        register(resource, 'model', { models = models, labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetModel(models, options)
        register(resource, 'model', { models = models, labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddTargetModel(models, options)
        register(resource, 'model', { models = models, labels = labels })
    end
end

Lib47.RemoveTargetModel = function(models, labels)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeModel(models, labels)
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveTargetModel(models, labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveTargetModel(models, labels)
    end
end

Lib47.AddGlobalPed = function(options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalPed(convert(options))
        register(resource, 'globalPed', { labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddGlobalPed(options)
        register(resource, 'globalPed', { labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddGlobalPed(options)
        register(resource, 'globalPed', { labels = labels })
    end
end

Lib47.RemoveGlobalPed = function(labels)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeGlobalPed(labels)
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveGlobalPed(labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveGlobalPed(labels)
    end
end

Lib47.AddGlobalVehicle = function(options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalVehicle(convert(options))
        register(resource, 'globalVehicle', { labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddGlobalVehicle(options)
        register(resource, 'globalVehicle', { labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddGlobalVehicle(options)
        register(resource, 'globalVehicle', { labels = labels })
    end
end

Lib47.RemoveGlobalVehicle = function(labels)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeGlobalVehicle(labels)
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveGlobalVehicle(labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveGlobalVehicle(labels)
    end
end

Lib47.AddGlobalObject = function(options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalObject(convert(options))
        register(resource, 'globalObject', { labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddGlobalObject(options)
        register(resource, 'globalObject', { labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddGlobalObject(options)
        register(resource, 'globalObject', { labels = labels })
    end
end

Lib47.RemoveGlobalObject = function(labels)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeGlobalObject(labels)
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveGlobalObject(labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveGlobalObject(labels)
    end
end

Lib47.AddGlobalPlayer = function(options)
    local resource = GetInvokingResource()
    local labels = getLabels(options)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalPlayer(convert(options))
        register(resource, 'globalPlayer', { labels = labels })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddGlobalPlayer(options)
        register(resource, 'globalPlayer', { labels = labels })
    elseif GetResourceState('qtarget') == 'started' then
        exports['qtarget']:AddGlobalPlayer(options)
        register(resource, 'globalPlayer', { labels = labels })
    end
end

Lib47.RemoveGlobalPlayer = function(labels)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeGlobalPlayer(labels)
    elseif GetResourceState('qb-target') == 'started' then
        return exports['qb-target']:RemoveGlobalPlayer(labels)
    elseif GetResourceState('qtarget') == 'started' then
        return exports['qtarget']:RemoveGlobalPlayer(labels)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if not registered[resource] then return end
    
    for _, item in ipairs(registered[resource]) do
        local type = item.type
        local data = item.data

        if type == 'zone' then
            Lib47.RemoveZone(data)
        elseif type == 'model' then
            Lib47.RemoveTargetModel(data.models, data.labels)
        elseif type == 'entity' then
            Lib47.RemoveTargetEntity(data.entities, data.labels)
        elseif type == 'globalPed' then
            Lib47.RemoveGlobalPed(data.labels)
        elseif type == 'globalVehicle' then
            Lib47.RemoveGlobalVehicle(data.labels)
        elseif type == 'globalObject' then
            Lib47.RemoveGlobalObject(data.labels)
        elseif type == 'globalPlayer' then
            Lib47.RemoveGlobalPlayer(data.labels)
        elseif type == 'bone' then
            if GetResourceState('qb-target') == 'started' then
                exports['qb-target']:RemoveTargetBone(data.bones, data.labels)
            elseif GetResourceState('qtarget') == 'started' then
                exports['qtarget']:RemoveTargetBone(data.bones, data.labels)
            end
        end
    end

    registered[resource] = nil
end)