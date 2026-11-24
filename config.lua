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
Config.MinHitchMs = 100
Config.MergeWindow = 10
Config.MaxIncidents = 200
Config.SampleInterval = 10
Config.SampleHistory = 30
Config.MaxEntitiesPerSample = 4000
Config.ContextSeconds = 120

Config.Profiler = {
    enabled = true,
    frames = 300,
    cooldown = 120,
    outputFile = 'cache/piercer_hitchhunter_profile.json',
    waitSeconds = 12,
    maxEvents = 200000,
}

Config.Discord = {
    enabled = false,
    webhook = '',
    cooldown = 300,
    minHitchMs = 300,
}
