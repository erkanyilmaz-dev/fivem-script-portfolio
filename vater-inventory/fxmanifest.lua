fx_version 'cerulean'
game 'gta5'

name        'vaterpvp-inventory'
author      'VaterPVP'
description 'VaterPVP QB-Core Inventory System'
version     '3.0.0'

dependencies {
    'qb-core',
    'oxmysql',
}

ui_page 'ui/inventory.html'

files {
    'ui/inventory.html',
    'ui/style_v2.css',
    'ui/script_v2.js',
    'ui/icons/weapon_combatpistol.png',
    'ui/icons/pistol_ammo.png',
    'ui/icons/heavyarmor.png',
    'ui/icons/medkit.png',
    'ui/icons/radio.png'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
