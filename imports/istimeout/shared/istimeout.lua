Lib47.IsTimeOut = function(timeout)
    local startTime = GetGameTimer()
    
    return function()
        return (GetGameTimer() - startTime) > tonumber(timeout)
    end
end