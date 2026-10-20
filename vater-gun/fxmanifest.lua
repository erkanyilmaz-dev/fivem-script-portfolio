fx_version 'cerulean'
game 'gta5'

name 'vater-silahci'
author 'VaterPVP'
description 'Advanced QBCore Call of Duty Gunsmith Weapon Modification & Custom Skin Generator'
version '1.3.0'

dependencies {
    'qb-core',
    'qb-inventory',
    'qb-weapons',
    'oxmysql'
}

ui_page 'ui/index.html'

shared_scripts {
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
    'ui/index.html',
    'ui/camo_canvas.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/bg.png',
    'ui/assets/camos/*.gif',
    'ui/assets/camos/*.png',
    'ui/assets/camos/*.jpg',
    'ui/assets/camos/*.jpeg',
    'ui/assets/camos/*.webp',
    'ui/assets/camos/**/*'
}

lua54 'yes'
