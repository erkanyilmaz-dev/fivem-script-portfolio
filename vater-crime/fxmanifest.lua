fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Erkan'
description 'VATER SCRIPTS - 3D Scene Reconstruction / Holographic Replay System'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql'
}
