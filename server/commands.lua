-- Acoes remotas. Duas entradas, mesma whitelist:
--   1) NUI in-game  -> Actions.run (apos checar permissao em Auth)
--   2) Painel web   -> fila data/commands.json (o painel escreve, este resource le a cada ~2s)
-- Nada aqui executa texto livre: so as acoes de `handlers`, com argumentos validados.
--
-- Cada handler devolve (ok, chave, dados). A chave e traduzida pela NUI (PT-BR / EN-US),
-- por isso nao ha texto em idioma nenhum aqui.
Actions = {}

local RES = GetCurrentResourceName()
local handlers = {}

local function validName(s)
    return type(s) == 'string' and #s > 0 and #s <= 64 and s:match('^[%w_%-%.]+$') ~= nil
end

local function findIncident(id)
    if type(id) ~= 'string' then return nil end
    return Storage.find(id)
end

handlers.profile = function()
    local last = Storage.incidents[#Storage.incidents]
    local ok = Profiler.run(function(top, e)
        if last then applyProfile(last, top, e) end
    end)
    if not ok then return false, 'profiler_busy' end
    return true, last and 'profile_started' or 'profile_started_noinc'
end

handlers.clear = function()
    Storage.clear()
    return true, 'cleared'
end

handlers.snapshot = function()
    local s = Hunter.snapshot()
    if not s then return false, 'no_data' end
    local top = {}
    for _, row in ipairs(Utils.sortedPairs(s.byScript)) do
        if #top >= 3 then break end
        top[#top + 1] = ('%s (%d)'):format(row.key, row.value)
    end
    return true, 'snapshot', {
        players = s.players, peds = s.entities.peds, vehicles = s.entities.vehicles,
        objects = s.entities.objects, top = #top > 0 and table.concat(top, ', ') or '-',
    }
end

handlers.export = function()
    local file = ('data/report-%s.json'):format(os.date('%Y%m%d-%H%M%S'))
    local ok = SaveResourceFile(RES, file, json.encode(Storage.incidents, { indent = true }), -1)
    if not ok then return false, 'export_failed' end
    return true, 'exported', { file = ('%s/%s'):format(RES, file) }
end

handlers.ignore = function(args)
    if not validName(args.resource) then return false, 'invalid_resource' end
    Settings.ignore(args.resource)
    return true, 'ignored', { resource = args.resource }
end

handlers.unignore = function(args)
    if not validName(args.resource) then return false, 'invalid_resource' end
    Settings.unignore(args.resource)
    return true, 'unignored', { resource = args.resource }
end

handlers.note = function(args)
    local inc = findIncident(args.id)
    if not inc then return false, 'incident_not_found' end
    local text = tostring(args.text or ''):sub(1, 200)
    inc.userNote = text ~= '' and text or nil
    Storage.save()
    return true, 'note_saved'
end

handlers.resolve = function(args)
    local inc = findIncident(args.id)
    if not inc then return false, 'incident_not_found' end
    inc.resolved = not inc.resolved or nil
    Storage.save()
    return true, inc.resolved and 'resolved' or 'reopened'
end

handlers.restart_resource = function(args)
    if Config.Actions.restartResource ~= true then return false, 'restart_disabled' end
    local name = args.resource
    if not validName(name) then return false, 'invalid_resource' end
    if name == RES then return false, 'protected' end
    for _, p in ipairs(Config.Actions.protected) do
        if p == name then return false, 'protected' end
    end
    if GetResourceState(name) == 'missing' then return false, 'resource_missing' end
    ExecuteCommand(('restart %s'):format(name))
    return true, 'restart_sent', { resource = name }
end

-- Retorna (ok, chave, dados)
function Actions.run(action, args)
    local fn = type(action) == 'string' and handlers[action]
    if not fn then return false, 'unknown_action' end
    if type(args) ~= 'table' then args = {} end
    local ok, a, b, c = pcall(fn, args)
    if not ok then return false, 'error', { detail = tostring(a) } end
    return a == true, b, c
end

---------------------------------------------------------------------
-- Fila de comandos do painel web (arquivos)
---------------------------------------------------------------------
local CMD_FILE, RES_FILE = 'data/commands.json', 'data/results.json'
local seen, results, order = {}, {}, {}

local function readCommands()
    local raw = LoadResourceFile(RES, CMD_FILE)
    if not raw or raw == '' then return {} end
    local ok, list = pcall(json.decode, raw)
    return (ok and type(list) == 'table') and list or {}
end

local function record(id, ok, msg, data)
    results[id] = { ok = ok, msg = msg, data = data, t = os.time() }
    order[#order + 1] = id
    while #order > 50 do results[table.remove(order, 1)] = nil end
    SaveResourceFile(RES, RES_FILE, json.encode(results), -1)
end

CreateThread(function()
    Wait(3000)
    for _, c in ipairs(readCommands()) do   -- o que ja estava na fila antes de subir nao roda
        if type(c) == 'table' and type(c.id) == 'string' then seen[c.id] = true end
    end
    while true do
        for _, c in ipairs(readCommands()) do
            if type(c) == 'table' and type(c.id) == 'string' and not seen[c.id] then
                seen[c.id] = true
                local age = os.time() - (tonumber(c.at) or 0)
                if age > Config.Actions.commandTtl or age < -30 then
                    record(c.id, false, 'expired')
                else
                    local ok, msg, data = Actions.run(c.action, c.args)
                    record(c.id, ok, msg, data)
                end
            end
        end
        Wait(Config.Actions.pollMs)
    end
end)
