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
            TriggerEvent('ak47_bridge:OnRemoveItem', name, newAmount) -- will be removed soon
        end
    end
end

Functions.FormatJobData = function( data )
    local job = {}
    
    job.name = data.name
    job.label = data.label
    job.payment = data.grade_salary
    
    job.isboss = data.grade_name == 'boss'

    job.grade = {}
    job.grade.name = data.grade_label
    job.grade.level = data.grade

    return job
end

