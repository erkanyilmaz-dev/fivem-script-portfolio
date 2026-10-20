fx_version 'cerulean'
game 'gta5'

author 'Vater Scripts'
description 'Premium QBCore garage system for WraithPVP'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/*.png'
}

dependencies {
    'qb-core',
    'oxmysql'
}
