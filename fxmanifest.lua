fx_version 'cerulean'
game 'gta5'

description 'Brozovec'
author 'CarThief'
version '3.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua',
    '@nwrp_core'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua'
}

client_scripts {
    'client/cl_main.lua',
}



lua54 'yes'