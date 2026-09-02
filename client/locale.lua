-- User-facing locale switch command.

if Config.Locale.AllowClientSwitch then
    RegisterCommand('ak47locale', function(_, args)
        local key = args[1]
        if not key or key == '' then
            Lib47.Notify(GetCurrentResourceName(), 'usage: /ak47locale <lang>', 'error')
            return
        end
        Lib47.Locale.Set(key)
        Lib47.Notify(GetCurrentResourceName(), ('locale -> %s'):format(key), 'success', 3000)
    end, false)
end