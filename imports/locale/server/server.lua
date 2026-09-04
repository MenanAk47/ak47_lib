-- Server-side locale helpers.
-- Resolves the active language from a convar. Server-side Load is not auto-run so it doesn't
-- waste memory loading every consumer's JSON. Resources should call Load() themselves if
-- they need server-side translations.



---@return string
function Lib47.Locale.GetKey()
    return GetConvar('ak47_lib:locale', 'en')

end