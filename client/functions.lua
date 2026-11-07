Functions.GetInventoryCounts = function(items)
    local counts = {}
    local itemData = {} -- Store one instance of item data for the event return

    if not items then return counts, itemData end

    for _, item in pairs(items) do
        if item and item.name then
            counts[item.name] = (counts[item.name] or 0) + (item.amount or item.count)
            if not itemData[item.name] then
                itemData[item.name] = item
            end
        end
    end
    return counts, itemData
end

Functions.HasAnyItemRemoved = function(oldItems, newItems)
    local oldCounts, oldData = Functions.GetInventoryCounts(oldItems)
    local newCounts, _ = Functions.GetInventoryCounts(newItems)

    for name, oldAmount in pairs(oldCounts) do
        local newAmount = newCounts[name] or 0
        if newAmount < oldAmount then
            local itemInfo = oldData[name]
            TriggerEvent('ak47_lib:OnRemoveItem', name, newAmount)
        end
    end
end

Functions.FormatJobData = function( data )
    if not data or not data.name then return {} end
    local job = {}
    
    job.name = data.name
    job.label = data.label
    job.payment = data.grade_salary or data.payment or 0
    job.onduty = data.onDuty ~= nil and data.onDuty or (data.onduty ~= nil and data.onduty or true)
    job.type = data.type or 'none'
    
    job.isboss = data.grade_name == 'boss' or (data.isboss == true)

    job.grade = {}
    if type(data.grade) == 'table' then
        job.grade.name = data.grade.name or data.grade_label
        job.grade.level = data.grade.level or data.grade.grade or 0
    else
        job.grade.name = data.grade_label
        job.grade.level = data.grade
    end

    return job
end
