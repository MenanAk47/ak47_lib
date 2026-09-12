local dicts = {}
local langs = {}

local function GetCaller()
    local invoking = GetInvokingResource()
    if invoking and invoking ~= '' then return invoking end
    return GetCurrentResourceName()
end

local function Flatten(source, target, prefix)
    for key, value in pairs(source) do
        local fullKey = prefix and (prefix .. '.' .. key) or key
        if type(value) == 'table' then
            Flatten(value, target, fullKey)
        else
            target[fullKey] = value
        end
    end
    return target
end

local function LoadDict(resource, lang)
    local path = GetResourceMetadata(resource, 'locales_path', 0) or 'locales'

    local function readFile(key)
        local raw = LoadResourceFile(resource, ('%s/%s.json'):format(path, key))
        if not raw then return nil end
        local ok, decoded = pcall(json.decode, raw)
        if not ok or type(decoded) ~= 'table' then
            print(('^1[Lib47 Error] Invalid JSON in %s/%s/%s.json^0'):format(resource, path, key))
            return nil
        end
        return Flatten(decoded, {})
    end

    -- en.json is the base; the active language is merged on top per-key,
    -- so partially translated files fall back to English keys.
    local dict = readFile('en') or {}
    if lang ~= 'en' then
        local extra = readFile(lang)
        if extra then
            for key, value in pairs(extra) do dict[key] = value end
        else
            print(('^1[Lib47 Error] Locale \'%s\' missing for %s, using \'en\'^0'):format(lang, resource))
        end
    end

    if next(dict) == nil then
        print(('^1[Lib47 Error] No locales found for resource %s^0'):format(resource))
    end
    return dict
end

Lib47.GetLocale = function(resource)
    if type(resource) ~= 'string' then resource = GetCaller() end
    if langs[resource] then return langs[resource] end
    local default = 'en'
    if Config.Locale and type(Config.Locale.Default) == 'string' then
        default = Config.Locale.Default
    end
    return GetConvar('ak47_lib:locale', default)
end

Lib47.GetLocaleDict = function(resource)
    if type(resource) ~= 'string' then resource = GetCaller() end
    local lang = Lib47.GetLocale(resource)
    local cacheKey = resource .. ':' .. lang
    if not dicts[cacheKey] then
        dicts[cacheKey] = LoadDict(resource, lang)
    end
    return dicts[cacheKey]
end

Lib47.SetLocale = function(lang, resource)
    if type(lang) ~= 'string' or lang == '' then return false end
    if type(resource) ~= 'string' then resource = GetCaller() end
    langs[resource] = lang
    dicts[resource .. ':' .. lang] = nil
    TriggerEvent('ak47_lib:setLocale', resource, lang)
    return true
end

Lib47.Translate = function(key, placeholders, ...)
    if type(key) ~= 'string' then return key end
    local str = Lib47.GetLocaleDict()[key]
    if type(str) ~= 'string' then return key end
    if type(placeholders) == 'table' then
        str = str:gsub('{(%w+)}', function(name)
            local value = placeholders[name]
            if value == nil then return '{' .. name .. '}' end
            return tostring(value)
        end)
    elseif placeholders ~= nil or select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, placeholders, ...)
        if ok then str = formatted end
    end
    return str
end

locale = function(key, ...)
    return Lib47.Translate(key, ...)
end

getLocale = function()
    return Lib47.GetLocale()
end

setLocale = function(lang)
    return Lib47.SetLocale(lang)
end
