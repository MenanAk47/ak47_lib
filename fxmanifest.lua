fx_version 'adamant'
game 'gta5'
description 'Ak47 Bridge'
author 'MenanAk47'
version '1.0.0'

shared_scripts {
    "config.lua",
    "@ox_lib/init.lua",
}

client_scripts {
    "framework/**/client/*.lua",
    "integration/client/*.lua",
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    
    "framework/**/server/*.lua",
    "integration/server/*.lua",
}

escrow_ignore {
    "**/*",
}

lua54 'yes'

dependencies {
    'ox_lib',
}
