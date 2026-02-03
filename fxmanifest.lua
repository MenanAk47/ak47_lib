fx_version 'adamant'
game 'gta5'
description 'Ak47 Bridge'
author 'MenanAk47'
version '1.0.3'

--ui_page 'web/index.html'
ui_page 'http://localhost:5173'

files {
    'web/index.html',
    'web/**/*',
}

shared_scripts {
    "config.lua",
    "@ox_lib/init.lua",
}

client_scripts {
    "store/**/client/*.lua",
    "framework/**/client/*.lua",
    "integration/client/*.lua",
    "interface/client/*.lua",

    "client/*.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    
    "store/**/server/*.lua",
    "framework/**/server/*.lua",
    "integration/server/*.lua",
    "interface/server/*.lua",

    "server/*.lua",
}

escrow_ignore {
    "**/*",
}

lua54 'yes'

dependencies {
    'ox_lib',
}
