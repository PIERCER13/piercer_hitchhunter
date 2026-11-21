Config = {}

-- Idioma das mensagens do servidor (notificacoes e Discord): 'pt-BR' ou 'en-US'.
-- A NUI tem seletor proprio (PT-BR / EN-US) e lembra a escolha de cada pessoa.
Config.Language = 'pt-BR'

-- Comando in-game: /hitchhunter. Quem pode usar (qualquer uma das regras libera):
Config.Permissions = {
    -- Grupos/permissoes/jobs da sua base, resolvidos pelo framezero_bridge
    -- (vRP: permissao; QBCore/Qbox: grupo; ESX: grupo; ACE/standalone: ver abaixo).
    bridge = { 'admin', 'Admin', 'admin.acess', 'superadmin', 'owner' },
    -- ACE nativo. No server.cfg: add_ace group.admin piercer_hitchhunter.use allow
    ace = { 'piercer_hitchhunter.use' },
    -- Identificadores fixos, ex.: 'license:abc123', 'discord:123'
    identifiers = {},
}
Config.IngameIncidentLimit = 60

-- Acoes remotas (painel web e NUI): fila em data/commands.json lida pelo resource.
Config.Actions = {
    pollMs = 2000,
    commandTtl = 60,          -- comandos mais velhos que isso (s) sao descartados
    -- Permite "Reiniciar resource" nos suspeitos. DESLIGADO por padrao: derruba o resource de verdade.
    restartResource = false,
    -- Nunca podem ser reiniciados pelo painel (o proprio hitchhunter ja e protegido).
    protected = { 'framezero_bridge', 'oxmysql', 'monitor', 'sessionmanager', 'mapmanager', 'spawnmanager', 'chat' },
}

-- Ao iniciar, se o encerramento anterior nao foi limpo (queda/crash), registra um incidente
-- "queda" com os suspeitos do ultimo estado gravado. Reinicios normais pelo txAdmin nao contam.
Config.CrashDetection = true

-- Hitches abaixo disso (ms) sao ignorados.
Config.MinHitchMs = 100

-- Hitches dentro dessa janela (segundos) viram o mesmo incidente.
Config.MergeWindow = 10

-- Maximo de incidentes guardados em data/incidents.json.
Config.MaxIncidents = 200

-- Amostragem periodica (entidades por resource criador, jogadores).
Config.SampleInterval = 10   -- segundos
Config.SampleHistory = 30    -- amostras mantidas (~5 min)
Config.MaxEntitiesPerSample = 4000 -- teto para nao pesar com muitos peds/veiculos

-- Janela de contexto anexada a cada incidente.
Config.ContextSeconds = 120

Config.Profiler = {
    enabled = true,
    -- Ao detectar hitch, grava N frames do profiler nativo e le o resultado.
    frames = 300,
    cooldown = 120,           -- segundos entre gravacoes automaticas
    -- Caminho relativo a pasta do servidor. VALIDAR no seu servidor.
    outputFile = 'cache/piercer_hitchhunter_profile.json',
    waitSeconds = 12,         -- espera a gravacao terminar antes de ler
    maxEvents = 200000,
}

Config.Discord = {
    enabled = false,
    webhook = '',
    cooldown = 300,           -- segundos entre alertas
    minHitchMs = 300,
}
