Config = {}

Config.Language = 'pt-BR'

Config.Permissions = {
    bridge = { 'admin', 'Admin', 'admin.acess', 'superadmin', 'owner' },
    ace = { 'piercer_hitchhunter.use' },
    identifiers = {},
}
Config.IngameIncidentLimit = 60

Config.Actions = {
    pollMs = 2000,
    commandTtl = 60,
    restartResource = false,
    protected = { 'framezero_bridge', 'oxmysql', 'monitor', 'sessionmanager', 'mapmanager', 'spawnmanager', 'chat' },
}

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
