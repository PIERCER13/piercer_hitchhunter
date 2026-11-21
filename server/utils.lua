Utils = {}

-- Texto do servidor (notificacoes/Discord) conforme Config.Language. A NUI tem seu proprio seletor.
function Utils.L(pt, en)
    return (Config.Language == 'en-US') and en or pt
end

function Utils.stripColors(s)
    return (tostring(s or ''):gsub('%^%d', ''):gsub('[\r\n]+$', ''))
end

function Utils.iso(ts)
    return os.date('!%Y-%m-%dT%H:%M:%SZ', ts or os.time())
end

function Utils.log(msg)
    -- prefixo fixo, e o listener ignora linhas com esse prefixo
    print(('^5[hitchhunter]^7 %s'):format(msg))
end

function Utils.resourceSet()
    local set = {}
    for i = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(i)
        if name then set[name] = true end
    end
    return set
end

function Utils.sortedPairs(map, field)
    local arr = {}
    for k, v in pairs(map) do
        arr[#arr + 1] = { key = k, value = field and v[field] or v }
    end
    table.sort(arr, function(a, b) return a.value > b.value end)
    return arr
end
