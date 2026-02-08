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