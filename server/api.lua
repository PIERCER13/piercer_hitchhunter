-- Leituras e acoes usadas pela NUI in-game (ingame.lua). Nao ha servidor HTTP: o painel web
-- (tools/start.bat) le os arquivos de data/ e envia acoes pela fila em commands.json.
Api = {}

local function topSuspect(inc)
    for _, s in ipairs(inc.suspects or {}) do
        if not Settings.isIgnored(s.resource) then return s end
    end
end

local function summary()
    local now = os.time()
    local day, maxMs, agg = 0, 0, {}
    for _, inc in ipairs(Storage.incidents) do
        if now - inc.at <= 86400 then
            day = day + 1
            maxMs = math.max(maxMs, inc.maxMs)
            local s = topSuspect(inc)
            if s then agg[s.resource] = (agg[s.resource] or 0) + 1 end
        end
    end
    local ranking = {}
    for _, row in ipairs(Utils.sortedPairs(agg)) do
        ranking[#ranking + 1] = { resource = row.key, incidents = row.value }
        if #ranking >= 8 then break end
    end
    return {
        incidents24h = day, maxMs24h = maxMs, ranking = ranking,
        total = #Storage.incidents, profilerBusy = Profiler.busy,
        players = GetNumPlayerIndices(), serverTime = os.time(),
    }
end

-- Retorna (httpCode, tabela). `limit` opcional; `args` = { action=, args= } para /api/action.
function Api.handle(path, method, limit, args)
    if path == '/api/summary' and method == 'GET' then
        return 200, summary()
    elseif path == '/api/settings' and method == 'GET' then
        return 200, Settings.public()
    elseif path == '/api/incidents' and method == 'GET' then
        local out = {}
        for i = #Storage.incidents, 1, -1 do
            out[#out + 1] = Storage.incidents[i]
            if limit and #out >= limit then break end
        end
        return 200, out
    elseif path == '/api/action' and method == 'POST' then
        local ok, msg, data = Actions.run(type(args) == 'table' and args.action, type(args) == 'table' and args.args)
        return 200, { ok = ok, msg = msg, data = data }
    end
    return 404, { error = 'not found' }
end
