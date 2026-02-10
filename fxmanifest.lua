fx_version 'adamant'
game 'gta5'
description 'Ak47 Lib'
author 'MenanAk47'
version '1.0.5'

--ui_page 'web/index.html'
ui_page 'http://localhost:5173'

files {
    'web/index.html',
    'web/**/*',
}

shared_scripts {
    "config.lua",
    "store/**/shared/*.lua",
    "imports/**/shared/*.lua",
}

client_scripts {
    "imports/**/client/*.lua",
    "framework/**/client/*.lua",
    "integration/client/*.lua",
    "interface/client/*.lua",

    "client/*.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    
    "imports/**/server/*.lua",
    "framework/**/server/*.lua",
    "integration/server/*.lua",
    "interface/server/*.lua",

    "server/*.lua",
}

escrow_ignore {
    "**/*",
}

lua54 'yes'

provides {
    'ak47_bridge'
}
