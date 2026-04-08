Lib47.Routing = {
    Player_Buckets = {},
    Entity_Buckets = {}
}

Lib47.SetPlayerBucket = function(source, bucket)
    if source and bucket then
        local plicense = Lib47.GetLicense(source)
        Player(source).state:set('instance', bucket, true)
        SetPlayerRoutingBucket(source, bucket)
        Lib47.Routing.Player_Buckets[plicense] = { id = source, bucket = bucket }
        return true
    end
    return false
end

Lib47.SetEntityBucket = function(entity, bucket)
    if entity and bucket then
        SetEntityRoutingBucket(entity, bucket)
        Lib47.Routing.Entity_Buckets[entity] = { id = entity, bucket = bucket }
        return true
    end
    return false
end

Lib47.GetPlayersInBucket = function(bucket)
    local curr_bucket_pool = {}
    if next(Lib47.Routing.Player_Buckets) then
        for _, v in pairs(Lib47.Routing.Player_Buckets) do
            if v.bucket == bucket then table.insert(curr_bucket_pool, v.id) end
        end
    end
    return next(curr_bucket_pool) and curr_bucket_pool or false
end

Lib47.GetEntitiesInBucket = function(bucket)
    local curr_bucket_pool = {}
    if next(Lib47.Routing.Entity_Buckets) then
        for _, v in pairs(Lib47.Routing.Entity_Buckets) do
            if v.bucket == bucket then table.insert(curr_bucket_pool, v.id) end
        end
    end
    return next(curr_bucket_pool) and curr_bucket_pool or false
end