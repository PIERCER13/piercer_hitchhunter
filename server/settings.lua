-- Preferencias persistidas em data/settings.json (lista de resources ignorados).
-- O arquivo tambem e lido pelo painel web, por isso publica `allowRestart`.
Settings = {}

local RES = GetCurrentResourceName()
local FILE = 'data/settings.json'
local ignored = {}

function Settings.isIgnored(resource) return ignored[resource] == true end

function Settings.public()
    local arr = {}
    for name in pairs(ignored) do arr[#arr + 1] = name end
    table.sort(arr)
    return { ignored = arr, allowRestart = Config.Actions.restartResource == true }
end

function Settings.save()
    SaveResourceFile(RES, FILE, json.encode(Settings.public()), -1)
end

function Settings.ignore(resource) ignored[resource] = true; Settings.save() end
function Settings.unignore(resource) ignored[resource] = nil; Settings.save() end

function Settings.load()
    local raw = LoadResourceFile(RES, FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' and type(data.ignored) == 'table' then
            for _, name in ipairs(data.ignored) do
                if type(name) == 'string' then ignored[name] = true end
            end
        end
    end
    Settings.save() -- publica allowRestart atual
end
