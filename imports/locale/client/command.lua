RegisterCommand('ak47locale', function(_, args)
    local lang = args[1]
    if not lang or lang == '' or not setLocale(lang) then
        Lib47.Notify(locale('command.locale_usage'), 'error')
        return
    end
    Lib47.Notify(locale('command.locale_changed', { lang = lang }), 'success')
end, false)
