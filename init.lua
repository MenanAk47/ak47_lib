-- ak47_lib consumer bootstrap (ox_lib style).
-- fxmanifest.lua:
--   dependency 'ak47_lib'
--   shared_scripts { '@ak47_lib/init.lua' }
--   files { 'locales/*.json' }
-- Gives you: Lib47 + locale(key, ...) + getLocale() + setLocale(lang).
-- locales/en.json example: { "greeting": "Hello {name}! {welcome}" } -> locale('greeting', { name = 'John' })
-- locales/en.json example: { "welcome": "Hello %s!" } -> locale('welcome', 'John')

if not Lib47 then
    Lib47 = exports.ak47_lib:GetLibObject()
end

if not locale then
    locale = function(key, ...)
        return Lib47.Translate(key, ...)
    end
end

if not getLocale then
    getLocale = function()
        return Lib47.GetLocale()
    end
end

if not setLocale then
    setLocale = function(lang)
        return Lib47.SetLocale(lang)
    end
end
