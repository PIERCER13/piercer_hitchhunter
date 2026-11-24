Profiler = { busy = false, lastRun = 0 }

local function parseTrace(path)
    local f = io.open(path, 'rb')
    if not f then return nil, 'arquivo nao encontrado: ' .. path end
    local raw = f:read('*a')
    f:close()
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return nil, 'JSON invalido' end

    local events = data.traceEvents or data
    if type(events) ~= 'table' then return nil, 'formato inesperado' end

    local resources = Utils.resourceSet()
    local totals, byName, count = {}, {}, 0

    for _, ev in ipairs(events) do
        count = count + 1
        if count > Config.Profiler.maxEvents then break end
        local dur = tonumber(ev.dur)
        if dur and dur > 0 then
            local ms = dur / 1000.0
            local owner
            local args = type(ev.args) == 'table' and ev.args or {}
            local candidates = { args.resource, args.name, ev.cat, ev.name }
            for _, c in ipairs(candidates) do
                if type(c) == 'string' then
                    for token in c:gmatch('[%w_%-%.]+') do
                        if resources[token] then owner = token break end
                    end
                end
                if owner then break end
            end
            if owner then
                totals[owner] = (totals[owner] or 0) + ms
                local label = tostring(ev.name or '?')
                byName[owner] = byName[owner] or {}
                byName[owner][label] = (byName[owner][label] or 0) + ms
            end
        end
    end

    local top = {}
    for _, row in ipairs(Utils.sortedPairs(totals)) do
        if #top >= 15 then break end
        local heavy, best = '', 0
        for label, ms in pairs(byName[row.key]) do
            if ms > best then best, heavy = ms, label end
        end
        top[#top + 1] = { resource = row.key, ms = math.floor(row.value * 100) / 100, heaviest = heavy }
    end
    return top
end

function Profiler.run(onDone)
    if Profiler.busy then return false, 'profiler ocupado' end
    Profiler.busy = true
    Profiler.lastRun = os.time()

    CreateThread(function()
        local cfg = Config.Profiler
        ExecuteCommand(('profiler record %d'):format(cfg.frames))
        Wait(cfg.waitSeconds * 1000)
        ExecuteCommand(('profiler saveJSON %s'):format(cfg.outputFile))
        Wait(1500)
        local top, err = parseTrace(cfg.outputFile)
        Profiler.busy = false
        if onDone then onDone(top, err) end
    end)
    return true
end

function Profiler.canAutoRun()
    local cfg = Config.Profiler
    return cfg.enabled and not Profiler.busy and (os.time() - Profiler.lastRun) >= cfg.cooldown
end
