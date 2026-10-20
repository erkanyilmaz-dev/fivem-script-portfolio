fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'VaterPVP Team'
description 'Realistic Bifold Leather Wallet HUD with Cards & Cash for QBCore'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*.png'
}
