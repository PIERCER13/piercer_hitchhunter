fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'piercer_hitchhunter'
description 'Detecta e atribui "network thread hitch warning" a resources suspeitos, com NUI in-game e painel web'
author 'piercer'
version '1.1.0'

-- Obrigatorio: a bridge resolve permissoes e notificacoes em qualquer base.
-- No server.cfg: ensure framezero_bridge  (antes deste resource)
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
