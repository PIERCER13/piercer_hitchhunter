fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'piercer_hitchhunter'
author 'piercer'

dependency 'framezero_bridge'

ui_page 'web/index.html'

client_script 'client/main.lua'

server_scripts {
    '@framezero_bridge/import.lua',
    'config.lua',
    'server/utils.lua',
    'server/auth.lua',
    'server/storage.lua',
    'server/settings.lua',
    'server/profiler.lua',
    'server/main.lua',
    'server/commands.lua',
    'server/api.lua',
    'server/ingame.lua',
}

files {
    'web/index.html',
}
