Hunter = {
    samples = {},       -- amostras periodicas
    slowQueries = {},   -- linhas de query lenta vistas no console
    resEvents = {},     -- start/stop de resources
    pending = {},       -- hitches capturados pelo listener (processados em thread)
    lastDiscord = 0,
}

local RES = GetCurrentResourceName()

local function push(list, item, max)
    list[#list + 1] = item
    if #list > max then table.remove(list, 1) end
end

local function sample()
    local byScript, total = {}, { peds = 0, vehicles = 0, objects = 0 }
    local budget = Config.MaxEntitiesPerSample

    local function scan(list, key)
        total[key] = #list
        for _, ent in ipairs(list) do
            if budget <= 0 then return end
            budget = budget - 1
            local script = GetEntityScript(ent) or '(sem script)'
            byScript[script] = (byScript[script] or 0) + 1
        end
    end

    scan(GetAllVehicles(), 'vehicles')
    scan(GetAllPeds(), 'peds')
    scan(GetAllObjects(), 'objects')

    push(Hunter.samples, {
        t = os.time(),
        players = GetNumPlayerIndices(),
        entities = total,
        byScript = byScript,
    }, Config.SampleHistory)
end

local STATE_FILE = 'data/last_state.json'

local function writeState(clean)
    local st = {
        t = os.time(), clean = clean == true,
        samples = {}, slowQueries = Hunter.slowQueries, resEvents = Hunter.resEvents,
    }
    local n = #Hunter.samples
    for i = math.max(1, n - 5), n do st.samples[#st.samples + 1] = Hunter.samples[i] end
    SaveResourceFile(RES, STATE_FILE, json.encode(st), -1)
end

function Hunter.snapshot()
    sample()
    pcall(writeState, false)
    return Hunter.samples[#Hunter.samples]
end

CreateThread(function()
    Wait(5000)
    while true do
        local ok, err = pcall(sample)
        if not ok then Utils.log('erro na amostragem: ' .. tostring(err)) end
        pcall(writeState, false)
        Wait(Config.SampleInterval * 1000)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == RES then pcall(writeState, true) end
end)
AddEventHandler('txAdmin:events:serverShuttingDown', function() pcall(writeState, true) end)
AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    if type(data) == 'table' and (tonumber(data.secondsRemaining) or 99) <= 1 then pcall(writeState, true) end
end)

RegisterConsoleListener(function(channel, message)
    local line = Utils.stripColors(message)
    if line == '' or line:find('[hitchhunter]', 1, true) then return end

    local kind, ms = line:match('(%a+) thread hitch warning.-interval of (%d+)')
    if kind then
        Hunter.pending[#Hunter.pending + 1] = { kind = kind, ms = tonumber(ms), t = os.time() }
        return
    end

    local res, qms = line:match('([%w_%-%.]+) took ([%d%.]+)%s*ms')
    if res and line:lower():find('quer') then
        push(Hunter.slowQueries, {
            t = os.time(), resource = res, ms = tonumber(qms), line = line:sub(1, 300),
        }, 100)
    end
end)

AddEventHandler('onServerResourceStart', function(name)
    push(Hunter.resEvents, { t = os.time(), resource = name, action = 'start' }, 100)
end)
AddEventHandler('onServerResourceStop', function(name)
    push(Hunter.resEvents, { t = os.time(), resource = name, action = 'stop' }, 100)
end)

local function buildSuspects(now)
    local score, evidence = {}, {}
    local function add(resource, pts, text)
        if resource == RES or Settings.isIgnored(resource) then return end
        score[resource] = (score[resource] or 0) + pts
        evidence[resource] = evidence[resource] or {}
        evidence[resource][#evidence[resource] + 1] = text
    end

    -- 1) Entidades: tamanho atual e crescimento vs. amostra mais antiga da janela
    local last = Hunter.samples[#Hunter.samples]
    local first
    for _, s in ipairs(Hunter.samples) do
        if now - s.t <= Config.ContextSeconds then first = s break end
    end
    if last then
        for script, n in pairs(last.byScript) do
            local before = (first and first.byScript[script]) or 0
            local growth = n - before
            if growth >= 20 then
                -- evidencias sao estruturadas ({k=chave, a=, b=, s=}); a NUI traduz (PT-BR / EN-US)
                add(script, math.min(40, growth / 5), { k = 'ent_growth', a = growth, b = n })
            elseif n >= 150 then
                add(script, math.min(15, n / 50), { k = 'ent_total', a = n })
            end
        end
    end

    -- 2) Queries lentas recentes
    local qAgg = {}
    for _, q in ipairs(Hunter.slowQueries) do
        if now - q.t <= Config.ContextSeconds then
            local a = qAgg[q.resource] or { n = 0, max = 0 }
            a.n, a.max = a.n + 1, math.max(a.max, q.ms)
            qAgg[q.resource] = a
        end
    end
    for r, a in pairs(qAgg) do
        add(r, math.min(40, a.n * 4 + a.max / 20), { k = 'queries', a = a.n, b = math.floor(a.max) })
    end

    -- 3) Resources iniciados/parados na janela (start/stop pesado causa hitch)
    for _, e in ipairs(Hunter.resEvents) do
        if now - e.t <= 30 then
            add(e.resource, 25, { k = 'res_action', s = e.action, a = now - e.t })
        end
    end

    local out = {}
    for r, s in pairs(score) do
        out[#out + 1] = { resource = r, score = math.floor(s * 10) / 10, evidence = evidence[r], source = 'heuristica' }
    end
    table.sort(out, function(a, b) return a.score > b.score end)
    return out
end

-- Mescla resultado do profiler (mais confiavel) no incidente
function applyProfile(incident, top, err)
    if not top then
        incident.profiler = { error = err or 'sem dados' }
    else
        incident.profiler = { top = top }
        local total = 0
        for _, r in ipairs(top) do total = total + r.ms end
        for _, r in ipairs(top) do
            local found
            for _, s in ipairs(incident.suspects) do
                if s.resource == r.resource then found = s break end
            end
            local pts = total > 0 and (r.ms / total) * 100 or 0
            local text = { k = 'prof_cpu', a = r.ms, s = r.heaviest }
            if found then
                found.score = math.floor((found.score + pts) * 10) / 10
                found.evidence[#found.evidence + 1] = text
                found.source = 'profiler+heuristica'
            else
                incident.suspects[#incident.suspects + 1] = {
                    resource = r.resource, score = math.floor(pts * 10) / 10,
                    evidence = { text }, source = 'profiler',
                }
            end
        end
        table.sort(incident.suspects, function(a, b) return a.score > b.score end)
    end
    Storage.save()
end

---------------------------------------------------------------------
-- Criacao de incidentes
---------------------------------------------------------------------
local function notifyDiscord(incident)
    local d = Config.Discord
    if not d.enabled or d.webhook == '' then return end
    if incident.maxMs < d.minHitchMs or os.time() - Hunter.lastDiscord < d.cooldown then return end
    Hunter.lastDiscord = os.time()
    local top = incident.suspects[1]
    PerformHttpRequest(d.webhook, function() end, 'POST', json.encode({
        embeds = {{
            title = ('%s thread hitch: %dms'):format(incident.kind, incident.maxMs),
            description = top
                and (Utils.L('Suspeito principal: **%s** (score %.1f)', 'Main suspect: **%s** (score %.1f)')):format(top.resource, top.score)
                or Utils.L('Sem suspeito claro.', 'No clear suspect.'),
            color = 9133302,
            footer = { text = 'piercer_hitchhunter' },
        }},
    }), { ['Content-Type'] = 'application/json' })
end

local function handleHitch(h)
    if h.ms < Config.MinHitchMs then return end

    local last = Storage.incidents[#Storage.incidents]
    if last and last.kind == h.kind and h.t - last.lastAt <= Config.MergeWindow then
        last.count = last.count + 1
        last.lastAt = h.t
        last.maxMs = math.max(last.maxMs, h.ms)
        Storage.save()
        return
    end

    local snap = Hunter.samples[#Hunter.samples]
    local incident = {
        id = ('%d-%d'):format(h.t, math.random(1000, 9999)),
        kind = h.kind,
        at = h.t, lastAt = h.t, iso = Utils.iso(h.t),
        count = 1, maxMs = h.ms,
        players = snap and snap.players or GetNumPlayerIndices(),
        entities = snap and snap.entities or nil,
        suspects = buildSuspects(h.t),
        slowQueries = {}, resourceEvents = {},
    }
    for _, q in ipairs(Hunter.slowQueries) do
        if h.t - q.t <= Config.ContextSeconds then incident.slowQueries[#incident.slowQueries + 1] = q end
    end
    for _, e in ipairs(Hunter.resEvents) do
        if h.t - e.t <= Config.ContextSeconds then incident.resourceEvents[#incident.resourceEvents + 1] = e end
    end

    Storage.incidents[#Storage.incidents + 1] = incident
    Storage.save()
    local top = incident.suspects[1]
    Utils.log(('%s hitch de %dms | suspeito: %s'):format(h.kind, h.ms, top and top.resource or 'nenhum claro'))
    notifyDiscord(incident)

    if Profiler.canAutoRun() then
        Profiler.run(function(topProf, err) applyProfile(incident, topProf, err) end)
    end
end

-- Se a execucao anterior nao terminou de forma limpa, registra uma "possivel queda"
-- com os suspeitos calculados a partir do ultimo estado gravado.
local function recoverCrash()
    if not Config.CrashDetection then return end
    local raw = LoadResourceFile(RES, STATE_FILE)
    if not raw or raw == '' then return end
    local ok, st = pcall(json.decode, raw)
    if not ok or type(st) ~= 'table' or st.clean or not st.t then return end

    Hunter.samples, Hunter.slowQueries, Hunter.resEvents = st.samples or {}, st.slowQueries or {}, st.resEvents or {}
    local suspects = buildSuspects(st.t)
    local last = Hunter.samples[#Hunter.samples]
    local incident = {
        id = ('%d-crash'):format(st.t), kind = 'crash',
        at = st.t, lastAt = st.t, iso = Utils.iso(st.t),
        count = 1, maxMs = 0,
        players = last and last.players or 0,
        entities = last and last.entities or nil,
        suspects = suspects,
        slowQueries = {}, resourceEvents = {},
        note = 'crash_note', -- chave traduzida pela NUI
    }
    for _, q in ipairs(Hunter.slowQueries) do
        if st.t - q.t <= Config.ContextSeconds then incident.slowQueries[#incident.slowQueries + 1] = q end
    end
    for _, e in ipairs(Hunter.resEvents) do
        if st.t - e.t <= Config.ContextSeconds then incident.resourceEvents[#incident.resourceEvents + 1] = e end
    end
    Hunter.samples, Hunter.slowQueries, Hunter.resEvents = {}, {}, {}

    Storage.incidents[#Storage.incidents + 1] = incident
    Storage.save()
    Utils.log(('^3possivel queda detectada^7 (ultimo sinal %s) | suspeito: %s'):format(
        incident.iso, suspects[1] and suspects[1].resource or 'nenhum claro'))
end

CreateThread(function()
    Storage.load()
    Settings.load()
    local ok, err = pcall(recoverCrash)
    if not ok then Utils.log('erro ao verificar queda anterior: ' .. tostring(err)) end
    pcall(writeState, false)
    while true do
        Wait(250)
        if #Hunter.pending > 0 then
            local batch = Hunter.pending
            Hunter.pending = {}
            for _, h in ipairs(batch) do
                local ok, err = pcall(handleHitch, h)
                if not ok then Utils.log('erro ao tratar hitch: ' .. tostring(err)) end
            end
        end
    end
end)

---------------------------------------------------------------------
-- Comandos de console
---------------------------------------------------------------------
RegisterCommand('hitch_profile', function(src)
    if src ~= 0 then return end
    local last = Storage.incidents[#Storage.incidents]
    local ok, err = Profiler.run(function(top, e)
        if last then applyProfile(last, top, e) end
        Utils.log(top and 'profiler concluido, veja o painel.' or ('profiler falhou: ' .. tostring(e)))
    end)
    Utils.log(ok and 'gravando profiler...' or tostring(err))
end, true)

RegisterCommand('hitch_status', function(src)
    if src ~= 0 then return end
    Utils.log(('%d incidentes guardados, %d amostras, %d queries lentas na memoria'):format(
        #Storage.incidents, #Hunter.samples, #Hunter.slowQueries))
end, true)
