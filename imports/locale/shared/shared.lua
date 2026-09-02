--[[
    Locale module for ak47_lib (Lib47).

    Usage:
        Shared side loaded automatically by fxmanifest globs.
        - Resources should expose `locales/<lang>.json` (or set Lib47.Locale.Path).
        - On the client, `Lib47.Locale.Load()` is auto-called at start so `Lib47.Locale('key')` works immediately.
        - Server resources should call `Lib47.Locale.Load()` themselves if they need server-side translations.

    Convar:
        ak47_lib:locale   (default 'en')
]]

---@field GetKey fun():string
---@field Load fun(key?: string)
---@field Set fun(key: string)
---@field Translate fun(key: string, ...: string|number): string
local L = {}
Lib47.Locale = L

L.Dict = {}
L.Path = 'locales'

--- Flatten a nested table into a dotted-key dict.
---@param source table
---@param target table
---@param prefix? string
local function flatten(source, target, prefix)
    for key, value in pairs(source) do
        local fullKey = prefix and (prefix .. '.' .. key) or key
        if type(value) == 'table' then
            flatten(value, target, fullKey)
        else
            target[fullKey] = value
        end
    end
    return target
end

--- Translate a key. Falls back to the key itself when missing.
---@param key string
---@vararg string|number
---@return string
function L.Translate(key, ...)
    local str = L.Dict[key]
    if not str then return key end
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

-- Friendly call shorthand: `L('ui.shop.welcome', playerName)`.
setmetatable(L, {
    __call = function(_, key, ...)
        return L.Translate(key, ...)
    end,
})

--- Deep-merge `src` into `dst`. Leaf values in `src` win.
local function deepMerge(dst, src)
    for k, v in pairs(src) do
        if type(v) == 'table' and type(dst[k]) == 'table' then
            deepMerge(dst[k], v)
        else
            dst[k] = v
        end
    end
end

--- Load a locale JSON file from the calling resource. Falls back to 'en' when language missing.
---@param key? string  language key; nil = use GetKey()
function L.Load(key)
    local lang = key or (L.GetKey and L.GetKey()) or 'en'

    local function read(langKey)
        return LoadResourceFile(cache.resource, ('%s/%s.json'):format(L.Path, langKey))
    end

    local enRaw = read('en') or '{}'
    local data = json.decode(enRaw) or {}

    if lang ~= 'en' then
        local raw = read(lang)
        if raw then
            local extra = json.decode(raw) or {}
            deepMerge(data, extra)
        else
            warn(("ak47_lib: locale '%s' missing for '%s', falling back to 'en'"):format(lang, cache.resource))
        end
    end

    -- wipe previous dict entries
    for k in pairs(L.Dict) do L.Dict[k] = nil end

    local flat = flatten(data, {})
    -- collect keys first; we mutate values below and must not iterate the table while doing so.
    local keys = {}
    for k in pairs(flat) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do
        local v = flat[k]
        if type(v) == 'string' then
            -- inline variable interpolation: ${other.key}
            for var in v:gmatch('${[%w%._]+}') do
                local ref = flat[var:sub(3, -2)]
                if ref and type(ref) == 'string' then
                    v = (v:gsub(var, (ref:gsub('%%', '%%%%'))))
                end
            end
        end
        L.Dict[k] = v
    end
end