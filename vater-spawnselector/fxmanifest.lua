fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Antigravity'
description 'VaterPVP Premium Spawn Selector'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html'
}
