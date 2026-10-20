fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Vater Scripts'
description 'Vater Mechanic - Ultra-Advanced Vehicle Customization, Tuning & Diagnostics System'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/tr.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/camera.lua',
    'client/mods.lua',
    'client/nui.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    'oxmysql'
}
