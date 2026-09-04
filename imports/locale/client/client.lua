-- Client-side locale: resolves current language, listens for runtime changes,
-- and forwards the active JSON to the NUI so the web layer can render translated strings.

---@return string
function Lib47.Locale.GetKey()
    -- Defaults to 'en' when no convar is set.
    return GetConvar('ak47_lib:locale', 'en')
end



-- Cache resource name once so we don't call `cache.resource` for every push.
local RESOURCE = cache.resource

local function loadLocaleFile(key)
    local raw = LoadResourceFile(RESOURCE, ('%s/%s.json'):format(Lib47.Locale.Path, key))
        or LoadResourceFile(RESOURCE, ('%s/%s.json'):format(Lib47.Locale.Path, 'en'))
    return raw and json.decode(raw) or {}
end

--- Push current locale JSON to NUI so UI strings stay in sync.
local function sendLocaleToNui()
    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(Lib47.Locale.GetKey()),
    })
end

--- Change the active locale at runtime. Reloads shared dict, notifies server event
--- (so server-side code can re-resolve), and pushes the new JSON to NUI.
---@param key string
function Lib47.Locale.Set(key)
    TriggerEvent('ak47_lib:setLocale', key)
    Lib47.Locale.Load(key)
    sendLocaleToNui()
end

-- Listen for locale changes triggered from any resource (e.g. an admin command).
AddEventHandler('ak47_lib:setLocale', function(key)
    Lib47.Locale.Load(key)
    sendLocaleToNui()
end)

-- NUI init handshake: when the web layer signals it's ready, push the current locale.
RegisterNUICallback('init', function(_, cb)
    cb(1)
    sendLocaleToNui()
end)

-- Auto-load at resource start so `L('key')` works immediately.
Lib47.Locale.Load()